import 'package:flutter/foundation.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/ai_client/label_extraction_dto.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/storage/storage_repository.dart';

/// Campos transcritos que el usuario puede editar (SPEC-004 R4). Siempre
/// "por porción": si la etiqueta solo dio valores por 100 g/ml, se derivan
/// una vez al construir el controller (matemática simple, no una segunda
/// transcripción) para tener un único formulario, no dos.
/// SPEC-032 R1: unidad de "¿Cuánto comiste?".
enum ConsumedUnit { portions, servingUnit }

class LabelConfirmationController extends ChangeNotifier {
  final StorageRepository _storage;

  String productName;
  double? servingQuantity;
  String servingUnit; // "g" | "ml"
  double? energyKcal;
  double? proteinG;
  double? carbsG;
  double? fatG;
  double? fiberG;
  double? sugarG;
  double? sodiumMg;
  late double consumedQuantity;

  /// SPEC-033 R8: los valores los escribió la persona, no la IA.
  final bool manualEntry;

  /// SPEC-033 R2: id del producto personal que guardó [save].
  int? savedProductId;

  /// SPEC-032 R1: arranca en porciones con 1 (equivale a la porción).
  ConsumedUnit consumedUnit = ConsumedUnit.portions;
  double portionsCount = 1;

  final Set<String> unreadableFields;
  bool _atwaterConfirmedDespiteWarning = false;

  LabelConfirmationController({
    required LabelExtractionDto extraction,
    required StorageRepository storage,

    /// SPEC-033 R2: nombre del ingrediente si la IA no leyó el del producto.
    String? defaultProductName,

    /// SPEC-033 R8: la persona escribe los valores (sin IA).
    this.manualEntry = false,
  })
    // ignore: prefer_initializing_formals
    : _storage = storage,
       productName = extraction.productName ?? defaultProductName ?? '',
       servingQuantity = extraction.servingSize?.quantity,
       servingUnit = extraction.servingSize?.unit ?? 'g',
       unreadableFields = extraction.unreadableFields.toSet() {
    final nutrients = extraction.perServing ?? _derivePerServing(extraction);
    energyKcal = nutrients?.energyKcal;
    proteinG = nutrients?.proteinG;
    carbsG = nutrients?.carbsG;
    fatG = nutrients?.fatG;
    fiberG = nutrients?.fiberG;
    sugarG = nutrients?.sugarG;
    sodiumMg = nutrients?.sodiumMg;
    consumedQuantity = servingQuantity ?? 0;
  }

  /// R2 edge case: la etiqueta solo dio valores por 100 g/ml — se derivan
  /// una vez a "por porción" (× cantidad/100) para el único formulario de
  /// edición. No es una segunda transcripción de la IA, es aritmética sobre
  /// lo ya transcrito.
  LabelNutrientSetDto? _derivePerServing(LabelExtractionDto extraction) {
    final per100 = extraction.per100;
    final servingQty = extraction.servingSize?.quantity;
    if (per100 == null || servingQty == null) return null;
    final factor = servingQty / 100;
    double? scale(double? value) => value == null ? null : value * factor;
    return LabelNutrientSetDto(
      energyKcal: scale(per100.energyKcal),
      proteinG: scale(per100.proteinG),
      carbsG: scale(per100.carbsG),
      fatG: scale(per100.fatG),
      fiberG: scale(per100.fiberG),
      sugarG: scale(per100.sugarG),
      sodiumMg: scale(per100.sodiumMg),
    );
  }

  /// R3: Atwater ±20 % sobre los valores por porción — la razón no cambia
  /// al escalar a por-100 g (es lineal), así que se puede validar aquí
  /// directamente sin convertir primero.
  LabelAtwaterCheck? get atwaterCheck {
    if (energyKcal == null ||
        proteinG == null ||
        carbsG == null ||
        fatG == null) {
      return null;
    }
    return checkLabelAtwater(
      energyKcal: energyKcal!,
      proteinG: proteinG!,
      carbsG: carbsG!,
      fatG: fatG!,
    );
  }

  bool get needsAtwaterConfirmation =>
      atwaterCheck != null && !atwaterCheck!.withinTolerance;

  bool get atwaterConfirmedDespiteWarning => _atwaterConfirmedDespiteWarning;

  void setAtwaterConfirmedDespiteWarning(bool value) {
    _atwaterConfirmedDespiteWarning = value;
    notifyListeners();
  }

  /// R3: porción obligatoria y positiva, los 4 macros presentes (el usuario
  /// completó cualquier campo no legible), cantidad consumida > 0, y si
  /// Atwater falla, confirmación explícita.
  bool get canSave => missingForSave.isEmpty;

  /// SPEC-030 R4: lo que falta para poder guardar, en el orden de la
  /// pantalla; vacío si `canSave`.
  List<String> get missingForSave => [
    if (productName.trim().isEmpty) 'nombre del producto',
    if (!isValidServingGrams(servingQuantity)) 'porción',
    if (energyKcal == null) 'calorías',
    if (proteinG == null) 'proteína',
    if (carbsG == null) 'carbohidratos',
    if (fatG == null) 'grasa',
    if (registeredQuantity <= 0) 'cuánto comiste',
    if (needsAtwaterConfirmation && !_atwaterConfirmedDespiteWarning)
      'confirmar que los valores son correctos',
  ];

  /// SPEC-032 R2: g/ml que se registran. Con porciones, número de
  /// porciones × porción vigente; con g/ml, lo que escribió la persona (o la
  /// porción, SPEC-031).
  double get registeredQuantity {
    if (consumedUnit == ConsumedUnit.servingUnit) return consumedQuantity;
    if (!isValidServingGrams(servingQuantity)) return 0;
    return portionsCount * servingQuantity!;
  }

  void setPortionsCount(double value) {
    portionsCount = value;
    notifyListeners();
  }

  /// SPEC-032 R3: cambiar de unidad conserva la cantidad registrada.
  void setConsumedUnit(ConsumedUnit unit) {
    if (unit == consumedUnit) return;
    if (unit == ConsumedUnit.servingUnit) {
      // Con 1 porción, pasar a g/ml no es editar la cantidad: sigue a la
      // porción mientras la persona no escriba otra (SPEC-031 R1). Con otro
      // número de porciones, esa cantidad es una elección de la persona y
      // no se reescribe al cambiar la porción (SPEC-032 R2).
      consumedQuantity = registeredQuantity;
      if (portionsCount != 1) _consumedQuantityTouchedByUser = true;
    } else if (isValidServingGrams(servingQuantity)) {
      portionsCount = consumedQuantity / servingQuantity!;
    }
    consumedUnit = unit;
    notifyListeners();
  }

  /// Valores por 100 g/ml a partir de lo confirmado "por porción". Es la
  /// única conversión: la usan [save] y la vista previa (SPEC-032 R4).
  ({
    double energyKcal,
    double proteinG,
    double carbsG,
    double fatG,
    double? fiberG,
    double? sugarG,
    double? sodiumMg,
  })
  _per100() {
    final factor = 100 / servingQuantity!;
    return (
      energyKcal: energyKcal! * factor,
      proteinG: proteinG! * factor,
      carbsG: carbsG! * factor,
      fatG: fatG! * factor,
      fiberG: fiberG == null ? null : fiberG! * factor,
      sugarG: sugarG == null ? null : sugarG! * factor,
      sodiumMg: sodiumMg == null ? null : sodiumMg! * factor,
    );
  }

  /// SPEC-032 R4/R5: lo que se va a registrar, calculado por
  /// `nutrition_core` igual que en Revisar (`resolveGrams` con
  /// `isLabelProduct` y `calculateItemNutrients` sobre el producto
  /// equivalente). `null` mientras falte algo para guardar.
  ({double grams, NutrientTotals nutrients})? get preview {
    if (!canSave) return null;
    final per100 = _per100();
    final food = FoodCatalogEntry(
      id: '${personalProductIdPrefix}preview',
      nameEs: productName.trim(),
      sourceId: personalProductSourceId,
      sourceRef: 'vista previa',
      energyKcal100g: per100.energyKcal,
      proteinG100g: per100.proteinG,
      carbsG100g: per100.carbsG,
      fatG100g: per100.fatG,
      portions: [
        PortionOption(
          descriptor: 'porcion',
          grams: servingQuantity!,
          sourceId: personalProductSourceId,
          sourceRef: 'vista previa',
          isCuratedEstimate: false,
        ),
      ],
    );
    final resolution = resolveGrams(
      input: QuantityInput(
        quantity: registeredQuantity,
        unit: servingUnit == 'ml'
            ? QuantityUnit.mililitros
            : QuantityUnit.gramos,
        isVague: false,
      ),
      food: food,
      isLabelProduct: true,
    );
    final grams = resolution.grams!;
    return (grams: grams, nutrients: calculateItemNutrients(food, grams));
  }

  void setProductName(String value) {
    productName = value;
    notifyListeners();
  }

  /// R5: mientras el usuario no haya tocado "cuánto comiste" directamente,
  /// sigue reflejando la porción — incluye el caso en que la porción llegó
  /// vacía (etiqueta ilegible) y el usuario la completa después.
  bool _consumedQuantityTouchedByUser = false;

  /// SPEC-031 R3: la pantalla deja de reescribir "¿Cuánto comiste?".
  bool get consumedQuantityTouchedByUser => _consumedQuantityTouchedByUser;

  void setServingQuantity(double? value) {
    servingQuantity = value;
    if (!_consumedQuantityTouchedByUser) {
      consumedQuantity = value ?? 0;
    }
    notifyListeners();
  }

  void setServingUnit(String value) {
    servingUnit = value;
    notifyListeners();
  }

  void setConsumedQuantity(double value) {
    consumedQuantity = value;
    _consumedQuantityTouchedByUser = true;
    notifyListeners();
  }

  void setEnergyKcal(double? v) {
    energyKcal = v;
    notifyListeners();
  }

  void setProteinG(double? v) {
    proteinG = v;
    notifyListeners();
  }

  void setCarbsG(double? v) {
    carbsG = v;
    notifyListeners();
  }

  void setFatG(double? v) {
    fatG = v;
    notifyListeners();
  }

  void setFiberG(double? v) {
    fiberG = v;
    notifyListeners();
  }

  void setSugarG(double? v) {
    sugarG = v;
    notifyListeners();
  }

  void setSodiumMg(double? v) {
    sodiumMg = v;
    notifyListeners();
  }

  /// R7: guarda el producto personal (valores normalizados a por-100 g/ml,
  /// misma convención que `catalog.db`) y devuelve su `nombre` — quien
  /// llama construye el `ParsedMealDto` de un solo ítem con
  /// `food_query = nombre` y `quantity/unit = consumedQuantity/servingUnit`
  /// para reutilizar el mismo `ReviewController` que texto/voz (R8).
  Future<String> save() async {
    if (!canSave) {
      throw StateError(
        'canSave es false: hay campos obligatorios sin completar.',
      );
    }
    final per100 = _per100();
    savedProductId = await _storage.savePersonalProduct(
      nameEs: productName.trim(),
      energyKcal100: per100.energyKcal,
      proteinG100: per100.proteinG,
      carbsG100: per100.carbsG,
      fatG100: per100.fatG,
      fiberG100: per100.fiberG,
      sugarG100: per100.sugarG,
      sodiumMg100: per100.sodiumMg,
      servingGrams: servingQuantity!,
      sourceRef:
          '${manualEntry ? 'Valores de la etiqueta escritos por el usuario el ' : 'Etiqueta transcrita por IA y confirmada por el usuario el '}'
          '${DateTime.now().toIso8601String().substring(0, 10)}'
          '${productName.trim().isEmpty ? '' : ' — producto: ${productName.trim()}'}.',
    );
    return productName.trim();
  }
}
