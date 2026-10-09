import 'package:flutter/foundation.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/ai_client/parsed_meal_dto.dart';
import '../../infra/catalog/food_match_result.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/food_resolution/meal_draft.dart';
import '../../infra/storage/storage_repository.dart';
import 'quantity_mapping.dart';
import 'review_item.dart';

/// SPEC-026: `sourceId` de un alimento armado con la instantánea de un ítem
/// guardado.
const _snapshotSourceId = 'snapshot';

/// R12: asignación de `meal_type` por hora local cuando la IA no lo pudo
/// inferir del texto.
String assignMealTypeByHour(DateTime at) {
  final hour = at.hour;
  if (hour >= 5 && hour <= 10) return 'desayuno';
  if (hour >= 11 && hour <= 15) return 'almuerzo';
  if (hour >= 18 && hour <= 22) return 'cena';
  return 'snack';
}

/// Controller de la pantalla de revisión (R8, R9, R10). No es un provider de
/// Riverpod a propósito: su estado es específico de una sesión de revisión
/// (un `ParsedMealDto`), así que vive como `ChangeNotifier` creado por
/// `ReviewScreen`, no compartido con el resto del árbol de widgets.
class ReviewController extends ChangeNotifier {
  final FoodQueryResolver _resolver;
  final StorageRepository _storage;
  final Map<QuantityUnit, double> _householdUnits;

  late List<ReviewItem> _items;
  late String mealType;

  /// SPEC-026: id de la comida guardada que se está editando; `null` al
  /// registrar una nueva.
  int? editingMealId;

  /// SPEC-026 R2: fecha y hora de la comida (en modo edición, la guardada).
  DateTime? eatenAt;

  bool get isEditing => editingMealId != null;

  /// SPEC-026: hubo cambios en los datos de la comida desde que se abrió
  /// (para no perderlos con "Repetir hoy"). Cambiar solo la vista (g o
  /// porciones) no cuenta.
  bool get hasChanges => _hasChanges;
  bool _hasChanges = false;

  /// Para los métodos que cambian datos de la comida.
  void _changed() {
    _hasChanges = true;
    notifyListeners();
  }

  ReviewController({
    required ParsedMealDto parsedMeal,
    required FoodQueryResolver resolver,
    required StorageRepository storage,
    DateTime? now,
    List<FoodMatchResult>? matches,
  }) : _resolver = resolver,
       // ignore: prefer_initializing_formals
       _storage = storage,
       _householdUnits = resolver.householdUnitMlByUnit() {
    mealType =
        parsedMeal.mealType ?? assignMealTypeByHour(now ?? DateTime.now());
    // SPEC-012 R2: quien muestra "Analizando" resuelve primero (paso 3) y
    // pasa aquí las coincidencias; el cálculo (paso 4) ocurre al construir.
    final resolved = matches ?? resolveAll(parsedMeal, resolver);
    _items = [
      for (final (i, parsed) in parsedMeal.items.indexed)
        _buildItem(parsed, resolved[i]),
    ];
  }

  /// SPEC-017: comida con los alimentos y gramos ya resueltos (Recientes),
  /// sin IA. El tipo de comida se asigna por la hora actual; un alimento que
  /// ya no existe se omite. Las kcal se recalculan con el catálogo actual.
  /// SPEC-026 R1: el Detalle de una comida guardada. Cada ítem conserva su
  /// instantánea (`savedSnapshot`) hasta que la persona lo cambie. Si su
  /// alimento ya no existe (producto borrado), se arma uno con los valores
  /// de la instantánea para poder ajustar los gramos.
  ReviewController.forEdit({
    required MealWithItems meal,
    required FoodQueryResolver resolver,
    required StorageRepository storage,
  }) : _resolver = resolver,
       // ignore: prefer_initializing_formals
       _storage = storage,
       _householdUnits = resolver.householdUnitMlByUnit() {
    editingMealId = meal.meal.id;
    eatenAt = meal.meal.eatenAt;
    mealType = meal.meal.mealType ?? assignMealTypeByHour(meal.meal.eatenAt);
    _items = [for (final item in meal.items) _savedReviewItem(item, resolver)];
  }

  static ReviewItem _savedReviewItem(
    MealItem item,
    FoodQueryResolver resolver,
  ) {
    final foodId = item.personalProductId != null
        ? '$personalProductIdPrefix${item.personalProductId}'
        : item.foodId;
    final food =
        (foodId == null ? null : resolver.getFoodById(foodId)) ??
        _snapshotFood(item);
    return ReviewItem(
      mention: item.mention,
      foodQuery: item.nameSnapshot,
      isVague: false,
      quantityRaw: item.quantityInput,
      unitRaw: item.unitInput,
      sizeRaw: item.sizeInput,
      status: ReviewItemStatus.matched,
      food: food,
      grams: item.grams,
      basis:
          QuantityBasis.values.asNameMap()[item.quantityBasis] ??
          QuantityBasis.explicitWeight,
      confidence:
          ConfidenceLevel.values.asNameMap()[item.confidence] ??
          ConfidenceLevel.estimacion,
      // AC4: la instantánea, no el catálogo actual.
      nutrients: (
        energyKcal: item.energyKcal,
        proteinG: item.proteinG,
        carbsG: item.carbsG,
        fatG: item.fatG,
      ),
      savedSnapshot: item,
    );
  }

  /// Alimento armado con los valores guardados (por 100 g), para un ítem
  /// cuyo alimento ya no existe. Mismo criterio que `_per100()` de
  /// "Confirmar etiqueta": una conversión de la instantánea, no un dato
  /// nuevo.
  static FoodCatalogEntry _snapshotFood(MealItem item) {
    // SPEC-042: la conversión la hace nutrition_core; con 0 g, 0 como antes.
    double per100(double value) => per100FromAmount(value, item.grams) ?? 0;
    return FoodCatalogEntry(
      id: 'snapshot:${item.id}',
      nameEs: item.nameSnapshot,
      sourceId: _snapshotSourceId,
      sourceRef: item.sourceRef,
      energyKcal100g: per100(item.energyKcal),
      proteinG100g: per100(item.proteinG),
      carbsG100g: per100(item.carbsG),
      fatG100g: per100(item.fatG),
      portions: const [],
    );
  }

  /// SPEC-026 R2: fecha y hora nuevas (quien llama impide las futuras).
  void setEatenAt(DateTime value) {
    eatenAt = value;
    _changed();
  }

  ReviewController.fromDraft({
    required MealDraft draft,
    required FoodQueryResolver resolver,
    required StorageRepository storage,
    DateTime? now,
  }) : _resolver = resolver,
       // ignore: prefer_initializing_formals
       _storage = storage,
       _householdUnits = resolver.householdUnitMlByUnit() {
    mealType = assignMealTypeByHour(now ?? DateTime.now());
    _items = [
      for (final item in draft.items)
        if (resolver.getFoodById(item.foodId) case final food?)
          _draftReviewItem(item, food),
    ];
  }

  static ReviewItem _draftReviewItem(
    MealDraftItem item,
    FoodCatalogEntry food,
  ) => ReviewItem(
    mention: item.mention,
    foodQuery: food.nameEs,
    isVague: false,
    quantityRaw: item.quantityInput ?? item.grams,
    unitRaw: item.quantityInput == null ? 'g' : item.unitInput,
    sizeRaw: item.sizeInput,
    status: ReviewItemStatus.matched,
    food: food,
    grams: item.grams,
    basis: item.basis,
    // La confianza que le dieron las reglas al registrarla (Recientes) o
    // al elegir la cantidad (búsqueda manual): repetir no la mejora.
    confidence: item.confidence,
    nutrients: calculateItemNutrients(food, item.grams),
  );

  /// SPEC-018 R3: "Añadir" un alimento buscado a mano; los totales se
  /// recalculan solos.
  void addDraftItem(MealDraftItem item) {
    final food = _resolver.getFoodById(item.foodId);
    if (food == null) return;
    _items.add(_draftReviewItem(item, food));
    _changed();
  }

  /// SPEC-040 R3: añade como ingrediente nuevo un producto recién guardado
  /// con su etiqueta, con la cantidad elegida en "Confirmar etiqueta"
  /// ([quantity] en [unit]). Los gramos los resuelve `nutrition_core`.
  /// Devuelve `false` si esa cantidad no se pudo resolver.
  bool addLabelProduct(
    FoodCatalogEntry food, {
    required double quantity,
    required String unit,
    required String servingUnit,
  }) {
    final resolution = resolveGrams(
      input: QuantityInput(
        quantity: quantity,
        unit: mapUnit(unit),
        isVague: false,
      ),
      food: food,
      isLabelProduct: true,
    );
    final grams = resolution.grams;
    if (!resolution.resolvable || grams == null || grams <= 0) return false;
    _servingUnits[food.id] = servingUnit;
    _items.add(
      _draftReviewItem(
        MealDraftItem(
          foodId: food.id,
          mention: food.nameEs,
          grams: grams,
          basis: resolution.basis,
          confidence: confidenceOfResolution(resolution, isVague: false),
          quantityInput: quantity,
          unitInput: unit,
        ),
        food,
      ),
    );
    _changed();
    return true;
  }

  /// Resolución de cada ítem contra el catálogo y los productos personales,
  /// sin cálculo.
  static List<FoodMatchResult> resolveAll(
    ParsedMealDto parsedMeal,
    FoodQueryResolver resolver,
  ) => parsedMeal.items
      // SPEC-025 R2: la marca también puede venir en la frase.
      .map((i) => resolver.resolve(i.foodQuery, mention: i.mention))
      .toList();

  List<ReviewItem> get items => List.unmodifiable(_items);

  bool get canRegister =>
      _items.isNotEmpty &&
      _items.every(
        (item) =>
            item.status != ReviewItemStatus.ambiguous &&
            item.status != ReviewItemStatus.notFound,
      );

  NutrientTotals get mealTotals => sumNutrients(
    _items.where((i) => i.nutrients != null).map((i) => i.nutrients!),
  );

  ConfidenceLevel? get mealConfidenceLevel {
    final withConfidence = _items
        .where((i) => i.confidence != null && i.nutrients != null)
        .map(
          (i) =>
              (energyKcal: i.nutrients!.energyKcal, confidence: i.confidence!),
        )
        .toList();
    if (withConfidence.isEmpty) return null;
    return mealConfidence(withConfidence);
  }

  /// SPEC-012 R5: todos los ítems salen del catálogo o de una etiqueta
  /// confirmada, es decir, todos tienen `source_ref` (invariante 8).
  bool get isFullyVerified =>
      _items.isNotEmpty &&
      _items.every(
        (i) =>
            i.status == ReviewItemStatus.matched &&
            (i.food?.sourceRef.isNotEmpty ?? false),
      );

  ReviewItem _buildItem(ParsedMealItemDto parsed, FoodMatchResult match) {
    final item = _itemFor(parsed, match);
    // SPEC-025 R3.
    final notice = _resolver.brandWithoutProduct(
      parsed.foodQuery,
      parsed.mention,
    );
    return notice == null ? item : item.withBrandNotice(notice);
  }

  ReviewItem _itemFor(ParsedMealItemDto parsed, FoodMatchResult match) {
    return switch (match) {
      FoodMatched(food: final food) => _matchedItem(parsed, food),
      FoodAmbiguous(candidates: final candidates) => ReviewItem(
        mention: parsed.mention,
        foodQuery: parsed.foodQuery,
        isVague: parsed.isVague,
        parentIndex: parsed.parentIndex,
        quantityRaw: parsed.quantity,
        unitRaw: parsed.unit,
        sizeRaw: parsed.size,
        status: ReviewItemStatus.ambiguous,
        candidates: candidates,
        grams: 0,
      ),
      FoodNotFound() => ReviewItem(
        mention: parsed.mention,
        foodQuery: parsed.foodQuery,
        isVague: parsed.isVague,
        parentIndex: parsed.parentIndex,
        quantityRaw: parsed.quantity,
        unitRaw: parsed.unit,
        sizeRaw: parsed.size,
        status: ReviewItemStatus.notFound,
        grams: 0,
      ),
    };
  }

  ReviewItem _matchedItem(ParsedMealItemDto parsed, FoodCatalogEntry food) {
    final isLabelProduct = isPersonalProductFood(food);
    final resolution = resolveGrams(
      input: QuantityInput(
        quantity: parsed.quantity,
        unit: mapUnit(parsed.unit),
        size: mapSize(parsed.size),
        isVague: parsed.isVague,
      ),
      food: food,
      householdUnitMlByUnit: _householdUnits,
      isLabelProduct: isLabelProduct,
    );
    // SPEC-043: sin equivalencia, el respaldo y su confianza los da
    // `nutrition_core`.
    final withoutEquivalence = !resolution.resolvable;
    final used = withoutEquivalence ? fallbackResolution(food) : resolution;
    final grams = used.grams!;
    final confidence = confidenceOfResolution(
      used,
      isVague: parsed.isVague,
      withoutEquivalence: withoutEquivalence,
    );
    return ReviewItem(
      mention: parsed.mention,
      foodQuery: parsed.foodQuery,
      isVague: parsed.isVague,
      parentIndex: parsed.parentIndex,
      quantityRaw: parsed.quantity,
      unitRaw: parsed.unit,
      sizeRaw: parsed.size,
      status: ReviewItemStatus.matched,
      food: food,
      grams: grams,
      basis: used.basis,
      confidence: confidence,
      nutrients: calculateItemNutrients(food, grams),
      highlightForEdit:
          withoutEquivalence || used.basis == QuantityBasis.defaultPortion,
      withoutEquivalence: withoutEquivalence,
    );
  }

  /// Lo que dijo la persona de este ingrediente, para volver a resolverlo
  /// con otro alimento.
  static ParsedMealItemDto _parsedOf(ReviewItem item) => ParsedMealItemDto(
    mention: item.mention,
    foodQuery: item.foodQuery,
    quantity: item.quantityRaw,
    unit: item.unitRaw,
    size: item.sizeRaw,
    preparation: null,
    isVague: item.isVague,
    parentIndex: item.parentIndex,
  );

  void selectCandidate(int index, String foodId) {
    final food = _resolver.getFoodById(foodId);
    if (food == null) return;
    _items[index] = _matchedItem(_parsedOf(_items[index]), food);
    _changed();
  }

  /// SPEC-033 R2–R4: la persona eligió el alimento de este ingrediente (su
  /// etiqueta o un producto guardado). La cantidad se resuelve con las
  /// reglas de siempre a partir de lo que dijo (R3); si no se pudo, o no
  /// dijo cantidad, se usa la elegida en "Confirmar etiqueta"
  /// ([fallbackQuantity] en [fallbackUnit]) y el ingrediente sigue
  /// destacado para revisar. Sin IA.
  void replaceFood(
    int index,
    FoodCatalogEntry food, {
    double? fallbackQuantity,
    String? fallbackUnit,

    /// SPEC-034 R5: "g" o "ml" del producto elegido.
    String? servingUnit,
  }) {
    if (servingUnit != null) _servingUnits[food.id] = servingUnit;
    final parsed = _parsedOf(_items[index]);
    var rebuilt = _matchedItem(parsed, food);
    final saidQuantityResolved =
        parsed.quantity != null &&
        resolveGrams(
          input: QuantityInput(
            quantity: parsed.quantity,
            unit: mapUnit(parsed.unit),
            size: mapSize(parsed.size),
            isVague: parsed.isVague,
          ),
          food: food,
          householdUnitMlByUnit: _householdUnits,
          isLabelProduct: isPersonalProductFood(food),
        ).resolvable;
    if (!saidQuantityResolved && fallbackQuantity != null) {
      final chosen = resolveGrams(
        input: QuantityInput(
          quantity: fallbackQuantity,
          unit: mapUnit(fallbackUnit),
          isVague: false,
        ),
        food: food,
        isLabelProduct: isPersonalProductFood(food),
      );
      final grams = chosen.grams;
      if (grams != null && grams > 0) {
        rebuilt = rebuilt.withoutEquivalence
            // SPEC-043: lo dicho no tenía equivalencia; manda la cantidad
            // elegida en "Confirmar etiqueta", con su base y su confianza.
            // Sigue destacado para revisar (SPEC-033 R3).
            ? rebuilt.copyWith(
                grams: grams,
                basis: chosen.basis,
                confidence: confidenceOfResolution(chosen, isVague: false),
                nutrients: calculateItemNutrients(food, grams),
                highlightForEdit: true,
                writtenQuantity: (
                  quantity: fallbackQuantity,
                  unit: fallbackUnit ?? 'g',
                ),
              )
            : rebuilt.copyWith(
                grams: grams,
                nutrients: calculateItemNutrients(food, grams),
              );
      }
    }
    _items[index] = rebuilt;
    _changed();
  }

  /// SPEC-034 R5: unidades de productos elegidos después de abrir el
  /// Detalle (el resolver no los conoce).
  final Map<String, String> _servingUnits = {};

  /// SPEC-034 R5: "g" o "ml" para mostrar la cantidad de este ingrediente.
  String unitOf(ReviewItem item) {
    final food = item.food;
    if (food == null) return 'g';
    return _servingUnits[food.id] ?? _resolver.servingUnitOf(food.id);
  }

  /// SPEC-033 R5: gramos (o ml) de una porción de la etiqueta, solo para
  /// productos personales.
  static double? portionGramsOf(ReviewItem item) {
    final food = item.food;
    if (food == null || !isPersonalProductFood(food)) return null;
    return food.portionFor('porcion')?.grams;
  }

  /// SPEC-033 R5: cuántas porciones de la etiqueta son los gramos actuales.
  static double? portionsOf(ReviewItem item) {
    final portionGrams = portionGramsOf(item);
    // SPEC-042: g → porciones en nutrition_core.
    return portionGrams == null
        ? null
        : portionsForAmount(item.grams, portionGrams);
  }

  /// SPEC-033 R5: cantidad en porciones de la etiqueta.
  /// Porciones → g los resuelve `nutrition_core` (invariante 3).
  void setPortions(int index, double portions) {
    final item = _items[index];
    final food = item.food;
    if (portionGramsOf(item) == null || food == null || portions <= 0) return;
    final grams = resolveGrams(
      input: QuantityInput(
        quantity: portions,
        unit: QuantityUnit.porcion,
        isVague: false,
      ),
      food: food,
      isLabelProduct: true,
    ).grams;
    if (grams != null) setGrams(index, grams);
  }

  /// SPEC-033 R5: ver este ingrediente en g/ml o en porciones.
  void setShowInGrams(int index, bool value) {
    _items[index] = _items[index].copyWith(showInGrams: value);
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    _changed();
  }

  /// AC8: recalcula kcal/macros localmente, sin llamadas de red.
  void setGrams(int index, double grams) {
    final item = _items[index];
    if (item.food == null || grams <= 0) return;
    _items[index] = item.copyWith(
      grams: grams,
      nutrients: calculateItemNutrients(item.food!, grams),
      // SPEC-026 AC4: editado → se guarda con los valores actuales.
      keepSnapshot: false,
    );
    _changed();
  }

  /// SPEC-023 R3: "Escribe los gramos". La cantidad exacta en g (o ml,
  /// según [unit]) pasa por las reglas de `nutrition_core`: base y
  /// confianza nuevas (p. ej. "Peso dicho por ti"). Sin IA.
  void setWrittenQuantity(int index, double quantity, {required String unit}) {
    final item = _items[index];
    final food = item.food;
    if (food == null || quantity <= 0) return;
    final isLabel = isPersonalProductFood(food);
    final resolution = resolveGrams(
      input: QuantityInput(
        quantity: quantity,
        unit: mapUnit(unit),
        isVague: false,
      ),
      food: food,
      isLabelProduct: isLabel,
    );
    final grams = resolution.grams;
    if (!resolution.resolvable || grams == null || grams <= 0) return;
    _items[index] = item.copyWith(
      grams: grams,
      basis: resolution.basis,
      confidence: confidenceOfResolution(resolution, isVague: false),
      nutrients: calculateItemNutrients(food, grams),
      highlightForEdit: false,
      keepSnapshot: false,
      writtenQuantity: (quantity: quantity, unit: unit),
    );
    _changed();
  }

  void setMealType(String type) {
    if (type == mealType) return;
    mealType = type;
    _changed();
  }

  Future<int> register({DateTime? eatenAt}) {
    final confidence = mealConfidenceLevel;
    if (!canRegister || confidence == null) {
      throw StateError(
        'No se puede registrar: hay ítems pendientes o sin confianza calculada.',
      );
    }
    final records = _items
        .where((item) => item.status == ReviewItemStatus.matched)
        .map((item) {
          // SPEC-026 AC4: un ítem no tocado se guarda tal como estaba.
          final saved = item.savedSnapshot;
          if (saved != null) return _recordFromSnapshot(saved);
          final food = item.food!;
          final personalId = personalProductIdFrom(food.id);
          // SPEC-026: un alimento armado con la instantánea (su producto se
          // borró) no tiene id que guardar.
          final fromSnapshot = food.sourceId == _snapshotSourceId;
          return MealItemRecord(
            mention: item.mention,
            foodId: personalId == null && !fromSnapshot ? food.id : null,
            personalProductId: personalId,
            nameSnapshot: food.nameEs,
            grams: item.grams,
            quantityInput: item.quantityRaw,
            unitInput: item.unitRaw,
            sizeInput: item.sizeRaw,
            quantityBasis: item.basis!.name,
            energyKcal: item.nutrients!.energyKcal,
            proteinG: item.nutrients!.proteinG,
            carbsG: item.nutrients!.carbsG,
            fatG: item.nutrients!.fatG,
            confidence: item.confidence!.name,
            sourceRef: food.sourceRef,
          );
        })
        .toList();

    final editingId = editingMealId;
    if (editingId != null) {
      // SPEC-026 R2: la misma comida, en una transacción.
      return _storage
          .updateMeal(
            id: editingId,
            eatenAt: this.eatenAt ?? eatenAt ?? DateTime.now(),
            mealType: mealType,
            confidence: confidence.name,
            catalogVersion: _resolver.catalogVersion,
            items: records,
          )
          .then((_) => editingId);
    }
    return _storage.registerMeal(
      eatenAt: eatenAt ?? DateTime.now(),
      mealType: mealType,
      confidence: confidence.name,
      catalogVersion: _resolver.catalogVersion,
      items: records,
    );
  }

  /// SPEC-026 R3: borra la comida que se está editando.
  Future<void> deleteEditedMeal() {
    final id = editingMealId;
    if (id == null) throw StateError('No hay una comida guardada abierta.');
    return _storage.deleteMeal(id);
  }

  static MealItemRecord _recordFromSnapshot(MealItem saved) => MealItemRecord(
    mention: saved.mention,
    foodId: saved.foodId,
    personalProductId: saved.personalProductId == null
        ? null
        : int.tryParse(saved.personalProductId!),
    nameSnapshot: saved.nameSnapshot,
    grams: saved.grams,
    quantityInput: saved.quantityInput,
    unitInput: saved.unitInput,
    sizeInput: saved.sizeInput,
    quantityBasis: saved.quantityBasis,
    energyKcal: saved.energyKcal,
    proteinG: saved.proteinG,
    carbsG: saved.carbsG,
    fatG: saved.fatG,
    confidence: saved.confidence,
    sourceRef: saved.sourceRef,
  );
}
