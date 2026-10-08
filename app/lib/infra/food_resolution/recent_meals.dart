import 'package:nutrition_core/nutrition_core.dart';

import '../../format/text_es.dart';
import '../storage/storage_repository.dart';
import 'food_query_resolver.dart';
import 'meal_draft.dart';

/// SPEC-017 R1: cuántas comidas distintas se muestran y cuántas se leen.
const recentMealsShown = 5;
const recentMealsScanned = 50;

/// Una comida reciente lista para repetir, con sus kcal recalculadas con el
/// catálogo actual (R2).
class RecentMeal {
  final MealDraft draft;
  final String name;
  final double kcal;

  /// Confianza de la comida con la regla del 15 % de `nutrition_core`
  /// (la misma que el detalle y Hoy).
  final ConfidenceLevel confidence;

  const RecentMeal({
    required this.draft,
    required this.name,
    required this.kcal,
    required this.confidence,
  });
}

String _foodIdOf(MealItem item) => item.personalProductId != null
    ? '$personalProductIdPrefix${item.personalProductId}'
    : item.foodId ?? '';

/// R1/R2/R4: hasta [recentMealsShown] comidas distintas (mismos alimentos con
/// los mismos gramos = la misma), de la más reciente a la más antigua. Se
/// omiten las que tienen un alimento que ya no existe.
List<RecentMeal> buildRecentMeals(
  List<MealWithItems> newestFirst,
  FoodQueryResolver resolver,
) {
  final seen = <String>{};
  final result = <RecentMeal>[];
  for (final meal in newestFirst) {
    if (result.length >= recentMealsShown) break;
    if (meal.items.isEmpty) continue;
    final key =
        (meal.items.map((i) => '${_foodIdOf(i)}@${i.grams}').toList()..sort())
            .join('|');
    if (!seen.add(key)) continue;

    final foods = [
      for (final i in meal.items) resolver.getFoodById(_foodIdOf(i)),
    ];
    if (foods.any((f) => f == null)) continue;

    final items = draftFromMeal(meal, resolver)!.items;
    final nutrients = [
      for (final (index, item) in meal.items.indexed)
        calculateItemNutrients(foods[index]!, item.grams),
    ];
    result.add(
      RecentMeal(
        draft: MealDraft(items),
        name: joinNamesEs([for (final f in foods) f!.nameEs]),
        kcal: sumNutrients(nutrients).energyKcal,
        confidence: mealConfidence([
          for (final (i, n) in nutrients.indexed)
            (energyKcal: n.energyKcal, confidence: items[i].confidence),
        ]),
      ),
    );
  }
  return result;
}

/// Lee las últimas [recentMealsScanned] comidas y arma las recientes.
Future<List<RecentMeal>> loadRecentMeals(
  StorageRepository storage,
  FoodQueryResolver Function(List<PersonalProduct> personalProducts)
  resolverFor,
) async {
  final meals = await storage.recentMeals(limit: recentMealsScanned);
  if (meals.isEmpty) return const [];
  final resolver = resolverFor(await storage.getAllPersonalProducts());
  return buildRecentMeals(meals, resolver);
}

/// SPEC-017 R1 / SPEC-026 R4: la comida guardada como un borrador para
/// repetirla (sin IA), o `null` si alguno de sus alimentos ya no existe.
MealDraft? draftFromMeal(MealWithItems meal, FoodQueryResolver resolver) {
  final items = <MealDraftItem>[];
  for (final item in meal.items) {
    final food = resolver.getFoodById(_foodIdOf(item));
    if (food == null) return null;
    items.add(
      MealDraftItem(
        foodId: food.id,
        mention: item.mention,
        grams: item.grams,
        basis:
            QuantityBasis.values.asNameMap()[item.quantityBasis] ??
            QuantityBasis.explicitWeight,
        confidence:
            ConfidenceLevel.values.asNameMap()[item.confidence] ??
            ConfidenceLevel.estimacion,
        quantityInput: item.quantityInput,
        unitInput: item.unitInput,
        sizeInput: item.sizeInput,
      ),
    );
  }
  return MealDraft(items);
}

/// SPEC-037 R1: borrador para "Repetir hoy" desde Hoy o Historial, o
/// `null` si algún alimento ya no existe.
Future<MealDraft?> loadRepeatDraft(
  StorageRepository storage,
  FoodQueryResolver Function(List<PersonalProduct> personalProducts)
  resolverFor,
  MealWithItems meal,
) async {
  final resolver = resolverFor(await storage.getAllPersonalProducts());
  return draftFromMeal(meal, resolver);
}
