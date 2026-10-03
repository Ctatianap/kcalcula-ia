import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_repository.dart';

/// SPEC-008 R4: mantenimiento a partir del perfil guardado, o `null` si los
/// datos ya no son válidos (p. ej. pasó de 100 años). Todo el cálculo vive
/// en `nutrition_core`; aquí solo se traduce el perfil guardado.
double? maintenanceForProfile(UserProfileData profile, DateTime today) {
  final sex = BiologicalSex.values.asNameMap()[profile.sex];
  final level = ActivityLevel.values.asNameMap()[profile.activityLevel];
  if (sex == null || level == null) return null;
  try {
    return estimateMaintenanceKcal(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      ageYears: ageInYears(profile.birthDate, today),
      sex: sex,
      activityLevel: level,
    );
  } on InvalidEstimationInput {
    return null;
  }
}

/// SPEC-008 R8/R10: meta lista para guardar (kcal y gramos sin redondear).
NutritionGoalValues goalValuesFor({
  required double kcal,
  required GoalObjective objective,
  required bool isManual,
}) {
  final grams = macroGramsFor(kcal, objective);
  return (
    objective: objective.name,
    isManual: isManual,
    energyKcal: kcal,
    proteinG: grams.proteinG,
    carbsG: grams.carbsG,
    fatG: grams.fatG,
  );
}

/// SPEC-008 R9: con el perfil nuevo, la meta que viene de un objetivo (no
/// manual) se recalcula; `null` si no hay que tocarla o si queda fuera de
/// 800–6.000 kcal (se conserva la anterior).
NutritionGoalValues? recalculatedGoal(
  NutritionGoal? current,
  double? newMaintenance,
) {
  if (current == null || current.isManual || newMaintenance == null) {
    return null;
  }
  final objective = GoalObjective.values.asNameMap()[current.objective];
  if (objective == null) return null;
  final kcal = objectiveKcal(newMaintenance, objective);
  if (!isValidGoalKcal(kcal)) return null;
  return goalValuesFor(kcal: kcal, objective: objective, isManual: false);
}

const disclaimerText =
    'Son estimaciones generales, no una recomendación médica. Si tienes una '
    'condición de salud, consulta a un profesional.';

/// SPEC-008 R2: textos de los niveles de actividad (incluye el NEAT).
const activityLevelTexts = {
  ActivityLevel.sedentary: (
    'Poca actividad',
    'Poco o nada de ejercicio, trabajo sentado.',
  ),
  ActivityLevel.lightlyActive: (
    'Actividad ligera',
    'Ejercicio 1–3 días por semana, o mucho movimiento en el día.',
  ),
  ActivityLevel.active: (
    'Actividad moderada',
    'Ejercicio 3–5 días por semana.',
  ),
  ActivityLevel.veryActive: (
    'Actividad alta',
    'Ejercicio 6–7 días por semana, o trabajo físico.',
  ),
};

/// SPEC-008 R6: textos de los objetivos.
const objectiveTexts = {
  GoalObjective.loseFatGentle: (
    'Bajar grasa (suave)',
    'Mantenimiento − 250 kcal',
  ),
  GoalObjective.loseFat: ('Bajar grasa', 'Mantenimiento − 500 kcal'),
  GoalObjective.maintain: ('Mantener', 'Tu mantenimiento'),
  GoalObjective.gainMuscleGentle: (
    'Subir masa muscular (suave)',
    'Mantenimiento + 10 %',
  ),
  GoalObjective.gainMuscle: ('Subir masa muscular', 'Mantenimiento + 20 %'),
};

/// "~2.276 kcal".
String approxKcal(double kcal) =>
    '~${formatThousandsEs(presentKcal(kcal))} kcal';

/// Gramos enteros para un resumen: "Proteína 114 g · Grasa 63 g · ...".
String macroSummary(MacroGrams m) =>
    'Proteína ${m.proteinG.round()} g · '
    'Grasa ${m.fatG.round()} g · '
    'Carbohidratos ${m.carbsG.round()} g';
