import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_routes.dart';
import '../../infra/ai_client/label_extraction_dto.dart';
import '../../infra/ai_client/parsed_meal_dto.dart';
import '../../infra/storage/storage_providers.dart';
import 'label_confirmation_controller.dart';

/// SPEC-004 R3, R4: pantalla de confirmación de una etiqueta transcrita.
/// Todos los valores son editables; si Atwater falla, exige confirmación
/// explícita (AC3) antes de poder guardar.
class LabelConfirmationScreen extends ConsumerStatefulWidget {
  final LabelExtractionDto extraction;

  const LabelConfirmationScreen({super.key, required this.extraction});

  @override
  ConsumerState<LabelConfirmationScreen> createState() =>
      _LabelConfirmationScreenState();
}

class _LabelConfirmationScreenState
    extends ConsumerState<LabelConfirmationScreen> {
  late LabelConfirmationController _controller;
  bool _saving = false;

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
    _consumedController.text = _numberText(_controller.consumedQuantity);
  }

  String _numberText(double? value) => value == null ? '' : value.toString();

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
    setState(() => _saving = true);
    try {
      final productName = await _controller.save();
      if (!mounted) return;
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
            quantity: _controller.consumedQuantity,
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
                      onChanged: _controller.setServingQuantity,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estos valores no cuadran entre sí (calorías vs. '
                        'proteína/carbohidratos/grasa). Revisa si transcribiste '
                        'bien la etiqueta, o confirma que así está impreso.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
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
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _NumberField(
                label: '¿Cuánto comiste? (${_controller.servingUnit})',
                controller: _consumedController,
                unreadable: false,
                onChanged: (v) => _controller.setConsumedQuantity(v ?? 0),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: (_controller.canSave && !_saving) ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar y continuar'),
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
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: unreadable ? '$label (no se pudo leer)' : label,
        ),
        onChanged: (text) => onChanged(double.tryParse(text)),
      ),
    );
  }
}
