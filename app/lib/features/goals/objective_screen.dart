import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/storage/storage_providers.dart';
import 'goal_calculation.dart';
import 'objective_controller.dart';

/// SPEC-008 R6–R10: "Mi objetivo".
class ObjectiveScreen extends ConsumerStatefulWidget {
  const ObjectiveScreen({super.key});

  @override
  ConsumerState<ObjectiveScreen> createState() => _ObjectiveScreenState();
}

class _ObjectiveScreenState extends ConsumerState<ObjectiveScreen> {
  late final ObjectiveController _controller;
  final _manualKcal = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ObjectiveController(
      storage: ref.read(storageRepositoryProvider),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualKcal.dispose();
    super.dispose();
  }

  Future<void> _done(Future<bool> save) async {
    if (await save && mounted) Navigator.of(context).maybePop();
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).pushNamed(AppRoutes.profile);
    await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi objetivo')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          if (!c.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!c.hasProfile || c.maintenance == null) {
            return _NeedsProfile(onOpenProfile: _openProfile);
          }
          final text = Theme.of(context).textTheme;
          final suggested = c.suggestedForManualGoal;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tu mantenimiento: ${approxKcal(c.maintenance!)}',
                style: text.titleMedium,
              ),
              if (suggested != null)
                Card(
                  margin: const EdgeInsets.only(top: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu meta es manual '
                          '(${formatThousandsEs(presentKcal(c.currentGoal!.energyKcal))} kcal). '
                          'Con tu perfil actual, '
                          '"${objectiveTexts[c.manualGoalObjective]!.$1}" sería '
                          '${approxKcal(suggested)}.',
                        ),
                        TextButton(
                          onPressed: isValidGoalKcal(suggested)
                              ? () => _done(c.useSuggestedForManualGoal())
                              : null,
                          child: const Text('Usar este valor'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              RadioGroup<GoalObjective>(
                groupValue: c.selected,
                onChanged: (v) {
                  if (v != null) c.select(v);
                },
                child: Column(
                  children: [
                    for (final objective in GoalObjective.values)
                      _ObjectiveOption(controller: c, objective: objective),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: c.busy || !c.isInRange(c.selected)
                    ? null
                    : () => _done(c.useSelectedObjective()),
                child: const Text('Usar como mi meta diaria'),
              ),
              if (!c.isInRange(c.selected))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(objectiveOutOfRangeMessage),
                ),
              const Divider(height: 32),
              Text('O escribe tu meta a mano', style: text.titleSmall),
              TextField(
                key: const Key('manual-kcal'),
                controller: _manualKcal,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Calorías (kcal)',
                  errorText: c.manualKcalError,
                  helperText:
                      c.manualKcalWarning ??
                      'Los macros se reparten como en '
                          '"${objectiveTexts[c.selected]!.$1}".',
                  helperMaxLines: 3,
                ),
                onChanged: c.setManualKcal,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: c.canSaveManual ? () => _done(c.saveManual()) : null,
                child: const Text('Guardar meta manual'),
              ),
              if (c.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    c.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(disclaimerText, style: text.bodySmall),
            ],
          );
        },
      ),
    );
  }
}

class _ObjectiveOption extends StatelessWidget {
  final ObjectiveController controller;
  final GoalObjective objective;

  const _ObjectiveOption({required this.controller, required this.objective});

  @override
  Widget build(BuildContext context) {
    final kcal = controller.kcalFor(objective)!;
    final (title, subtitle) = objectiveTexts[objective]!;
    return RadioListTile<GoalObjective>(
      key: Key('objective-${objective.name}'),
      contentPadding: EdgeInsets.zero,
      value: objective,
      title: Text('$title · ${approxKcal(kcal)}'),
      subtitle: Text(
        '$subtitle\n${macroSummary(macroGramsFor(kcal, objective))}',
      ),
      isThreeLine: true,
    );
  }
}

class _NeedsProfile extends StatelessWidget {
  final VoidCallback onOpenProfile;

  const _NeedsProfile({required this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para calcular tu objetivo primero necesito tu perfil: '
              'sexo, fecha de nacimiento, estatura, peso y actividad.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onOpenProfile,
              child: const Text('Completar mi perfil'),
            ),
          ],
        ),
      ),
    );
  }
}
