import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_repository.dart';

/// SPEC-014 R1: últimos 7, 30 o 90 días, hoy incluido.
enum ProgressPeriod {
  week('Semana', 7),
  month('Mes', 30),
  threeMonths('3 meses', 90);

  const ProgressPeriod(this.label, this.days);

  final String label;
  final int days;
}

/// Una barra del gráfico: un día (Semana) o una semana (Mes, 3 meses).
/// `kcal` es `null` si no hubo registros.
class ProgressBar {
  final DateTime start;
  final double? kcal;
  final DayStatus? status;

  const ProgressBar({
    required this.start,
    required this.kcal,
    required this.status,
  });
}

class ProgressData {
  final ProgressPeriod period;
  final DateTime from;
  final DateTime today;
  final NutritionGoal? goal;
  final PeriodSummary summary;
  final List<ProgressBar> bars;

  /// "~" si alguna comida del periodo no es "Alta precisión" (SPEC-008 R6).
  final bool isApproximate;

  const ProgressData({
    required this.period,
    required this.from,
    required this.today,
    required this.goal,
    required this.summary,
    required this.bars,
    required this.isApproximate,
  });
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Una sola consulta por periodo; los días se agrupan por la fecha local de
/// `eaten_at`. Sumas, promedios y estados salen de `nutrition_core`.
Future<ProgressData> loadProgress(
  StorageRepository storage,
  ProgressPeriod period,
  DateTime now,
) async {
  final today = _dateOnly(now);
  final from = DateTime(today.year, today.month, today.day - (period.days - 1));
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final meals = await storage.mealsBetween(from, tomorrow);
  final goal = await storage.getNutritionGoal();
  final goalKcal = goal?.energyKcal;

  final byDate = <DateTime, List<NutrientTotals>>{};
  for (final meal in meals) {
    byDate.putIfAbsent(_dateOnly(meal.meal.eatenAt), () => []).add(meal.totals);
  }
  final logged = [
    for (final MapEntry(key: date, value: totals) in byDate.entries)
      (date: date, totals: sumNutrients(totals)),
  ]..sort((a, b) => a.date.compareTo(b.date));

  DayStatus? statusOf(double? kcal) =>
      kcal == null ? null : dayStatus(consumedKcal: kcal, goalKcal: goalKcal);

  final List<ProgressBar> bars;
  if (period == ProgressPeriod.week) {
    final byDay = {for (final d in logged) d.date: d.totals.energyKcal};
    bars = [
      for (var i = 0; i < period.days; i++)
        () {
          final date = DateTime(from.year, from.month, from.day + i);
          final kcal = byDay[date];
          return ProgressBar(start: date, kcal: kcal, status: statusOf(kcal));
        }(),
    ];
  } else {
    bars = [
      for (final week in weeklyAverages(logged, from: from, to: today))
        ProgressBar(
          start: week.monday,
          kcal: week.averageKcal,
          status: statusOf(week.averageKcal),
        ),
    ];
  }

  return ProgressData(
    period: period,
    from: from,
    today: today,
    goal: goal,
    summary: summarizePeriod(logged, goalKcal: goalKcal),
    bars: bars,
    isApproximate: meals.any(
      (m) => m.meal.confidence != ConfidenceLevel.altaPrecision.name,
    ),
  );
}
