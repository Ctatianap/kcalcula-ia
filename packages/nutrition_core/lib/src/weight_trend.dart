/// SPEC-015 R4/R7: cambio de peso de la última semana, sin redondear hasta
/// presentar.
library;

/// Un registro de peso por día (fecha local a las 00:00).
typedef WeightEntry = ({DateTime date, double kg});

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysBetween(DateTime a, DateTime b) =>
    // Fechas de calendario en UTC: sin errores por el cambio de hora.
    DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Hasta cuántos días antes del último registro se busca la referencia.
/// **Decisión de producto** (SPEC-015, Change Log): más atrás ya no es "esta
/// semana", así que no se muestra cambio.
const weightReferenceMaxDays = 14;

/// Último registro, o `null` si no hay ninguno.
WeightEntry? latestWeight(Iterable<WeightEntry> entries) {
  WeightEntry? latest;
  for (final e in entries) {
    if (latest == null || e.date.isAfter(latest.date)) latest = e;
  }
  return latest;
}

/// Último peso menos el del registro más cercano a 7 días antes del último
/// (entre 1 y [weightReferenceMaxDays] días antes; en empate, el más
/// antiguo). `null` si no hay referencia.
double? weeklyWeightChange(Iterable<WeightEntry> entries) {
  final latest = latestWeight(entries);
  if (latest == null) return null;
  WeightEntry? reference;
  int? bestDistance;
  int? bestAge;
  for (final e in entries) {
    final age = _daysBetween(_dateOnly(e.date), _dateOnly(latest.date));
    if (age < 1 || age > weightReferenceMaxDays) continue;
    final distance = (age - 7).abs();
    if (bestDistance == null ||
        distance < bestDistance ||
        (distance == bestDistance && age > bestAge!)) {
      reference = e;
      bestDistance = distance;
      bestAge = age;
    }
  }
  return reference == null ? null : latest.kg - reference.kg;
}
