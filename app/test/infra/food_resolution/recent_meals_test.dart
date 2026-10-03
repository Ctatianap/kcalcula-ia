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
}
