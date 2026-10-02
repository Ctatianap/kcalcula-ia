import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = NutritionGoalController(
      storage: ref.read(storageRepositoryProvider),
    );
    _controller.load().then((_) {
      _kcalField.text = _controller.kcalText;
      for (final f in MacroField.values) {
        _macroFields[f]!.text = _controller.macroText[f]!;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _kcalField.dispose();
    for (final c in _macroFields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await _controller.save();
    if (saved && mounted) Navigator.of(context).maybePop();
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
                    labelText: _macroLabels[f],
                    border: const OutlineInputBorder(),
                    errorText: _controller.macroError(f),
                  ),
                  onChanged: (text) => _controller.setMacro(f, text),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.canSave ? _save : null,
                child: const Text('Guardar'),
              ),
              if (_controller.hasEstimationInputs)
                TextButton(
                  onPressed: _controller.deleteEstimationInputs,
                  child: const Text('Borrar mis datos para la sugerencia'),
                ),
            ],
          );
        },
      ),
    );
  }
}
