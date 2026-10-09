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

  /// SPEC-022: "la misma comida" (alimentos y gramos), para no repetirla
  /// entre Recientes y Frecuentes.
  final String key;

  /// Confianza de la comida con la regla del 15 % de `nutrition_core`
  /// (la misma que el detalle y Hoy).
  final ConfidenceLevel confidence;

  const RecentMeal({
    required this.draft,
    required this.name,
    required this.kcal,
    required this.confidence,
    this.key = '',
  });
}

String _keyOfMeal(MealWithItems meal) =>
    mealKeyOf(meal.items.map((i) => (foodId: _foodIdOf(i), grams: i.grams)));

/// SPEC-022 R1: comidas frecuentes.
const frequentMealsShown = 5;
const frequentMealsMinTimes = 3;
const frequentMealsWindow = Duration(days: 60);

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
    final key = _keyOfMeal(meal);
    if (!seen.add(key)) continue;
    final recent = _quickMeal(draftFromMeal(meal, resolver), resolver, key);
    if (recent != null) result.add(recent);
  }
  return result;
}

/// La comida lista para repetir, con sus kcal del catálogo actual, o
/// `null` si algún alimento ya no existe.
RecentMeal? _quickMeal(
  MealDraft? draft,
  FoodQueryResolver resolver,
  String key,
) {
  if (draft == null || draft.items.isEmpty) return null;
  final foods = [for (final i in draft.items) resolver.getFoodById(i.foodId)];
  if (foods.any((f) => f == null)) return null;
  final nutrients = [
    for (final (index, item) in draft.items.indexed)
      calculateItemNutrients(foods[index]!, item.grams),
  ];
  return RecentMeal(
    draft: draft,
    name: joinNamesEs([for (final f in foods) f!.nameEs]),
    kcal: sumNutrients(nutrients).energyKcal,
    confidence: mealConfidence([
      for (final (i, n) in nutrients.indexed)
        (energyKcal: n.energyKcal, confidence: draft.items[i].confidence),
    ]),
    key: key,
  );
}

/// SPEC-022 R1/AC1/AC2: hasta [frequentMealsShown] comidas distintas
/// registradas al menos [frequentMealsMinTimes] veces en [newestFirst] (las
/// de los últimos 60 días), de la más repetida a la menos; empate: la más
/// reciente primero. Se omiten las que están en [excludeKeys] (Recientes) y
/// las que tienen un alimento que ya no existe.
List<RecentMeal> buildFrequentMeals(
  List<MealWithItems> newestFirst,
  FoodQueryResolver resolver, {
  Set<String> excludeKeys = const {},
}) {
  final counts = <String, int>{};
  final newestByKey = <String, MealWithItems>{};
  for (final meal in newestFirst) {
    if (meal.items.isEmpty) continue;
    final key = _keyOfMeal(meal);
    counts[key] = (counts[key] ?? 0) + 1;
    newestByKey.putIfAbsent(key, () => meal);
  }
  // `newestByKey` conserva el orden de la más reciente: el sort es estable.
  final keys =
      newestByKey.keys
          .where(
            (k) =>
                counts[k]! >= frequentMealsMinTimes && !excludeKeys.contains(k),
          )
          .toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  final result = <RecentMeal>[];
  for (final key in keys) {
    if (result.length >= frequentMealsShown) break;
    final meal = newestByKey[key]!;
    final frequent = _quickMeal(draftFromMeal(meal, resolver), resolver, key);
    if (frequent != null) result.add(frequent);
  }
  return result;
}

/// SPEC-022 R2/R4: una favorita para "¿Qué comiste?". [meal] es `null` si
/// algún alimento ya no existe (se muestra con un aviso y no se abre).
class FavoriteQuickMeal {
  final int id;
  final String name;
  final RecentMeal? meal;

  const FavoriteQuickMeal({required this.id, required this.name, this.meal});
}

/// SPEC-022 R4: la favorita como borrador (SPEC-017), sin IA.
FavoriteQuickMeal buildFavoriteMeal(
  FavoriteMealWithItems favorite,
  FoodQueryResolver resolver,
) {
  final draft = MealDraft([
    for (final i in favorite.items)
      MealDraftItem(
        foodId: i.foodId,
        mention: i.mention,
        grams: i.grams,
        basis:
            QuantityBasis.values.asNameMap()[i.quantityBasis] ??
            QuantityBasis.explicitWeight,
        confidence:
            ConfidenceLevel.values.asNameMap()[i.confidence] ??
            ConfidenceLevel.estimacion,
        quantityInput: i.quantityInput,
        unitInput: i.unitInput,
        sizeInput: i.sizeInput,
      ),
  ]);
  return FavoriteQuickMeal(
    id: favorite.favorite.id,
    name: favorite.favorite.name,
    meal: _quickMeal(
      draft,
      resolver,
      mealKeyOf(favorite.items.map((i) => (foodId: i.foodId, grams: i.grams))),
    ),
  );
}

/// SPEC-022: lo que muestra "¿Qué comiste?" para repetir sin IA.
typedef QuickMeals = ({
  List<FavoriteQuickMeal> favorites,
  List<RecentMeal> recents,
  List<RecentMeal> frequents,
});

/// SPEC-017/022: favoritas, recientes y frecuentes en una sola lectura.
Future<QuickMeals> loadQuickMeals(
  StorageRepository storage,
  FoodQueryResolver Function(List<PersonalProduct> personalProducts)
  resolverFor, {
  required DateTime now,
}) async {
  final recentRows = await storage.recentMeals(limit: recentMealsScanned);
  final windowRows = await storage.mealsBetween(
    now.subtract(frequentMealsWindow),
    now.add(const Duration(days: 1)),
  );
  final favoriteRows = await storage.favoriteMeals();
  if (recentRows.isEmpty && favoriteRows.isEmpty) {
    return (
      favorites: <FavoriteQuickMeal>[],
      recents: <RecentMeal>[],
      frequents: <RecentMeal>[],
    );
  }
  final resolver = resolverFor(await storage.getAllPersonalProducts());
  final recents = buildRecentMeals(recentRows, resolver);
  return (
    favorites: [for (final f in favoriteRows) buildFavoriteMeal(f, resolver)],
    recents: recents,
    frequents: buildFrequentMeals(
      windowRows.reversed.toList(),
      resolver,
      excludeKeys: {for (final r in recents) r.key},
    ),
  );
}

/// SPEC-022 R2: los alimentos de un borrador para guardarlos como favorita.
List<FavoriteMealItemRecord> favoriteItemsOf(MealDraft draft) => [
  for (final i in draft.items)
    FavoriteMealItemRecord(
      foodId: i.foodId,
      mention: i.mention,
      grams: i.grams,
      quantityInput: i.quantityInput,
      unitInput: i.unitInput,
      sizeInput: i.sizeInput,
      quantityBasis: i.basis.name,
      confidence: i.confidence.name,
    ),
];

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
