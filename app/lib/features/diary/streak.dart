/// SPEC-019 R1/R4: días seguidos, hasta hoy, con al menos una comida. Si hoy
/// aún no hay registros, cuenta hasta ayer: la racha no se "rompe" hasta que
/// termina el día. No es un cálculo nutricional.
library;

/// Hasta cuántos días atrás se lee (Edge Cases).
const streakLookbackDays = 400;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [mealTimes]: `eaten_at` de las comidas; se agrupan por su fecha local.
int streakDays(Iterable<DateTime> mealTimes, DateTime now) {
  final days = {for (final t in mealTimes) _dateOnly(t)};
  final today = _dateOnly(now);
  // Por fecha de calendario (no restando 24 h): un cambio de hora queda
  // cubierto por construcción. Colombia no tiene horario de verano.
  var day = days.contains(today)
      ? today
      : DateTime(today.year, today.month, today.day - 1);
  var count = 0;
  while (days.contains(day) && count < streakLookbackDays) {
    count++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return count;
}

/// R2: etiqueta semántica de la píldora.
String streakSemantics(int days) =>
    days == 1 ? '1 día seguido registrando' : '$days días seguidos registrando';
