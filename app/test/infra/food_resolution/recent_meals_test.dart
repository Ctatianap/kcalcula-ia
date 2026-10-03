import 'package:calorias_ia/infra/food_resolution/food_query_resolver.dart';
import 'package:calorias_ia/infra/food_resolution/recent_meals.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../support/fixture_catalog.dart';
import '../../support/recent_fixtures.dart';

void main() {
  late AppDatabase db;
  late StorageRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StorageRepository(db);
  });
  tearDown(() => db.close());

  Future<List<RecentMeal>> load({double eggKcal = 143}) {
    final catalog = buildFixtureCatalog(eggKcal: eggKcal);
    addTearDown(catalog.close);
    return loadRecentMeals(
      repo,
      (products) =>
          FoodQueryResolver(catalog: catalog, personalProducts: products),
    );
  }

  test('AC1/R1: 7 comidas (2 repetidas) → 5 distintas, de la más reciente a '
      'la más antigua', () async {
    await seedSevenMeals(repo);
    final recents = await load();
    expect(recents.map((r) => r.name), [
      'Arepa',
      'Huevo y Arepa',
      'Muslo de pollo',
      'Pechuga de pollo',
      'Huevo',
    ]);
    expect(recents[1].draft.items.map((i) => (i.foodId, i.grams)), [
      ('huevo', 50.0),
      ('arepa', 70.0),
    ]);
  });

  test(
    'AC3: las kcal salen del catálogo actual, no de la instantánea',
    () async {
      // Guardada con 999 kcal de instantánea; el catálogo dice 143 / 100 g.
      await recentMeal(repo, DateTime(2026, 10, 1, 8), [
        recentItem('huevo', 'Huevo', 100, kcal: 999),
      ]);
      expect((await load()).single.kcal, closeTo(143, 1e-9));
      // Si el catálogo cambia el valor del huevo, cambia la tarjeta.
      expect((await load(eggKcal: 155)).single.kcal, closeTo(155, 1e-9));
    },
  );

  test('AC4: una comida con un alimento que ya no está en el catálogo no '
      'aparece', () async {
    await recentMeal(repo, DateTime(2026, 10, 1, 8), [
      recentItem('huevo', 'Huevo', 100),
    ]);
    await recentMeal(repo, DateTime(2026, 10, 2, 8), [
      recentItem('huevo', 'Huevo', 100),
      recentItem('chontaduro', 'Chontaduro', 80),
    ]);
    final recents = await load();
    expect(recents.map((r) => r.name), ['Huevo']);
  });

  test(
    'R4: un producto personal borrado saca la comida de Recientes',
    () async {
      final id = await repo.savePersonalProduct(
        nameEs: 'Yogur de prueba',
        energyKcal100: 60,
        proteinG100: 3,
        carbsG100: 8,
        fatG100: 2,
        servingGrams: 150,
        sourceRef: 'etiqueta confirmada',
      );
      await repo.registerMeal(
        eatenAt: DateTime(2026, 10, 2, 10),
        mealType: 'snack',
        confidence: 'altaPrecision',
        catalogVersion: 'test-1',
        items: [
          MealItemRecord(
            mention: 'yogur',
            personalProductId: id,
            nameSnapshot: 'Yogur de prueba',
            grams: 150,
            quantityBasis: 'label',
            energyKcal: 90,
            proteinG: 4.5,
            carbsG: 12,
            fatG: 3,
            confidence: 'altaPrecision',
            sourceRef: 'etiqueta confirmada',
          ),
        ],
      );
      final recents = await load();
      expect(recents.single.name, 'Yogur de prueba');
      expect(recents.single.kcal, closeTo(90, 1e-9));
      expect(
        recents.single.draft.items.single.confidence,
        ConfidenceLevel.altaPrecision,
      );

      await db.customStatement('DELETE FROM personal_products');
      expect(await load(), isEmpty);
    },
  );

  test('R5: sin comidas previas, no hay recientes', () async {
    expect(await load(), isEmpty);
  });

  test(
    'R1: con 8 comidas distintas solo se muestran las 5 más recientes',
    () async {
      for (var i = 0; i < 8; i++) {
        await recentMeal(repo, DateTime(2026, 9, 20 + i, 8), [
          recentItem('huevo', 'Huevo', 10.0 + i),
        ]);
      }
      final recents = await load();
      expect(recents, hasLength(5));
      expect(recents.map((r) => r.draft.items.single.grams), [
        17,
        16,
        15,
        14,
        13,
      ]);
    },
  );

  test('edge case: la consulta lee solo las últimas 50 comidas', () async {
    for (var i = 0; i < 52; i++) {
      await recentMeal(repo, DateTime(2026, 8, 1).add(Duration(hours: i)), [
        recentItem('huevo', 'Huevo', 100),
      ]);
    }
    final meals = await repo.recentMeals(limit: recentMealsScanned);
    expect(meals, hasLength(50));
    expect(
      meals.first.meal.eatenAt,
      DateTime(2026, 8, 1).add(const Duration(hours: 51)),
    );
  });

  test('la confianza de la tarjeta usa la regla del 15 % y la cantidad '
      'original se conserva', () async {
    await recentMeal(repo, DateTime(2026, 10, 1, 8), [
      MealItemRecord(
        mention: 'dos huevos',
        foodId: 'huevo',
        nameSnapshot: 'Huevo',
        grams: 100,
        quantityInput: 2,
        unitInput: 'unidad',
        quantityBasis: 'unitPortion',
        energyKcal: 143,
        proteinG: 1,
        carbsG: 1,
        fatG: 1,
        confidence: 'altaPrecision',
        sourceRef: 'fixture',
      ),
      // Menos del 15 % de las kcal: no baja la confianza de la comida.
      recentItem('arepa', 'Arepa', 5, confidence: 'estimacion'),
    ]);
    final recent = (await load()).single;
    expect(recent.confidence, ConfidenceLevel.altaPrecision);
    final item = recent.draft.items.first;
    expect((item.quantityInput, item.unitInput), (2.0, 'unidad'));
  });
}
