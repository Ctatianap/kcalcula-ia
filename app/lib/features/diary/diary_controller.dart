import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_repository.dart';

const _mealTypeOrder = ['desayuno', 'almuerzo', 'cena', 'snack'];

class DiaryMealSummary {
  final MealWithItems meal;
  final NutrientTotals totals;

  const DiaryMealSummary({required this.meal, required this.totals});
}

/// R12: comidas de hoy agrupadas por tipo, con kcal por comida y totales
/// del día. Puramente de lectura: no recalcula nutrientes (usa la
/// instantánea ya guardada por ítem).
class DiarySummary {
  final List<DiaryMealSummary> meals;
  final NutrientTotals dayTotals;

  /// SPEC-008 R6/R7: meta vigente, o `null` si el usuario no ha fijado una.
  final NutritionGoal? goal;

  const DiarySummary({required this.meals, required this.dayTotals, this.goal});

  /// SPEC-008 R6/AC12: el consumido lleva "~" si alguna comida del día no
  /// es "Alta precisión".
  bool get isApproximate => meals.any(
    (m) => m.meal.meal.confidence != ConfidenceLevel.altaPrecision.name,
  );
}

NutrientTotals _totalsOf(MealWithItems meal) => sumNutrients(
  meal.items.map(
    (item) => (
      energyKcal: item.energyKcal,
      proteinG: item.proteinG,
      carbsG: item.carbsG,
      fatG: item.fatG,
    ),
  ),
);

Future<DiarySummary> loadDiarySummary(
  StorageRepository storage,
  DateTime day,
) async {
  final meals = await storage.mealsForDay(day);
  final summaries =
      meals.map((m) => DiaryMealSummary(meal: m, totals: _totalsOf(m))).toList()
        ..sort((a, b) {
          final aIndex = _mealTypeOrder.indexOf(
            a.meal.meal.mealType ?? 'snack',
          );
          final bIndex = _mealTypeOrder.indexOf(
            b.meal.meal.mealType ?? 'snack',
          );
          return aIndex.compareTo(bIndex);
        });
  final dayTotals = sumNutrients(summaries.map((s) => s.totals));
  final goal = await storage.getNutritionGoal();
  return DiarySummary(meals: summaries, dayTotals: dayTotals, goal: goal);
}
