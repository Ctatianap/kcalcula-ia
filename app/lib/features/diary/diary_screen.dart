import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../app_routes.dart';
import '../../infra/storage/storage_providers.dart';
import 'diary_controller.dart';

const _mealTypeLabels = {
  'desayuno': 'Desayuno',
  'almuerzo': 'Almuerzo',
  'cena': 'Cena',
  'snack': 'Snack',
};

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late Future<DiarySummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _summaryFuture = loadDiarySummary(
      ref.read(storageRepositoryProvider),
      DateTime.now(),
    );
  }

  Future<void> _openCapture() async {
    await Navigator.of(context).pushNamed(AppRoutes.capture);
    setState(_reload);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).pushNamed(AppRoutes.settings);
    setState(_reload);
  }

  Future<void> _openObjective() async {
    await Navigator.of(context).pushNamed(AppRoutes.objective);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: _openSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCapture,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<DiarySummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          // SPEC-009 R4: una lectura fallida no deja el spinner para siempre.
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No pude leer tus datos. Intenta de nuevo.'),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: summary.goal == null
                    ? _NoGoalHeader(summary: summary, onSetGoal: _openObjective)
                    : _GoalHeader(summary: summary),
              ),
              Expanded(
                child: summary.meals.isEmpty
                    ? const Center(
                        child: Text('Todavía no registras nada hoy.'),
                      )
                    : ListView(
                        children: summary.meals
                            .map((m) => _MealTile(summary: m))
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// SPEC-008 R7: sin meta, el diario se ve como antes, más un enlace discreto.
class _NoGoalHeader extends StatelessWidget {
  final DiarySummary summary;
  final VoidCallback onSetGoal;

  const _NoGoalHeader({required this.summary, required this.onSetGoal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.meals.isNotEmpty)
          Text(
            'Total del día: ${presentKcal(summary.dayTotals.energyKcal)} kcal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        TextButton(onPressed: onSetGoal, child: const Text('Calcular mi meta')),
      ],
    );
  }
}

/// SPEC-008 R6: consumido / meta y lo que queda, en tono neutro (sin rojo).
class _GoalHeader extends StatelessWidget {
  final DiarySummary summary;

  const _GoalHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final goal = summary.goal!;
    final totals = summary.dayTotals;
    final approx = summary.isApproximate;
    final macros = [
      ('Proteína', totals.proteinG, goal.proteinG),
      ('Carbohidratos', totals.carbsG, goal.carbsG),
      ('Grasa', totals.fatG, goal.fatG),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressLine(
          text: kcalProgressText(
            GoalProgress(consumed: totals.energyKcal, goal: goal.energyKcal),
            approximate: approx,
          ),
          progress: GoalProgress(
            consumed: totals.energyKcal,
            goal: goal.energyKcal,
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final (label, consumed, target) in macros)
          _ProgressLine(
            text: macroProgressText(
              label,
              GoalProgress(consumed: consumed, goal: target),
              approximate: approx,
            ),
            progress: GoalProgress(consumed: consumed, goal: target),
          ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String text;
  final GoalProgress progress;
  final TextStyle? style;

  const _ProgressLine({required this.text, required this.progress, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: style),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: progress.fraction),
        ],
      ),
    );
  }
}

/// SPEC-008 R6/AC6: "1.250 / 2.000 kcal · quedan 750".
String kcalProgressText(GoalProgress p, {required bool approximate}) {
  String k(double v) => formatThousandsEs(presentKcal(v));
  final head = '${approximate ? '~' : ''}${k(p.consumed)} / ${k(p.goal)} kcal';
  return p.isOverGoal
      ? '$head · ${k(p.excess)} por encima de la meta'
      : '$head · quedan ${k(p.remaining)}';
}

/// SPEC-008 R6: "Proteína: 45,3 / 100,0 g · quedan 54,7 g".
String macroProgressText(
  String label,
  GoalProgress p, {
  required bool approximate,
}) {
  final head =
      '$label: ${approximate ? '~' : ''}${formatMacroEs(p.consumed)} / '
      '${formatMacroEs(p.goal)} g';
  return p.isOverGoal
      ? '$head · ${formatMacroEs(p.excess)} g por encima de la meta'
      : '$head · quedan ${formatMacroEs(p.remaining)} g';
}

class _MealTile extends StatelessWidget {
  final DiaryMealSummary summary;

  const _MealTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final label = _mealTypeLabels[summary.meal.meal.mealType] ?? 'Snack';
    return ListTile(
      title: Text(label),
      subtitle: Text(summary.meal.items.map((i) => i.nameSnapshot).join(', ')),
      trailing: Text('${presentKcal(summary.totals.energyKcal)} kcal'),
    );
  }
}
