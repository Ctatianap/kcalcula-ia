import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/clock.dart';
import '../../infra/storage/storage_providers.dart';
import '../../ui/components/empty_state.dart';
import '../../ui/components/k_card.dart';
import '../../ui/components/main_nav_bar.dart';
import '../../ui/date_format_es.dart';
import '../../ui/theme.dart';
import 'progress_controller.dart';

const noRecordsInPeriodMessage = 'Todavía no hay registros en este periodo.';

String _k(double v) => formatThousandsEs(presentKcal(v));

String _shortDate(DateTime d) =>
    '${d.day} ${monthsEs[d.month - 1].substring(0, 3)}';

const _statusStyles = {
  DayStatus.belowGoal: DayGoalStatus.belowGoal,
  DayStatus.onGoal: DayGoalStatus.onGoal,
  DayStatus.aboveGoal: DayGoalStatus.aboveGoal,
};

/// SPEC-014: promedios de kcal y macros por periodo y días en meta.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressPeriod _period = ProgressPeriod.week;
  late Future<ProgressData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = loadProgress(
      ref.read(storageRepositoryProvider),
      _period,
      ref.read(clockProvider)(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Atrás vuelve a Hoy en vez de cerrar la app (SPEC-010, Edge Cases).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) backToToday(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Progreso')),
        bottomNavigationBar: MainNavBar(
          current: MainTab.progress,
          onAdd: () => openCaptureFromTab(context),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ProgressPeriod>(
                showSelectedIcon: false,
                segments: [
                  for (final p in ProgressPeriod.values)
                    ButtonSegment(value: p, label: Text(p.label)),
                ],
                selected: {_period},
                onSelectionChanged: (value) => setState(() {
                  _period = value.first;
                  _load();
                }),
              ),
              const SizedBox(height: 16),
              FutureBuilder<ProgressData>(
                future: _future,
                builder: (context, snapshot) {
                  // SPEC-009 R4: una lectura fallida no deja el spinner.
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        const SizedBox(height: 40),
                        const Text('No pude leer tus datos. Intenta de nuevo.'),
                        TextButton(
                          onPressed: () => setState(_load),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    );
                  }
                  final data = snapshot.data;
                  if (data == null ||
                      snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _ProgressBody(data: data);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  final ProgressData data;

  const _ProgressBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final average = data.summary.average;
    if (average == null) {
      // R6: sin gráfico ni promedios.
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: EmptyState(
          icon: Icons.bar_chart_outlined,
          title: noRecordsInPeriodMessage,
        ),
      );
    }
    final approx = data.isApproximate ? '~' : '';
    final text = Theme.of(context).textTheme;
    const secondary = TextStyle(fontSize: 14, color: KColors.textSecondary);
    final goal = data.goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KCard(
          radius: 28,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Promedio diario', style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                '$approx${_k(average.energyKcal)} kcal',
                key: const Key('progress-average'),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sobre ${data.summary.loggedDays} '
                '${data.summary.loggedDays == 1 ? 'día' : 'días'} con registros',
                style: secondary,
              ),
              if (goal != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${data.summary.daysOnGoal} de '
                      '${data.summary.loggedDays} días en meta',
                      key: const Key('progress-days-on-goal'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'meta ${_k(goal.energyKcal)}',
                      key: const Key('progress-goal'),
                      style: secondary,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _BarChart(data: data),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Macros, promedio diario', style: text.titleMedium),
        const SizedBox(height: 10),
        _MacroAverages(average: average, approx: approx),
      ],
    );
  }
}

/// R4: barras por día (Semana) o por semana (Mes, 3 meses), con la línea
/// de la meta. Cada barra lleva su valor como etiqueta semántica (AC6).
class _BarChart extends StatelessWidget {
  final ProgressData data;

  const _BarChart({required this.data});

  static const _height = 140.0;

  String _label(ProgressBar bar) => data.period == ProgressPeriod.week
      ? weekdayInitials[bar.start.weekday - 1]
      : _shortDate(bar.start);

  String _semantics(ProgressBar bar) {
    final when = data.period == ProgressPeriod.week
        ? longDateEs(bar.start)
        : 'Semana del ${bar.start.day} de ${monthsEs[bar.start.month - 1]}';
    final kcal = bar.kcal;
    if (kcal == null) return '$when: sin registros';
    final value = data.period == ProgressPeriod.week
        ? '${_k(kcal)} kcal'
        : '${_k(kcal)} kcal de promedio diario';
    final status = bar.status;
    return status == null
        ? '$when: $value'
        : '$when: $value, ${_statusStyles[status]!.label.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final goal = data.goal?.energyKcal;
    final values = data.bars.map((b) => b.kcal ?? 0);
    final top = [...values, goal ?? 0].reduce((a, b) => a > b ? a : b) * 1.15;
    final showEveryLabel = data.bars.length <= 7;
    return Column(
      children: [
        SizedBox(
          height: _height,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, bar) in data.bars.indexed)
                    Expanded(
                      child: Semantics(
                        key: Key('progress-bar-$i'),
                        container: true,
                        label: _semantics(bar),
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: bar.kcal == null
                                ? Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: KColors.track,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  )
                                : Container(
                                    height: top <= 0
                                        ? 4
                                        : (bar.kcal! / top * _height).clamp(
                                            4,
                                            _height,
                                          ),
                                    decoration: BoxDecoration(
                                      color: bar.status == null
                                          ? KColors.accent
                                          : _statusStyles[bar.status]!.color,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (goal != null && top > 0)
                Positioned(
                  key: const Key('progress-goal-line'),
                  left: 0,
                  right: 0,
                  bottom: goal / top * _height,
                  child: ExcludeSemantics(
                    child: Container(height: 1.5, color: KColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final (i, bar) in data.bars.indexed)
                Expanded(
                  child: showEveryLabel || i.isEven
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _label(bar),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 11,
                              color: KColors.textSecondary,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// R5: promedio diario de cada macro, con su color.
class _MacroAverages extends StatelessWidget {
  final NutrientTotals average;
  final String approx;

  const _MacroAverages({required this.average, required this.approx});

  @override
  Widget build(BuildContext context) {
    final macros = [
      ('Proteína', average.proteinG, KColors.protein, 'protein'),
      ('Carbohidratos', average.carbsG, KColors.carbs, 'carbs'),
      ('Grasa', average.fatG, KColors.fat, 'fat'),
    ];
    return Row(
      children: [
        for (final (i, (label, grams, color, key)) in macros.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: KCard(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 13,
                        color: KColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$approx${formatMacroEs(grams)} g',
                      key: Key('progress-macro-$key'),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
