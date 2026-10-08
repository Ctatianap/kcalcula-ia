import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/ai_client/label_extraction_dto.dart';
import '../../infra/ai_client/parsed_meal_dto.dart';
import '../../infra/food_resolution/ingredient_label_result.dart';
import '../../infra/storage/app_database.dart' show NutritionGoal;
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/macro_cards.dart';
import '../../ui/theme.dart';
import '../../ui/number_input_es.dart';
import 'label_confirmation_controller.dart';

/// SPEC-004 R3, R4: pantalla de confirmación de una etiqueta transcrita.
/// Todos los valores son editables; si Atwater falla, exige confirmación
/// explícita (AC3) antes de poder guardar.

/// SPEC-032 R1: segmentos del selector de "¿Cuánto comiste?".
const consumedUnitPortionsKey = ValueKey('consumed-unit-portions');
const consumedUnitServingKey = ValueKey('consumed-unit-serving');

/// SPEC-033 R2: "Confirmar etiqueta" abierta desde un ingrediente.
const useInIngredientButtonLabel = 'Usar en este ingrediente';
const useInIngredientNote =
    'Guardamos el producto en tus productos y lo usamos en este ingrediente.';

/// SPEC-032 R6.
const reviewMealButtonLabel = 'Revisar comida';
const reviewMealNote =
    'Guardamos el producto en tus productos y revisas la comida antes de '
    'añadirla a tu diario.';

const saveProductErrorMessage =
    'No pude guardar el producto. Intenta de nuevo.';

/// SPEC-030 R3.
const labelNumberErrorMessage =
    'Escribe un número con máximo 2 decimales, por ejemplo 1,4.';

/// SPEC-030 R1: decimales permitidos en los campos de la etiqueta.
const _labelMaxDecimals = 2;

class LabelConfirmationScreen extends ConsumerStatefulWidget {
  final LabelExtractionDto extraction;

  /// SPEC-033 R2: si viene, la etiqueta es de este ingrediente del Detalle:
  /// el botón dice "Usar en este ingrediente" y, al guardar, la pantalla
  /// se cierra devolviendo un [IngredientLabelResult] en vez de abrir
  /// Revisar.
  final String? ingredientName;

  const LabelConfirmationScreen({
    super.key,
    required this.extraction,
    this.ingredientName,
  });

  @override
  ConsumerState<LabelConfirmationScreen> createState() =>
      _LabelConfirmationScreenState();
}

class _LabelConfirmationScreenState
    extends ConsumerState<LabelConfirmationScreen> {
  late LabelConfirmationController _controller;
  bool _saving = false;

  /// SPEC-009 R3: fallo al guardar en `user.db`, sin el texto técnico.
  String? _saveError;

  /// SPEC-032 R4: meta del día para las tarjetas de la vista previa.
  NutritionGoal? _goal;

  late final _nameController = TextEditingController();
  late final _servingController = TextEditingController();
  late final _energyController = TextEditingController();
  late final _proteinController = TextEditingController();
  late final _carbsController = TextEditingController();
  late final _fatController = TextEditingController();
  late final _fiberController = TextEditingController();
  late final _sugarController = TextEditingController();
  late final _sodiumController = TextEditingController();
  late final _consumedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = LabelConfirmationController(
      extraction: widget.extraction,
      defaultProductName: widget.ingredientName,
      storage: ref.read(storageRepositoryProvider),
    );
    _nameController.text = _controller.productName;
    _servingController.text = _numberText(_controller.servingQuantity);
    _energyController.text = _numberText(_controller.energyKcal);
    _proteinController.text = _numberText(_controller.proteinG);
    _carbsController.text = _numberText(_controller.carbsG);
    _fatController.text = _numberText(_controller.fatG);
    _fiberController.text = _numberText(_controller.fiberG);
    _sugarController.text = _numberText(_controller.sugarG);
    _sodiumController.text = _numberText(_controller.sodiumMg);
    _consumedController.text = _consumedText();
    // SPEC-032 R4: sin meta (o si no se pudo leer), la vista previa muestra
    // solo los gramos; un fallo aquí no debe molestar a la persona.
    ref
        .read(storageRepositoryProvider)
        .getNutritionGoal()
        .then((goal) {
          if (mounted) setState(() => _goal = goal);
        })
        .catchError((Object _) {});
  }

  bool get _inPortions => _controller.consumedUnit == ConsumedUnit.portions;

  /// SPEC-031 R1/R2 y SPEC-032 R1: "¿Cuánto comiste?" en la unidad elegida;
  /// vacío si no hay una cantidad > 0.
  String _consumedText() {
    final value = _inPortions
        ? _controller.portionsCount
        : _controller.consumedQuantity;
    return value > 0 ? _numberText(value) : '';
  }

  /// SPEC-031 R1: en g/ml, mientras la persona no edite "¿Cuánto comiste?",
  /// el campo muestra lo que se va a registrar (la porción, SPEC-004 R5).
  /// En porciones el número no cambia: cambia lo que equivale (SPEC-032 R2).
  void _onServingChanged(double? value) {
    _controller.setServingQuantity(value);
    if (!_inPortions && !_controller.consumedQuantityTouchedByUser) {
      _consumedController.text = _consumedText();
    }
  }

  /// SPEC-032 R3: al cambiar de unidad, el campo muestra la misma cantidad.
  void _onConsumedUnitChanged(ConsumedUnit unit) {
    _controller.setConsumedUnit(unit);
    _consumedController.text = _consumedText();
  }

  /// SPEC-030 R2: se muestra con coma y redondeado; el controlador guarda
  /// el valor original mientras no se edite el campo.
  String _numberText(double? value) => value == null
      ? ''
      : formatDecimalEs(value, maxDecimals: _labelMaxDecimals);

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _servingController.dispose();
    _energyController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    _consumedController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final String productName;
      try {
        productName = await _controller.save();
      } catch (_) {
        // R3: no se relanza; el texto de SQLite trae la etiqueta.
        if (mounted) setState(() => _saveError = saveProductErrorMessage);
        return;
      }
      if (!mounted) return;
      if (widget.ingredientName != null) {
        final IngredientLabelResult result = (
          productId: _controller.savedProductId!,
          quantity: _controller.registeredQuantity,
          unit: _controller.servingUnit,
        );
        Navigator.of(context).pop(result);
        return;
      }
      // Mismo pipeline que texto/voz (R8): un ParsedMealDto de un solo
      // ítem con food_query = nombre exacto del producto recién guardado
      // (coincidencia exacta garantizada, ver food_query_resolver.dart) y
      // la cantidad consumida en g/ml explícitos -> QuantityBasis.label.
      final parsedMeal = ParsedMealDto(
        mealType: null,
        items: [
          ParsedMealItemDto(
            mention: productName,
            foodQuery: productName,
            isVague: false,
            quantity: _controller.registeredQuantity,
            unit: _controller.servingUnit,
          ),
        ],
      );
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.review, arguments: parsedMeal);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar etiqueta')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TextField(
                label: 'Nombre del producto',
                controller: _nameController,
                unreadable: _controller.unreadableFields.contains(
                  'product_name',
                ),
                onChanged: _controller.setProductName,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _NumberField(
                      label: 'Porción',
                      controller: _servingController,
                      unreadable: _controller.unreadableFields.contains(
                        'serving_size',
                      ),
                      onChanged: _onServingChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _controller.servingUnit,
                    items: const [
                      DropdownMenuItem(value: 'g', child: Text('g')),
                      DropdownMenuItem(value: 'ml', child: Text('ml')),
                    ],
                    onChanged: (value) {
                      if (value != null) _controller.setServingUnit(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _NumberField(
                label: 'Calorías por porción (kcal)',
                controller: _energyController,
                unreadable: _controller.unreadableFields.contains(
                  'energy_kcal',
                ),
                onChanged: _controller.setEnergyKcal,
              ),
              _NumberField(
                label: 'Proteína por porción (g)',
                controller: _proteinController,
                unreadable: _controller.unreadableFields.contains('protein_g'),
                onChanged: _controller.setProteinG,
              ),
              _NumberField(
                label: 'Carbohidratos por porción (g)',
                controller: _carbsController,
                unreadable: _controller.unreadableFields.contains('carbs_g'),
                onChanged: _controller.setCarbsG,
              ),
              _NumberField(
                label: 'Grasa por porción (g)',
                controller: _fatController,
                unreadable: _controller.unreadableFields.contains('fat_g'),
                onChanged: _controller.setFatG,
              ),
              _NumberField(
                label: 'Fibra por porción (g, opcional)',
                controller: _fiberController,
                unreadable: _controller.unreadableFields.contains('fiber_g'),
                onChanged: _controller.setFiberG,
              ),
              _NumberField(
                label: 'Azúcar por porción (g, opcional)',
                controller: _sugarController,
                unreadable: _controller.unreadableFields.contains('sugar_g'),
                onChanged: _controller.setSugarG,
              ),
              _NumberField(
                label: 'Sodio por porción (mg, opcional)',
                controller: _sodiumController,
                unreadable: _controller.unreadableFields.contains('sodium_mg'),
                onChanged: _controller.setSodiumMg,
              ),
              if (_controller.needsAtwaterConfirmation) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Estos valores no cuadran entre sí (calorías vs. '
                    'proteína/carbohidratos/grasa). Revisa si transcribiste '
                    'bien la etiqueta, o confirma que así está impreso.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                // Fuera del contenedor de color: un ListTile pinta su fondo
                // e ink splashes sobre el Material ancestro más cercano, y
                // el DecoratedBox de arriba lo taparía (advertencia real del
                // framework, no solo estética).
                CheckboxListTile(
                  value: _controller.atwaterConfirmedDespiteWarning,
                  onChanged: (value) => _controller
                      .setAtwaterConfirmedDespiteWarning(value ?? false),
                  title: const Text(
                    'Confirmo que los valores son correctos así',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
              const SizedBox(height: 16),
              SegmentedButton<ConsumedUnit>(
                segments: [
                  const ButtonSegment(
                    value: ConsumedUnit.portions,
                    label: Text('Porciones', key: consumedUnitPortionsKey),
                  ),
                  ButtonSegment(
                    value: ConsumedUnit.servingUnit,
                    label: Text(
                      _controller.servingUnit,
                      key: consumedUnitServingKey,
                    ),
                  ),
                ],
                selected: {_controller.consumedUnit},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    _onConsumedUnitChanged(selection.single),
              ),
              const SizedBox(height: 8),
              _NumberField(
                label: _inPortions
                    ? '¿Cuánto comiste? (porciones)'
                    : '¿Cuánto comiste? (${_controller.servingUnit})',
                controller: _consumedController,
                unreadable: false,
                onChanged: (v) => _inPortions
                    ? _controller.setPortionsCount(v ?? 0)
                    : _controller.setConsumedQuantity(v ?? 0),
              ),
              if (_controller.preview case final preview?)
                _Preview(
                  portions: _inPortions ? _controller.portionsCount : null,
                  quantity: _controller.registeredQuantity,
                  unit: _controller.servingUnit,
                  nutrients: preview.nutrients,
                  goal: _goal,
                ),
              const SizedBox(height: 16),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_controller.missingForSave.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Falta: ${_controller.missingForSave.join(', ')}.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: (_controller.canSave && !_saving) ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.ingredientName == null
                            ? reviewMealButtonLabel
                            : useInIngredientButtonLabel,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.ingredientName == null
                    ? reviewMealNote
                    : useInIngredientNote,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: KColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool unreadable;
  final ValueChanged<String> onChanged;

  const _TextField({
    required this.label,
    required this.controller,
    required this.unreadable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: unreadable ? '$label (no se pudo leer, complétalo)' : label,
      ),
      onChanged: onChanged,
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool unreadable;
  final ValueChanged<double?> onChanged;

  const _NumberField({
    required this.label,
    required this.controller,
    required this.unreadable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // SPEC-030 R3: el error depende del texto del campo, no del
      // controlador de la pantalla.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final text = value.text.trim();
          final invalid =
              text.isNotEmpty &&
              parseDecimalUpTo(text, maxDecimals: _labelMaxDecimals) == null;
          return TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: unreadable ? '$label (no se pudo leer)' : label,
              errorText: invalid ? labelNumberErrorMessage : null,
            ),
            onChanged: (text) => onChanged(
              parseDecimalUpTo(text, maxDecimals: _labelMaxDecimals),
            ),
          );
        },
      ),
    );
  }
}

/// SPEC-032 R4: lo que se va a registrar. Solo presenta lo que calculó
/// `nutrition_core` (invariante 3).
class _Preview extends StatelessWidget {
  final double? portions;

  /// Cantidad registrada en la unidad de la etiqueta (g o ml).
  final double quantity;
  final String unit;
  final NutrientTotals nutrients;
  final NutritionGoal? goal;

  const _Preview({
    required this.portions,
    required this.quantity,
    required this.unit,
    required this.nutrients,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final portionsText = portions == null
        ? null
        : '${formatDecimalEs(portions!)} '
              '${portions == 1 ? 'porción' : 'porciones'} = '
              '${formatDecimalEs(quantity, maxDecimals: 1)} $unit';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vas a registrar', style: text.titleSmall),
          if (portionsText != null) ...[
            const SizedBox(height: 4),
            Text(portionsText, style: text.bodyMedium),
          ],
          const SizedBox(height: 4),
          Text(
            '~${formatThousandsEs(presentKcal(nutrients.energyKcal))} kcal',
            style: text.titleMedium,
          ),
          const SizedBox(height: 8),
          MacroCards(
            macros: [
              (
                label: 'Proteína',
                grams: nutrients.proteinG,
                goal: goal?.proteinG,
                color: KColors.protein,
              ),
              (
                label: 'Carbohidratos',
                grams: nutrients.carbsG,
                goal: goal?.carbsG,
                color: KColors.carbs,
              ),
              (
                label: 'Grasa',
                grams: nutrients.fatG,
                goal: goal?.fatG,
                color: KColors.fat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
