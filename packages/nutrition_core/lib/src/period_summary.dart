/// SPEC-014: promedios y días en meta de un periodo.
///
/// **Decisión de producto (SPEC-014 R2):** los promedios diarios cuentan
/// solo los días con al menos un registro. Un día no registrado no es un
/// día en 0 kcal. Todo se suma y divide sin redondear; se redondea al
/// presentar.
library;

import 'day_status.dart';
import 'nutrient_calculation.dart';

/// Totales de un día con registros, en su fecha local (00:00).
typedef LoggedDay = ({DateTime date, NutrientTotals totals});

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Lunes de la semana de [date], por fecha de calendario (sin restar días
/// de 24 h, que fallan con el cambio de hora).
DateTime mondayOf(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - 1));

/// Promedio diario de nutrientes sobre los días con registros; `null` si no
/// hay ninguno.
NutrientTotals? dailyAverage(Iterable<LoggedDay> days) {
  final list = days.toList();
  if (list.isEmpty) return null;
  final sum = sumNutrients(list.map((d) => d.totals));
  final n = list.length;
  return (
    energyKcal: sum.energyKcal / n,
    proteinG: sum.proteinG / n,
    carbsG: sum.carbsG / n,
    fatG: sum.fatG / n,
  );
}

/// SPEC-014 R3: cuántos días con registros quedaron "en tu meta"
/// (SPEC-011 R3). `null` sin meta positiva.
int? daysOnGoal(Iterable<LoggedDay> days, {double? goalKcal}) {
  if (goalKcal == null || goalKcal <= 0) return null;
  return days
      .where(
        (d) =>
            dayStatus(consumedKcal: d.totals.energyKcal, goalKcal: goalKcal) ==
            DayStatus.onGoal,
      )
      .length;
}

class PeriodSummary {
  /// Días con al menos un registro (M de "N de M días en meta").
  final int loggedDays;

  /// `null` si no hubo registros en el periodo (R6).
  final NutrientTotals? average;

  /// `null` sin meta (R7).
  final int? daysOnGoal;

  const PeriodSummary({
    required this.loggedDays,
    required this.average,
    required this.daysOnGoal,
  });
}

PeriodSummary summarizePeriod(List<LoggedDay> days, {double? goalKcal}) =>
    PeriodSummary(
      loggedDays: days.length,
      average: dailyAverage(days),
      daysOnGoal: daysOnGoal(days, goalKcal: goalKcal),
    );

/// Una semana (lunes a domingo) con el promedio diario de sus días con
/// registros dentro del periodo.
class WeekAverage {
  final DateTime monday;
  final int loggedDays;

  /// `null` si la semana no tiene registros.
  final double? averageKcal;

  const WeekAverage({
    required this.monday,
    required this.loggedDays,
    required this.averageKcal,
  });
}

/// SPEC-014 R4/AC4: una entrada por semana, de la semana de [from] a la de
/// [to] (ambas fechas incluidas), en orden. Solo cuentan los días de [days]
/// entre [from] y [to].
List<WeekAverage> weeklyAverages(
  List<LoggedDay> days, {
  required DateTime from,
  required DateTime to,
}) {
  final start = _dateOnly(from);
  final end = _dateOnly(to);
  final inRange = days.where((d) {
    final date = _dateOnly(d.date);
    return !date.isBefore(start) && !date.isAfter(end);
  });
  final byWeek = <DateTime, List<LoggedDay>>{};
  for (final day in inRange) {
    byWeek.putIfAbsent(mondayOf(day.date), () => []).add(day);
  }
  final weeks = <WeekAverage>[];
  for (
    var monday = mondayOf(start);
    !monday.isAfter(end);
    monday = DateTime(monday.year, monday.month, monday.day + 7)
  ) {
    final weekDays = byWeek[monday] ?? const <LoggedDay>[];
    weeks.add(
      WeekAverage(
        monday: monday,
        loggedDays: weekDays.length,
        averageKcal: dailyAverage(weekDays)?.energyKcal,
      ),
    );
  }
  return weeks;
}
