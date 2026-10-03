/// SPEC-011 R3: estado de un día frente a la meta de kcal.
///
/// "En tu meta" es del 90 % al 110 % de la meta, ambos incluidos. **La
/// tolerancia del 10 % es una decisión de producto** de SPEC-011 (aprobada
/// por la usuaria), no una recomendación nutricional.
library;

enum DayStatus { belowGoal, onGoal, aboveGoal }

const dayStatusTolerance = 0.10;

/// `null` si no hay meta (o no es positiva).
DayStatus? dayStatus({required double consumedKcal, double? goalKcal}) {
  if (goalKcal == null || goalKcal <= 0) return null;
  final ratio = consumedKcal / goalKcal;
  if (ratio < 1 - dayStatusTolerance) return DayStatus.belowGoal;
  if (ratio > 1 + dayStatusTolerance) return DayStatus.aboveGoal;
  return DayStatus.onGoal;
}
