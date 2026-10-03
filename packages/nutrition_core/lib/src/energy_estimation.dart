/// SPEC-008 R2: estimación de las kcal diarias de mantenimiento con las
/// ecuaciones de gasto energético total (TEE) para adultos de 19 años o más.
///
/// Fuente: National Academies of Sciences, Engineering, and Medicine (2023),
/// *Dietary Reference Intakes for Energy*, cap. 5, Tabla 5-5
/// (https://www.nationalacademies.org/read/26818/chapter/7, consultado
/// 2026-10-02). Verificación: `docs/research/2026-10-02-formula-gasto-energetico.md`
/// y OQ9 de SPEC-008 (las 8 ecuaciones reproducen las 40 celdas de las
/// Tablas 7-9 y 7-10 de la misma fuente).
library;

enum BiologicalSex { female, male }

/// Categorías de nivel de actividad física (PAL) de la DRI 2023 (Tabla 5-4).
enum ActivityLevel { inactive, lowActive, active, veryActive }

/// SPEC-008 OQ4: rangos de entrada aceptados para la sugerencia. La edad
/// mínima es 19 porque las ecuaciones de adultos de la fuente son para
/// 19 años o más.
const estimationWeightMinKg = 30.0;
const estimationWeightMaxKg = 300.0;
const estimationHeightMinCm = 120.0;
const estimationHeightMaxCm = 230.0;
const estimationAgeMin = 19;
const estimationAgeMax = 100;

enum EstimationField { weight, height, age }

/// AC4: entrada fuera de rango; nunca se devuelve un número en ese caso.
class InvalidEstimationInput implements Exception {
  final EstimationField field;

  const InvalidEstimationInput(this.field);

  @override
  String toString() => 'InvalidEstimationInput($field)';
}

/// Coeficientes de una ecuación: TEE = intercepto − a·edad + b·estatura + c·peso.
typedef _TeeEquation = ({
  double intercept,
  double age,
  double height,
  double weight,
});

/// DRI 2023, Tabla 5-5, adultos de 19 años o más (edad en años, estatura en
/// cm, peso en kg, resultado en kcal/día).
const Map<BiologicalSex, Map<ActivityLevel, _TeeEquation>> _equations = {
  BiologicalSex.male: {
    ActivityLevel.inactive: (
      intercept: 753.07,
      age: 10.83,
      height: 6.50,
      weight: 14.10,
    ),
    ActivityLevel.lowActive: (
      intercept: 581.47,
      age: 10.83,
      height: 8.30,
      weight: 14.94,
    ),
    ActivityLevel.active: (
      intercept: 1004.82,
      age: 10.83,
      height: 6.52,
      weight: 15.91,
    ),
    ActivityLevel.veryActive: (
      intercept: -517.88,
      age: 10.83,
      height: 15.61,
      weight: 19.11,
    ),
  },
  BiologicalSex.female: {
    ActivityLevel.inactive: (
      intercept: 584.90,
      age: 7.01,
      height: 5.72,
      weight: 11.71,
    ),
    ActivityLevel.lowActive: (
      intercept: 575.77,
      age: 7.01,
      height: 6.60,
      weight: 12.14,
    ),
    ActivityLevel.active: (
      intercept: 710.25,
      age: 7.01,
      height: 6.54,
      weight: 12.34,
    ),
    ActivityLevel.veryActive: (
      intercept: 511.83,
      age: 7.01,
      height: 9.07,
      weight: 12.56,
    ),
  },
};

/// Kcal/día de mantenimiento, sin redondear. Lanza [InvalidEstimationInput]
/// si alguna entrada está fuera de los rangos de OQ4.
double estimateMaintenanceKcal({
  required double weightKg,
  required double heightCm,
  required int ageYears,
  required BiologicalSex sex,
  required ActivityLevel activityLevel,
}) {
  if (weightKg < estimationWeightMinKg || weightKg > estimationWeightMaxKg) {
    throw const InvalidEstimationInput(EstimationField.weight);
  }
  if (heightCm < estimationHeightMinCm || heightCm > estimationHeightMaxCm) {
    throw const InvalidEstimationInput(EstimationField.height);
  }
  if (ageYears < estimationAgeMin || ageYears > estimationAgeMax) {
    throw const InvalidEstimationInput(EstimationField.age);
  }
  final eq = _equations[sex]![activityLevel]!;
  return eq.intercept -
      eq.age * ageYears +
      eq.height * heightCm +
      eq.weight * weightKg;
}
