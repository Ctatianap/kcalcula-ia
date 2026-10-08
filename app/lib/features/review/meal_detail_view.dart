import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/clock.dart';
import '../../infra/food_resolution/food_query_resolver.dart';
import '../../infra/food_resolution/ingredient_label_result.dart';
import '../../infra/storage/app_database.dart' show PersonalProduct;
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/confidence_indicator.dart';
import '../../ui/components/k_card.dart';
import '../../ui/components/meal_actions.dart';
import '../../format/date_format_es.dart';
import '../../format/text_es.dart';
import '../../ui/confidence_texts.dart';
import '../../ui/number_input_es.dart';
import '../../ui/theme.dart';
import 'food_search_screen.dart';
import 'personal_product_picker_screen.dart';
import 'review_controller.dart';
import 'review_item.dart';

const _gramsStep = 5.0;

/// SPEC-033 R5: de a media porción.
const _portionStep = 0.5;

const registerErrorMessage = 'No pude guardar la comida. Intenta de nuevo.';

/// SPEC-026.
const futureMealMessage = 'La comida no puede quedar en el futuro.';

/// SPEC-026 R4 (mismo texto que el menú de SPEC-037).
const repeatTodayLabel = repeatTodayAction;

/// SPEC-026 R2/AC2: una comida no puede quedar en el futuro.
String? validateEatenAt(DateTime chosen, DateTime now) =>
    chosen.isAfter(now) ? futureMealMessage : null;

/// SPEC-033 R1: acciones del menú de cada ingrediente.
const useLabelAction = 'Usar etiqueta';
const pickProductAction = 'Elegir de mis productos';
const removeIngredientAction = 'Quitar';
const loadProductErrorMessage =
    'No pude leer el producto que guardaste. Elígelo en «Elegir de mis '
    'productos».';

/// SPEC-040: el producto guardado con su etiqueta no se pudo añadir.
const addProductErrorMessage =
    'No pude añadir el producto que guardaste. Búscalo en «Añadir '
    'ingrediente».';

String _portionsText(double portions) =>
    '${formatDecimalEs(portions, maxDecimals: 1)} '
    // Se compara lo que se muestra, no el double de una división.
    '${formatDecimalEs(portions, maxDecimals: 1) == '1' ? 'porción' : 'porciones'}';

/// SPEC-033 R5: la media porción siguiente (o anterior) a [portions], para
/// que una cantidad como 3,33 porciones pase a 3,5 (o 3) y no a 3,83.
double _nextHalfPortion(double portions, {required bool up}) {
  const epsilon = 1e-9;
  final halves = portions / _portionStep;
  final next = up
      ? (halves + epsilon).floor() + 1
      : (halves - epsilon).ceil() - 1;
  return next * _portionStep;
}

/// SPEC-023: los nombres viven con el indicador.
const confidenceLabels = confidenceLevelLabels;

/// R4: cómo se obtuvo la cantidad de cada ingrediente.
String quantitySourceLabel(QuantityBasis? basis) => switch (basis) {
  QuantityBasis.explicitWeight ||
  QuantityBasis.unitPortion => 'Cantidad dicha por ti',
  QuantityBasis.label => 'De tu etiqueta',
  QuantityBasis.sizeDescriptor => 'Tamaño estimado · ajústalo',
  QuantityBasis.householdMeasure => 'Medida casera estimada · ajústala',
  QuantityBasis.defaultPortion || null => 'Porción estimada · ajústala',
};

/// SPEC-043 R3.
const withoutEquivalenceLabel = 'Sin equivalencia · ajústala';

String _itemName(ReviewItem item) => item.food?.nameEs ?? item.mention;

/// SPEC-012 R4/R5: "Detalle de comida". Lo usan tanto el análisis de texto
/// como la etiqueta confirmada (y más adelante Recientes y la búsqueda).
class MealDetailView extends ConsumerStatefulWidget {
  final ReviewController controller;

  /// "Corregir": vuelve a "¿Qué comiste?" con el texto.
  final VoidCallback onCorrect;

  /// SPEC-026 R4 / SPEC-038 R2: repetir una comida guardada ("Repetir hoy"
  /// en otros días, "Repetir ahora" en la de hoy; ver [repeatLabel]).
  final VoidCallback? onRepeatToday;

  /// SPEC-038 R2: "Repetir hoy" u "Repetir ahora".
  final String repeatLabel;

  /// SPEC-022 R2: "Guardar como favorita" en una comida guardada.
  final VoidCallback? onSaveFavorite;

  const MealDetailView({
    super.key,
    required this.controller,
    required this.onCorrect,
    this.onRepeatToday,
    this.repeatLabel = repeatTodayLabel,
    this.onSaveFavorite,
  });

  @override
  ConsumerState<MealDetailView> createState() => _MealDetailViewState();
}

class _MealDetailViewState extends ConsumerState<MealDetailView> {
  late final DateTime _shownAt = ref.read(clockProvider)();
  bool _registering = false;
  String? _registerError;

  /// SPEC-033: error de "Usar etiqueta"; se limpia con la siguiente acción.
  String? _ingredientError;

  Future<void> _addIngredient() async {
    setState(() => _ingredientError = null);
    final pick = await pickIngredient(context);
    if (pick == null || !mounted) return;
    switch (pick) {
      case PickedFood(:final item):
        widget.controller.addDraftItem(item);
      case PickedLabelProduct(:final result):
        await _addLabelProduct(result);
    }
  }

  /// SPEC-033/040: el producto recién guardado con su etiqueta, o `null`
  /// si no se pudo leer (SPEC-009: sin el texto de SQLite).
  Future<PersonalProduct?> _savedProduct(int id) async {
    try {
      return await ref
          .read(storageRepositoryProvider)
          .getPersonalProductById(id);
    } catch (_) {
      return null;
    }
  }

  /// SPEC-040 R3: el producto recién guardado, como ingrediente nuevo.
  Future<void> _addLabelProduct(IngredientLabelResult result) async {
    final product = await _savedProduct(result.productId);
    if (!mounted) return;
    final added =
        product != null &&
        widget.controller.addLabelProduct(
          personalProductToFoodCatalogEntry(product),
          quantity: result.quantity,
          unit: result.unit,
          servingUnit: product.servingUnit,
        );
    if (!added) setState(() => _ingredientError = addProductErrorMessage);
  }

  /// SPEC-033 R2: etiqueta de este ingrediente; vuelve aquí con el
  /// producto guardado.
  Future<void> _useLabel(int index) async {
    setState(() => _ingredientError = null);
    final item = widget.controller.items[index];
    final result = await Navigator.of(context).pushNamed<IngredientLabelResult>(
      AppRoutes.ingredientLabel,
      arguments: item.foodQuery,
    );
    if (result == null || !mounted) return;
    final product = await _savedProduct(result.productId);
    if (!mounted) return;
    if (product == null) {
      setState(() => _ingredientError = loadProductErrorMessage);
      return;
    }
    widget.controller.replaceFood(
      index,
      personalProductToFoodCatalogEntry(product),
      fallbackQuantity: result.quantity,
      fallbackUnit: result.unit,
      servingUnit: product.servingUnit,
    );
  }

  /// SPEC-033 R4: un producto ya guardado, sin foto y sin IA.
  Future<void> _pickProduct(int index) async {
    setState(() => _ingredientError = null);
    final picked = await pickPersonalProduct(context);
    if (picked != null && mounted) {
      widget.controller.replaceFood(
        index,
        picked.food,
        servingUnit: picked.servingUnit,
      );
    }
  }

  /// SPEC-023 R3: "Escribe los gramos" (o ml) de este ingrediente.
  Future<void> _writeGrams(int index) async {
    final controller = widget.controller;
    final item = controller.items[index];
    final unit = controller.unitOf(item);
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _WriteQuantityDialog(
        name: _itemName(item),
        unit: unit,
        initial: item.grams,
      ),
    );
    if (value != null && mounted) {
      controller.setWrittenQuantity(index, value, unit: unit);
    }
  }

  /// SPEC-023 R3: por qué este ingrediente tiene su nivel y cómo mejorarlo.
  Future<void> _explainItem(int index) async {
    final item = widget.controller.items[index];
    final level = item.confidence;
    if (level == null) return;
    final explanation = confidenceExplanation(
      confidenceReasonFor(
        basis: item.basis,
        isVague: item.isVague,
        level: level,
        withoutEquivalence: item.withoutEquivalence,
      ),
      said: saidQuantityWord(unit: item.unitRaw, size: item.sizeRaw),
    );
    final action = await _showConfidenceSheet(
      context,
      level: level,
      title: explanation.title,
      body: explanation.body,
      actions: [
        for (final a in explanation.actions)
          if (a != ConfidenceAction.useLabel || !_registering) a,
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case ConfidenceAction.writeGrams:
        await _writeGrams(index);
      case ConfidenceAction.useLabel:
        await _useLabel(index);
    }
  }

  /// SPEC-023 R3: la regla de la comida y los ingredientes con su nivel.
  Future<void> _explainMeal() async {
    final controller = widget.controller;
    final level = controller.mealConfidenceLevel;
    if (level == null) return;
    final names = [
      for (final item in controller.items)
        if (item.status == ReviewItemStatus.matched && item.confidence == level)
          _itemName(item),
    ];
    await _showConfidenceSheet(
      context,
      level: level,
      title: 'Confianza de la comida',
      body:
          '$mealConfidenceRuleText'
          '${names.isEmpty ? '' : '\n\nIngredientes con este nivel: ${joinNamesEs(names)}.'}',
      actions: const [],
    );
  }

  /// SPEC-026 R2: fecha y hora nuevas; nunca en el futuro.
  Future<void> _changeEatenAt() async {
    final now = ref.read(clockProvider)();
    final current = widget.controller.eatenAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      // Una comida más vieja que eso también se puede abrir.
      firstDate: current.year < now.year - 5
          ? DateTime(current.year)
          : DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    final chosen = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final error = validateEatenAt(chosen, now);
    if (error != null) {
      setState(() => _registerError = error);
      return;
    }
    setState(() => _registerError = null);
    widget.controller.setEatenAt(chosen);
  }

  /// SPEC-026 R3: borrar con confirmación.
  Future<void> _deleteMeal() async {
    final controller = widget.controller;
    final at = controller.eatenAt ?? ref.read(clockProvider)();
    final confirmed = await confirmDeleteMeal(
      context,
      mealType: controller.mealType,
      eatenAt: at,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _registering = true;
      _registerError = null;
    });
    try {
      await controller.deleteEditedMeal();
    } catch (_) {
      // SPEC-009: sin el texto de SQLite.
      if (mounted) {
        setState(() {
          _registering = false;
          _registerError = deleteMealErrorMessage;
        });
      }
      return;
    }
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.today, (route) => false);
    }
  }

  Future<void> _register() async {
    // Edge case: un doble toque no guarda dos veces.
    if (_registering) return;
    setState(() {
      _registering = true;
      _registerError = null;
    });
    try {
      await widget.controller.register(eatenAt: ref.read(clockProvider)());
    } catch (_) {
      // SPEC-009 R2: sin relanzar (el texto de SQLite trae la comida).
      if (mounted) {
        setState(() {
          _registering = false;
          _registerError = registerErrorMessage;
        });
      }
      return;
    }
    if (mounted) {
      // SPEC-010: siempre un Hoy recién cargado, aunque se haya registrado
      // desde Historial o Progreso.
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.today, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEditing ? 'Editar comida' : 'Detalle de comida',
        ),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final items = controller.items;
          final text = Theme.of(context).textTheme;
          return Column(
            children: [
              Expanded(
                // Pocos ítems: se construyen todos (sin lista perezosa).
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        joinNamesEs(items.map(_itemName).toList()),
                        key: const Key('meal-detail-title'),
                        style: text.headlineMedium?.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      if (controller.isEditing)
                        // SPEC-026 R2: fecha y hora de la comida guardada.
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${timeEs(controller.eatenAt!)} · '
                                '${longDateEs(controller.eatenAt!)}',
                                key: const Key('meal-detail-eaten-at'),
                                style: text.bodyMedium?.copyWith(
                                  color: KColors.textSecondary,
                                ),
                              ),
                            ),
                            TextButton(
                              key: const Key('meal-detail-change-eaten-at'),
                              onPressed: _registering ? null : _changeEatenAt,
                              child: const Text('Cambiar'),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${timeEs(_shownAt)} · ${longDateEs(_shownAt)}',
                          style: text.bodyMedium?.copyWith(
                            color: KColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 16),
                      _TotalsCard(
                        controller: controller,
                        onExplain: _explainMeal,
                      ),
                      if (controller.isFullyVerified) ...[
                        const SizedBox(height: 12),
                        const _VerifiedSeal(),
                      ],
                      const SizedBox(height: 20),
                      Text('Tipo de comida', style: text.titleMedium),
                      const SizedBox(height: 8),
                      _MealTypeSelector(
                        value: controller.mealType,
                        onChanged: controller.setMealType,
                      ),
                      const SizedBox(height: 20),
                      Text('Ingredientes', style: text.titleMedium),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        Text(
                          controller.isEditing
                              ? 'Quitaste todos los alimentos. Para eliminar '
                                    'la comida, toca "Borrar comida".'
                              : 'Quitaste todos los alimentos. Toca "Corregir" '
                                    'para escribir de nuevo.',
                          key: Key('meal-detail-empty'),
                          style: TextStyle(color: KColors.textSecondary),
                        ),
                      for (final (index, item) in items.indexed) ...[
                        _IngredientCard(
                          item: item,
                          onSelectCandidate: (foodId) =>
                              controller.selectCandidate(index, foodId),
                          onRemove: () => controller.removeItem(index),
                          onAdjustGrams: (delta) =>
                              controller.setGrams(index, item.grams + delta),
                          onUseLabel: _registering
                              ? null
                              : () => _useLabel(index),
                          onPickProduct: _registering
                              ? null
                              : () => _pickProduct(index),
                          onSetPortions: (portions) =>
                              controller.setPortions(index, portions),
                          onExplain: () => _explainItem(index),
                          onShowInGrams: (value) =>
                              controller.setShowInGrams(index, value),
                          unit: controller.unitOf(item),
                        ),
                        const SizedBox(height: 10),
                      ],
                      // SPEC-018 R3: añadir un alimento buscado a mano.
                      OutlinedButton.icon(
                        onPressed: _registering ? null : _addIngredient,
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir ingrediente'),
                      ),
                      if (widget.onRepeatToday case final repeat?) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          // No descarta en silencio lo que se editó.
                          onPressed: _registering || controller.hasChanges
                              ? null
                              : repeat,
                          icon: const Icon(Icons.replay),
                          label: Text(widget.repeatLabel),
                        ),
                      ],
                      if (widget.onSaveFavorite case final save?) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const Key('meal-detail-save-favorite'),
                          // Se guarda lo que está registrado, no lo que se
                          // está corrigiendo (SPEC-022 Open Questions).
                          onPressed: _registering || controller.hasChanges
                              ? null
                              : save,
                          icon: const Icon(Icons.star_outline),
                          label: const Text(saveFavoriteAction),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_ingredientError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _ingredientError!,
                            style: const TextStyle(color: KColors.error),
                          ),
                        ),
                      if (_registerError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _registerError!,
                            style: const TextStyle(color: KColors.error),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: controller.isEditing
                                // SPEC-026 R3.
                                ? OutlinedButton(
                                    onPressed: _registering
                                        ? null
                                        : _deleteMeal,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: KColors.error,
                                    ),
                                    child: const Text('Borrar comida'),
                                  )
                                : OutlinedButton(
                                    onPressed: _registering
                                        ? null
                                        : widget.onCorrect,
                                    child: const Text('Corregir'),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: controller.canRegister && !_registering
                                  ? _register
                                  : null,
                              child: Text(
                                controller.isEditing
                                    ? 'Guardar cambios'
                                    : 'Guardar',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final ReviewController controller;

  /// SPEC-023 R3.
  final VoidCallback onExplain;

  const _TotalsCard({required this.controller, required this.onExplain});

  @override
  Widget build(BuildContext context) {
    final totals = controller.mealTotals;
    final confidence = controller.mealConfidenceLevel;
    // Como en Hoy: "~" salvo con Alta precisión.
    final approx =
        confidence == null || confidence == ConfidenceLevel.altaPrecision
        ? ''
        : '~';
    const secondary = TextStyle(fontSize: 14, color: KColors.textSecondary);
    return KCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$approx${formatThousandsEs(presentKcal(totals.energyKcal))} kcal',
            key: const Key('meal-detail-kcal'),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w300,
              height: 1.1,
            ),
          ),
          if (confidence != null) ...[
            const SizedBox(height: 4),
            // SPEC-023 R2/R3.
            ConfidenceIndicator(
              key: const Key('meal-confidence'),
              level: confidence,
              onTap: onExplain,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              Text(
                'P $approx${formatMacroEs(totals.proteinG)} g',
                style: secondary,
              ),
              Text(
                'C $approx${formatMacroEs(totals.carbsG)} g',
                style: secondary,
              ),
              Text(
                'G $approx${formatMacroEs(totals.fatG)} g',
                style: secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// R5: todos los ítems tienen fuente (catálogo o etiqueta confirmada).
class _VerifiedSeal extends StatelessWidget {
  const _VerifiedSeal();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('verified-seal'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: KColors.confirmBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 18, color: KColors.confirmText),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Base verificada',
                style: TextStyle(
                  color: KColors.confirmText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// R4: botones en lugar del desplegable.
class _MealTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _MealTypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(:key, value: label) in mealTypeLabels.entries)
          ChoiceChip(
            key: Key('meal-type-$key'),
            label: Text(label),
            selected: value == key,
            showCheckmark: false,
            selectedColor: KColors.accent,
            labelStyle: TextStyle(
              color: value == key ? KColors.background : KColors.text,
            ),
            onSelected: (_) => onChanged(key),
          ),
      ],
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final ReviewItem item;
  final void Function(String foodId) onSelectCandidate;
  final VoidCallback onRemove;
  final void Function(double delta) onAdjustGrams;
  final VoidCallback? onUseLabel;
  final VoidCallback? onPickProduct;
  final ValueChanged<double> onSetPortions;
  final ValueChanged<bool> onShowInGrams;

  /// SPEC-023 R3: "¿Por qué?" del indicador.
  final VoidCallback onExplain;

  /// SPEC-034 R5: "g" o "ml".
  final String unit;

  const _IngredientCard({
    required this.onExplain,
    required this.item,
    required this.onSelectCandidate,
    required this.onRemove,
    required this.onAdjustGrams,
    required this.onUseLabel,
    required this.onPickProduct,
    required this.onSetPortions,
    required this.onShowInGrams,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(fontSize: 13, color: KColors.textSecondary);
    return KCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _itemName(item),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // SPEC-033 R1.
              PopupMenuButton<String>(
                key: Key('ingredient-menu-${item.mention}'),
                tooltip: 'Más opciones de ${_itemName(item)}',
                icon: const Icon(Icons.more_vert),
                onSelected: (action) => switch (action) {
                  useLabelAction => onUseLabel?.call(),
                  pickProductAction => onPickProduct?.call(),
                  _ => onRemove(),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: useLabelAction,
                    enabled: onUseLabel != null,
                    child: const ListTile(
                      leading: Icon(Icons.receipt_long_outlined),
                      title: Text(useLabelAction),
                    ),
                  ),
                  PopupMenuItem(
                    value: pickProductAction,
                    enabled: onPickProduct != null,
                    child: const ListTile(
                      leading: Icon(Icons.inventory_2_outlined),
                      title: Text(pickProductAction),
                    ),
                  ),
                  const PopupMenuItem(
                    value: removeIngredientAction,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text(removeIngredientAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text('“${item.mention}”', style: secondary),
          const SizedBox(height: 4),
          switch (item.status) {
            ReviewItemStatus.matched => _MatchedRow(
              item: item,
              onExplain: onExplain,
              onAdjustGrams: onAdjustGrams,
              onSetPortions: onSetPortions,
              onShowInGrams: onShowInGrams,
              unit: unit,
            ),
            ReviewItemStatus.ambiguous => _AmbiguousRow(
              item: item,
              onSelectCandidate: onSelectCandidate,
            ),
            ReviewItemStatus.notFound => _NotFoundRow(onRemove: onRemove),
          },
        ],
      ),
    );
  }
}

class _MatchedRow extends StatelessWidget {
  final ReviewItem item;
  final void Function(double delta) onAdjustGrams;
  final ValueChanged<double> onSetPortions;
  final ValueChanged<bool> onShowInGrams;
  final String unit;

  final VoidCallback onExplain;

  const _MatchedRow({
    required this.onExplain,
    required this.item,
    required this.onAdjustGrams,
    required this.onSetPortions,
    required this.onShowInGrams,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = item.highlightForEdit;
    // SPEC-033 R5: productos personales en porciones (de a media porción).
    final portionGrams = ReviewController.portionGramsOf(item);
    final inPortions = portionGrams != null && !item.showInGrams;
    final portions = inPortions ? ReviewController.portionsOf(item)! : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // SPEC-043 R3.
          item.withoutEquivalence
              ? withoutEquivalenceLabel
              : quantitySourceLabel(item.basis),
          style: TextStyle(
            fontSize: 13,
            color: highlight ? KColors.accent : KColors.textSecondary,
            fontWeight: highlight ? FontWeight.w500 : FontWeight.w300,
          ),
        ),
        // SPEC-023 R2.
        if (item.confidence case final level?)
          ConfidenceIndicator(
            key: Key('ingredient-confidence-${item.mention}'),
            level: level,
            compact: true,
            onTap: onExplain,
          ),
        // Con texto grande, las kcal bajan a otra línea en vez de salirse.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Menos',
                  onPressed: inPortions
                      ? (_nextHalfPortion(portions, up: false) > 0
                            ? () => onSetPortions(
                                _nextHalfPortion(portions, up: false),
                              )
                            : null)
                      : () => onAdjustGrams(-_gramsStep),
                ),
                Text(
                  inPortions
                      ? '${_portionsText(portions)} · '
                            '${item.grams.toStringAsFixed(0)} $unit'
                      : '${item.grams.toStringAsFixed(0)} $unit',
                  key: Key('ingredient-quantity-${item.mention}'),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Más',
                  onPressed: inPortions
                      ? () =>
                            onSetPortions(_nextHalfPortion(portions, up: true))
                      : () => onAdjustGrams(_gramsStep),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${presentKcal(item.nutrients!.energyKcal)} kcal',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        if (portionGrams != null)
          TextButton(
            key: Key('ingredient-toggle-unit-${item.mention}'),
            onPressed: () => onShowInGrams(inPortions),
            child: Text(inPortions ? 'Ver en $unit' : 'Ver en porciones'),
          ),
      ],
    );
  }
}

class _AmbiguousRow extends StatelessWidget {
  final ReviewItem item;
  final void Function(String foodId) onSelectCandidate;

  const _AmbiguousRow({required this.item, required this.onSelectCandidate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cuál de estos?',
          style: TextStyle(fontSize: 13, color: KColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: item.candidates
              .map(
                (candidate) => ActionChip(
                  label: Text(candidate.nameEs),
                  onPressed: () => onSelectCandidate(candidate.id),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _NotFoundRow extends StatelessWidget {
  final VoidCallback onRemove;

  const _NotFoundRow({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'No encontrado en la base',
            style: TextStyle(fontSize: 13, color: KColors.textSecondary),
          ),
        ),
        TextButton(onPressed: onRemove, child: const Text('Quitar')),
      ],
    );
  }
}

/// SPEC-023 R3: hoja con la explicación de un nivel y las acciones para
/// mejorarlo. Devuelve la acción elegida.
Future<ConfidenceAction?> _showConfidenceSheet(
  BuildContext context, {
  required ConfidenceLevel level,
  required String title,
  required String body,
  required List<ConfidenceAction> actions,
}) => showModalBottomSheet<ConfidenceAction>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        key: const Key('confidence-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConfidenceIndicator(level: level),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body),
          const SizedBox(height: 12),
          for (final action in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(action),
                icon: Icon(switch (action) {
                  ConfidenceAction.writeGrams => Icons.edit_outlined,
                  ConfidenceAction.useLabel => Icons.receipt_long_outlined,
                }),
                label: Text(switch (action) {
                  ConfidenceAction.writeGrams => writeGramsAction,
                  ConfidenceAction.useLabel => useLabelHelpAction,
                }),
              ),
            ),
        ],
      ),
    ),
  ),
);

/// SPEC-023 R3: la cantidad exacta en g o ml.
class _WriteQuantityDialog extends StatefulWidget {
  final String name;
  final String unit;
  final double initial;

  const _WriteQuantityDialog({
    required this.name,
    required this.unit,
    required this.initial,
  });

  @override
  State<_WriteQuantityDialog> createState() => _WriteQuantityDialogState();
}

class _WriteQuantityDialogState extends State<_WriteQuantityDialog> {
  late final _amount = TextEditingController(
    text: formatDecimalEs(widget.initial, maxDecimals: 1),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _value {
    final v = parseDecimal(_amount.text);
    return v == null || v <= 0 ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    return AlertDialog(
      title: Text('¿Cuánto ${widget.name}?'),
      content: TextField(
        key: const Key('write-quantity'),
        controller: _amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: widget.unit,
          errorText: _amount.text.trim().isEmpty || value != null
              ? null
              : 'Escribe una cantidad mayor que 0.',
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: value == null
              ? null
              : () => Navigator.of(context).pop(value),
          child: const Text('Listo'),
        ),
      ],
    );
  }
}
