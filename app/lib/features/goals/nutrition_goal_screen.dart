import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_providers.dart';
import 'nutrition_goal_controller.dart';

const _macroLabels = {
  MacroField.protein: 'Proteína (g, opcional)',
  MacroField.carbs: 'Carbohidratos (g, opcional)',
  MacroField.fat: 'Grasa (g, opcional)',
};

/// SPEC-008 R1: "Mi meta diaria".
class NutritionGoalScreen extends ConsumerStatefulWidget {
  const NutritionGoalScreen({super.key});

  @override
  ConsumerState<NutritionGoalScreen> createState() =>
      _NutritionGoalScreenState();
}

class _NutritionGoalScreenState extends ConsumerState<NutritionGoalScreen> {
  late final NutritionGoalController _controller;
  final _kcalField = TextEditingController();
  final _macroFields = {
    for (final f in MacroField.values) f: TextEditingController(),
  };
  final _weightField = TextEditingController();
  final _heightField = TextEditingController();
  final _ageField = TextEditingController();
  bool _showSuggestion = false;

  @override
  void initState() {
    super.initState();
    _controller = NutritionGoalController(
      storage: ref.read(storageRepositoryProvider),
    );
    _controller.load().then((_) {
      _kcalField.text = _controller.kcalText;
      _syncGoalFields();
      _weightField.text = _controller.weightText;
      _heightField.text = _controller.heightText;
      _ageField.text = _controller.ageText;
    });
  }

  void _syncGoalFields() {
    _kcalField.text = _controller.kcalText;
    for (final f in MacroField.values) {
      _macroFields[f]!.text = _controller.macroText[f]!;
    }
  }

  void _applySuggestion() {
    _controller.applySuggestion();
    _syncGoalFields();
  }

  @override
  void dispose() {
    _controller.dispose();
    _kcalField.dispose();
    _weightField.dispose();
    _heightField.dispose();
    _ageField.dispose();
    for (final c in _macroFields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await _controller.save();
    if (saved && mounted) Navigator.of(context).maybePop();
  }

  Future<void> _deleteEstimationInputs() async {
    await _controller.deleteEstimationInputs();
    if (!_controller.hasEstimationInputs) {
      _weightField.clear();
      _heightField.clear();
      _ageField.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi meta diaria')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (!_controller.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final warning = _controller.kcalWarning;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: const Key('goal-kcal'),
                controller: _kcalField,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: _controller.suggestedFields.contains('kcal')
                      ? '~'
                      : null,
                  labelText: 'Calorías (kcal)',
                  border: const OutlineInputBorder(),
                  errorText: _controller.kcalError,
                  helperText: warning,
                  helperMaxLines: 3,
                ),
                onChanged: _controller.setKcal,
              ),
              for (final f in MacroField.values) ...[
                const SizedBox(height: 12),
                TextField(
                  key: Key('goal-${f.name}'),
                  controller: _macroFields[f],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    prefixText: _controller.suggestedFields.contains(f)
                        ? '~'
                        : null,
                    labelText: _macroLabels[f],
                    border: const OutlineInputBorder(),
                    errorText: _controller.macroError(f),
                  ),
                  onChanged: (text) => _controller.setMacro(f, text),
                ),
              ],
              if (_controller.suggestionApplied) ...[
                const SizedBox(height: 12),
                const Text(estimationDisclaimer),
              ],
              const SizedBox(height: 16),
              if (!_showSuggestion)
                OutlinedButton(
                  onPressed: () => setState(() => _showSuggestion = true),
                  child: const Text('Calcular una sugerencia'),
                )
              else
                _SuggestionForm(
                  controller: _controller,
                  weightField: _weightField,
                  heightField: _heightField,
                  ageField: _ageField,
                  onCalculate: _applySuggestion,
                ),
              if (_controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.canSave ? _save : null,
                child: const Text('Guardar'),
              ),
              if (_controller.hasEstimationInputs)
                TextButton(
                  onPressed: _deleteEstimationInputs,
                  child: const Text('Borrar mis datos para la sugerencia'),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// SPEC-008 R2/R14: datos para la sugerencia. Solo se guardan si el usuario
/// guarda una meta después de calcular (R8/R9).
class _SuggestionForm extends StatelessWidget {
  final NutritionGoalController controller;
  final TextEditingController weightField;
  final TextEditingController heightField;
  final TextEditingController ageField;
  final VoidCallback onCalculate;

  const _SuggestionForm({
    required this.controller,
    required this.weightField,
    required this.heightField,
    required this.ageField,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sugerencia', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: const Key('estimation-weight'),
              controller: weightField,
              keyboardType: decimal,
              decoration: InputDecoration(
                labelText: 'Peso (kg)',
                errorText: controller.weightError,
              ),
              onChanged: controller.setWeight,
            ),
            TextField(
              key: const Key('estimation-height'),
              controller: heightField,
              keyboardType: decimal,
              decoration: InputDecoration(
                labelText: 'Estatura (cm)',
                errorText: controller.heightError,
              ),
              onChanged: controller.setHeight,
            ),
            TextField(
              key: const Key('estimation-age'),
              controller: ageField,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Edad (años)',
                errorText: controller.ageError,
                errorMaxLines: 2,
              ),
              onChanged: controller.setAge,
            ),
            const SizedBox(height: 12),
            const Text('Sexo (lo usa la fórmula)'),
            const SizedBox(height: 4),
            SegmentedButton<BiologicalSex>(
              segments: const [
                ButtonSegment(
                  value: BiologicalSex.female,
                  label: Text('Femenino'),
                ),
                ButtonSegment(
                  value: BiologicalSex.male,
                  label: Text('Masculino'),
                ),
              ],
              emptySelectionAllowed: true,
              selected: {?controller.sex},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) controller.setSex(s.first);
              },
            ),
            const SizedBox(height: 12),
            const Text('Nivel de actividad'),
            RadioGroup<ActivityLevel>(
              groupValue: controller.activityLevel,
              onChanged: (v) {
                if (v != null) controller.setActivityLevel(v);
              },
              child: Column(
                children: [
                  for (final level in ActivityLevel.values)
                    RadioListTile<ActivityLevel>(
                      contentPadding: EdgeInsets.zero,
                      value: level,
                      title: Text(activityLevelTexts[level]!.$1),
                      subtitle: Text(activityLevelTexts[level]!.$2),
                    ),
                ],
              ),
            ),
            const Text(activityLevelNote),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: controller.canEstimate ? onCalculate : null,
              child: const Text('Calcular'),
            ),
          ],
        ),
      ),
    );
  }
}
