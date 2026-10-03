import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_repository.dart';

const historyMealTypes = ['desayuno', 'almuerzo', 'cena', 'snack'];

/// Un día del mes con registros. Totales y estado salen de `nutrition_core`
/// (invariante 3); aquí solo se agrupan las instantáneas guardadas.
class HistoryDay {
  final DateTime date;
  final List<MealWithItems> meals;
  final NutrientTotals totals;

  /// `null` sin meta (R4).
  final DayStatus? status;

  /// Totales por tipo de comida, con las cuatro claves de
  /// [historyMealTypes].
  final Map<String, NutrientTotals> byMealType;

  const HistoryDay({
    required this.date,
    required this.meals,
    required this.totals,
    required this.status,
    required this.byMealType,
  });

  /// SPEC-008 R6: "~" si alguna comida no es "Alta precisión".
  bool get isApproximate =>
      meals.any((m) => m.meal.confidence != ConfidenceLevel.altaPrecision.name);
}

class HistoryMonth {
  /// Día 1 del mes mostrado.
  final DateTime month;

  /// Meta vigente (SPEC-008: sin historial de metas).
  final NutritionGoal? goal;

  /// Solo los días con registros, por número de día.
  final Map<int, HistoryDay> days;

  const HistoryMonth({
    required this.month,
    required this.goal,
    required this.days,
  });
}

NutrientTotals mealTotals(MealWithItems meal) => sumNutrients(
  meal.items.map(
    (item) => (
      energyKcal: item.energyKcal,
      proteinG: item.proteinG,
      carbsG: item.carbsG,
      fatG: item.fatG,
    ),
  ),
);

/// R5: lee solo el mes pedido con `mealsBetween`.
Future<HistoryMonth> loadHistoryMonth(
  StorageRepository storage,
  DateTime month,
) async {
  final first = DateTime(month.year, month.month);
  final next = DateTime(month.year, month.month + 1);
  final meals = await storage.mealsBetween(first, next);
  final goal = await storage.getNutritionGoal();

  final byDay = <int, List<MealWithItems>>{};
  for (final meal in meals) {
    byDay.putIfAbsent(meal.meal.eatenAt.day, () => []).add(meal);
  }
  final days = <int, HistoryDay>{};
  for (final MapEntry(key: day, value: dayMeals) in byDay.entries) {
    dayMeals.sort((a, b) => a.meal.eatenAt.compareTo(b.meal.eatenAt));
    final totals = sumNutrients(dayMeals.map(mealTotals));
    days[day] = HistoryDay(
      date: DateTime(first.year, first.month, day),
      meals: dayMeals,
      totals: totals,
      status: dayStatus(
        consumedKcal: totals.energyKcal,
        goalKcal: goal?.energyKcal,
      ),
      byMealType: {
        for (final type in historyMealTypes)
          type: sumNutrients(
            dayMeals.where((m) => m.meal.mealType == type).map(mealTotals),
          ),
      },
    );
  }
  return HistoryMonth(month: first, goal: goal, days: days);
}
