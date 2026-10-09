/// SPEC-016 R1/R4: periodo de la exportación, por fecha local de la comida.
/// `from`/`to` son fechas (00:00), ambas incluidas; `null` = sin límite.
class ExportRange {
  final DateTime? from;
  final DateTime? to;

  const ExportRange({this.from, this.to});

  const ExportRange.all() : from = null, to = null;

  /// "Últimos 30 días", hoy incluido (como "Mes" en Progreso).
  factory ExportRange.last30Days(DateTime now) => ExportRange(
    from: DateTime(now.year, now.month, now.day - 29),
    to: DateTime(now.year, now.month, now.day),
  );

  bool get isAll => from == null && to == null;

  /// Límites para `mealsBetween` ([inicio, fin)).
  DateTime get start => from ?? DateTime(1970);
  DateTime get endExclusive =>
      to == null ? DateTime(9999) : DateTime(to!.year, to!.month, to!.day + 1);

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && day.isBefore(endExclusive);
  }
}
