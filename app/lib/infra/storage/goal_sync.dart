import 'package:nutrition_core/nutrition_core.dart';

import 'storage_repository.dart';

/// SPEC-008 R4: mantenimiento a partir del perfil guardado. Si hay un
/// mantenimiento medido válido, se usa ese aunque los demás datos ya no
/// sirvan para la fórmula (no los necesita). Si no, el de la fórmula, o
/// `null` si los datos ya no son válidos (p. ej. pasó de 100 años). Todo
/// el cálculo vive en `nutrition_core`; aquí solo se traduce el perfil.
double? maintenanceForProfile(UserProfileData profile, DateTime today) {
  final measured = profile.measuredMaintenanceKcal;
  if (measured != null && isValidGoalKcal(measured)) return measured;
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
