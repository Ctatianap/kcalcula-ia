import 'package:nutrition_core/nutrition_core.dart';

import '../../ui/date_format_es.dart';
import '../storage/storage_repository.dart';
import 'export_range.dart';

/// SPEC-016 R3: contenido del PDF como texto. El PDF solo dibuja estas
/// cadenas, así que lo que no está aquí (fecha de nacimiento, sexo,
/// mantenimiento medido) no puede aparecer en el archivo (minimización).
class SummaryReport {
  final String title;
  final String period;
  final String? goal;
  final String average;
  final String? daysOnGoal;
  final List<String> weights;
  final List<ReportDay> days;
  final String footer;

  const SummaryReport({
    required this.title,
    required this.period,
    required this.goal,
    required this.average,
    required this.daysOnGoal,
    required this.weights,
    required this.days,
    required this.footer,
  });

  /// Todo el texto que va al PDF, para inspeccionarlo.
  Iterable<String> get allText sync* {
    yield title;
    yield period;
    if (goal != null) yield goal!;
    yield average;
    if (daysOnGoal != null) yield daysOnGoal!;
    yield* weights;
    for (final day in days) {
      yield* day.cells;
      yield* day.meals;
    }
    yield footer;
  }
}

class ReportDay {
  /// Fecha, kcal, proteína, carbohidratos y grasa (fila de la tabla).
  final List<String> cells;

  /// "8:05 · Desayuno · Huevo 100 g, Arepa 115 g · 450 kcal".
  final List<String> meals;

  const ReportDay({required this.cells, required this.meals});
}

const reportFooter =
    'Estimaciones calculadas por KCalcula IA; no reemplazan una valoración '
    'profesional.';

const reportTableHeader = [
  'Día',
  'kcal',
  'Proteína (g)',
  'Carbohidratos (g)',
  'Grasa (g)',
];

String _k(double v) => formatThousandsEs(presentKcal(v));

String _date(DateTime d) => '${d.day} de ${monthsEs[d.month - 1]} de ${d.year}';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Arma el resumen con las comidas y pesos ya filtrados por [range]. Los
/// totales y promedios salen de `nutrition_core` (invariante 3).
SummaryReport buildSummaryReport({
  required List<MealWithItems> meals,
  required ExportRange range,
  required NutritionGoal? goal,
  required List<WeightLogData> weights,
}) {
  final byDay = <DateTime, List<MealWithItems>>{};
  for (final meal in meals) {
    byDay.putIfAbsent(_dateOnly(meal.meal.eatenAt), () => []).add(meal);
  }
  final dates = byDay.keys.toList()..sort();
  final logged = [
    for (final date in dates)
      (date: date, totals: sumNutrients(byDay[date]!.map((m) => m.totals))),
  ];
  final summary = summarizePeriod(logged, goalKcal: goal?.energyKcal);
  final approx =
      meals.any((m) => m.meal.confidence != ConfidenceLevel.altaPrecision.name)
      ? '~'
      : '';

  final String period;
  if (range.isAll) {
    period = dates.isEmpty
        ? 'Periodo: todo el registro'
        : 'Periodo: todo el registro (del ${_date(dates.first)} al '
              '${_date(dates.last)})';
  } else {
    period = 'Periodo: del ${_date(range.from!)} al ${_date(range.to!)}';
  }

  final avg = summary.average;
  final days = <ReportDay>[];
  for (final day in logged) {
    final dayMeals = byDay[day.date]!
      ..sort((a, b) => a.meal.eatenAt.compareTo(b.meal.eatenAt));
    days.add(
      ReportDay(
        cells: [
          '${weekdaysEs[day.date.weekday - 1]} ${day.date.day}/'
              '${day.date.month}/${day.date.year}',
          _k(day.totals.energyKcal),
          formatMacroEs(day.totals.proteinG),
          formatMacroEs(day.totals.carbsG),
          formatMacroEs(day.totals.fatG),
        ],
        meals: [
          for (final m in dayMeals)
            '${timeEs(m.meal.eatenAt)} · '
                '${mealTypeLabels[m.meal.mealType] ?? 'Snack'} · '
                '${m.items.map((i) => '${i.nameSnapshot} ${i.grams.round()} g').join(', ')}'
                ' · ${_k(m.totals.energyKcal)} kcal',
        ],
      ),
    );
  }

  return SummaryReport(
    title: 'Resumen de alimentación · KCalcula IA',
    period: period,
    goal: goal == null
        ? null
        : 'Meta diaria actual: ${_k(goal.energyKcal)} kcal · Proteína '
              '${formatMacroEs(goal.proteinG)} g · Carbohidratos '
              '${formatMacroEs(goal.carbsG)} g · Grasa '
              '${formatMacroEs(goal.fatG)} g',
    average: avg == null
        ? 'Sin comidas en este periodo.'
        : 'Promedio diario: $approx${_k(avg.energyKcal)} kcal · Proteína '
              '${formatMacroEs(avg.proteinG)} g · Carbohidratos '
              '${formatMacroEs(avg.carbsG)} g · Grasa '
              '${formatMacroEs(avg.fatG)} g (sobre ${summary.loggedDays} '
              '${summary.loggedDays == 1 ? 'día' : 'días'} con registros)',
    daysOnGoal: summary.daysOnGoal == null
        ? null
        : 'Días en meta: ${summary.daysOnGoal} de ${summary.loggedDays} '
              '(del 90 % al 110 % de la meta actual)',
    weights: [
      for (final w in weights)
        'Peso del ${_date(w.day)}: ${formatMacroEs(w.weightKg)} kg',
    ],
    days: days,
    footer: reportFooter,
  );
}
