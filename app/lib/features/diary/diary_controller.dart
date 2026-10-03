import 'package:nutrition_core/nutrition_core.dart';

import '../../infra/storage/storage_repository.dart';

class DiaryMealSummary {
  final MealWithItems meal;
  final NutrientTotals totals;

  const DiaryMealSummary({required this.meal, required this.totals});
}

/// SPEC-011 R2: un día de la semana actual. `status` y `fraction` salen de
/// `nutrition_core` (regla de estado y `GoalProgress`); aquí no se calcula.
class WeekDaySummary {
  final DateTime date;
  final double kcal;
  final bool hasMeals;
  final bool isToday;
  final bool isFuture;
  final DayStatus? status;
  final double fraction;

  const WeekDaySummary({
    required this.date,
    required this.kcal,
    required this.hasMeals,
    required this.isToday,
    required this.isFuture,
    required this.status,
    required this.fraction,
  });
}

/// Comidas de hoy (por hora), totales del día, meta vigente y la semana.
/// Puramente de lectura: usa la instantánea guardada por ítem.
class DiarySummary {
  final List<DiaryMealSummary> meals;
  final NutrientTotals dayTotals;

  /// SPEC-008 R6/R7: meta vigente, o `null` si el usuario no ha fijado una.
  final NutritionGoal? goal;

  /// SPEC-011 R2: lunes a domingo de la semana actual.
  final List<WeekDaySummary> week;

  const DiarySummary({
    required this.meals,
    required this.dayTotals,
    this.goal,
    this.week = const [],
  });

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

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

Future<DiarySummary> loadDiarySummary(
  StorageRepository storage,
  DateTime now,
) async {
  final today = _dayOf(now);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
  final weekMeals = await storage.mealsBetween(monday, nextMonday);
  final goal = await storage.getNutritionGoal();

  final todays =
      weekMeals
          .where((m) => _dayOf(m.meal.eatenAt) == today)
          .map((m) => DiaryMealSummary(meal: m, totals: _totalsOf(m)))
          .toList()
        ..sort((a, b) => a.meal.meal.eatenAt.compareTo(b.meal.meal.eatenAt));

  final week = <WeekDaySummary>[];
  for (var i = 0; i < 7; i++) {
    final date = DateTime(monday.year, monday.month, monday.day + i);
    final meals = weekMeals.where((m) => _dayOf(m.meal.eatenAt) == date);
    final kcal = sumNutrients(meals.map(_totalsOf)).energyKcal;
    final hasMeals = meals.isNotEmpty;
    week.add(
      WeekDaySummary(
        date: date,
        kcal: kcal,
        hasMeals: hasMeals,
        isToday: date == today,
        isFuture: date.isAfter(today),
        status: hasMeals
            ? dayStatus(consumedKcal: kcal, goalKcal: goal?.energyKcal)
            : null,
        fraction: goal == null
            ? 0
            : GoalProgress(consumed: kcal, goal: goal.energyKcal).fraction,
      ),
    );
  }

  return DiarySummary(
    meals: todays,
    dayTotals: sumNutrients(todays.map((s) => s.totals)),
    goal: goal,
    week: week,
  );
}
