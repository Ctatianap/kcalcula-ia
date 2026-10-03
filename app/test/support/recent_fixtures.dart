import 'package:calorias_ia/infra/storage/storage_repository.dart';

MealItemRecord recentItem(
  String foodId,
  String name,
  double grams, {
  double kcal = 100,
  String confidence = 'buenaEstimacion',
  String basis = 'unitPortion',
}) => MealItemRecord(
  mention: name.toLowerCase(),
  foodId: foodId,
  nameSnapshot: name,
  grams: grams,
  quantityBasis: basis,
  energyKcal: kcal,
  proteinG: 1,
  carbsG: 1,
  fatG: 1,
  confidence: confidence,
  sourceRef: 'fixture',
);

Future<void> recentMeal(
  StorageRepository repo,
  DateTime at,
  List<MealItemRecord> items,
) => repo.registerMeal(
  eatenAt: at,
  mealType: 'almuerzo',
  confidence: 'buenaEstimacion',
  catalogVersion: 'test-1',
  items: items,
);

/// 7 comidas, 2 repetidas: quedan 5 distintas.
Future<void> seedSevenMeals(StorageRepository repo) async {
  final d = DateTime(2026, 9, 27, 8);
  await recentMeal(repo, d, [recentItem('huevo', 'Huevo', 100)]);
  await recentMeal(repo, d.add(const Duration(days: 1)), [
    recentItem('arepa', 'Arepa', 115),
  ]);
  await recentMeal(repo, d.add(const Duration(days: 2)), [
    recentItem('huevo', 'Huevo', 100),
  ]);
  await recentMeal(repo, d.add(const Duration(days: 3)), [
    recentItem('pechuga_de_pollo', 'Pechuga de pollo', 150),
  ]);
  await recentMeal(repo, d.add(const Duration(days: 4)), [
    recentItem('pollo_muslo', 'Muslo de pollo', 120),
  ]);
  await recentMeal(repo, d.add(const Duration(days: 5)), [
    recentItem('huevo', 'Huevo', 50),
    recentItem('arepa', 'Arepa', 70),
  ]);
  await recentMeal(repo, d.add(const Duration(days: 6)), [
    recentItem('arepa', 'Arepa', 115),
  ]);
}
