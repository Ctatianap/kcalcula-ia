/// SPEC-008 (v2) R3/R4: metabolismo basal y mantenimiento.
///
/// Fuentes (ver `docs/research/2026-10-02-harris-benedict-actividad-objetivo.md`, PV-14):
/// - Metabolismo basal: Harris JA, Benedict FG. "A Biometric Study of Human
///   Basal Metabolism". PNAS 1918;4(12):370-373, p. 373
///   (https://pmc.ncbi.nlm.nih.gov/articles/PMC1091498/, consultado
///   2026-10-02). Ecuaciones originales, no la revisión de Roza y Shizgal.
/// - Factores de actividad: escala de las calculadoras de fitness (1,2 /
///   1,375 / 1,55 / 1,725 / 1,9), la misma de
///   https://fitgeneration.es/calculadora/harris-benedict/. **No tiene fuente
///   institucional ni académica** (PV-14): es una **decisión de producto** de
///   SPEC-008, aprobada por la usuaria tras compararla con su gasto medido
///   por reloj (los PAL de EFSA 2013, 1,4–2,0, daban valores más altos que
///   su gasto real). Mantenimiento = basal × factor. Si la persona registra
///   su mantenimiento medido, ese manda (R4).
library;

enum BiologicalSex { female, male }

/// SPEC-008 R2: niveles de actividad (incluye NEAT) y su factor. Los
/// nombres se conservan de la versión anterior para no invalidar perfiles
/// guardados; `active` es "Actividad moderada".
enum ActivityLevel {
  sedentary(1.2),
  lightlyActive(1.375),
  active(1.55),
  veryActive(1.725),
  extraActive(1.9);

  const ActivityLevel(this.pal);

  /// Factor por el que se multiplica el metabolismo basal.
  final double pal;
}

/// SPEC-008 R1: rangos de entrada aceptados (validación, no recomendación).
/// La muestra de 1918 tabula 21–70 años; usar la ecuación de 18 a 100 es
/// una decisión de producto, como en cualquier calculadora.
const estimationWeightMinKg = 30.0;
const estimationWeightMaxKg = 300.0;
const estimationHeightMinCm = 120.0;
const estimationHeightMaxCm = 230.0;
const estimationAgeMin = 18;
const estimationAgeMax = 100;

enum EstimationField { weight, height, age }

/// AC3: entrada fuera de rango (incluido NaN o infinito); nunca se devuelve
/// un número en ese caso.
class InvalidEstimationInput implements Exception {
  final EstimationField field;

  const InvalidEstimationInput(this.field);

  @override
  String toString() => 'InvalidEstimationInput($field)';
}

/// Edad en años cumplidos a una fecha dada.
int ageInYears(DateTime birthDate, DateTime on) {
  var age = on.year - birthDate.year;
  final hadBirthday =
      on.month > birthDate.month ||
      (on.month == birthDate.month && on.day >= birthDate.day);
  if (!hadBirthday) age--;
  return age;
}

/// Metabolismo basal en kcal/día, sin redondear (Harris y Benedict 1918).
double estimateBasalKcal({
  required double weightKg,
  required double heightCm,
  required int ageYears,
  required BiologicalSex sex,
}) {
  // `!(x >= min && x <= max)` también rechaza NaN.
  if (!(weightKg >= estimationWeightMinKg &&
      weightKg <= estimationWeightMaxKg)) {
    throw const InvalidEstimationInput(EstimationField.weight);
  }
  if (!(heightCm >= estimationHeightMinCm &&
      heightCm <= estimationHeightMaxCm)) {
    throw const InvalidEstimationInput(EstimationField.height);
  }
  if (ageYears < estimationAgeMin || ageYears > estimationAgeMax) {
    throw const InvalidEstimationInput(EstimationField.age);
  }
  return switch (sex) {
    BiologicalSex.male =>
      66.4730 + 13.7516 * weightKg + 5.0033 * heightCm - 6.7550 * ageYears,
    BiologicalSex.female =>
      655.0955 + 9.5634 * weightKg + 1.8496 * heightCm - 4.6756 * ageYears,
  };
}

/// Mantenimiento estimado en kcal/día, sin redondear: basal × factor.
double estimateMaintenanceKcal({
  required double weightKg,
  required double heightCm,
  required int ageYears,
  required BiologicalSex sex,
  required ActivityLevel activityLevel,
}) =>
    estimateBasalKcal(
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      sex: sex,
    ) *
    activityLevel.pal;
