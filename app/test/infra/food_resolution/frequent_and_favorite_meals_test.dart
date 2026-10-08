import 'dart:io';

import 'package:calorias_ia/infra/food_resolution/food_query_resolver.dart';
import 'package:calorias_ia/infra/food_resolution/meal_draft.dart';
import 'package:calorias_ia/infra/food_resolution/recent_meals.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../support/fixture_catalog.dart';
import '../../support/recent_fixtures.dart';

final _now = DateTime(2026, 10, 8, 12);

/// SPEC-022 AC1: huevo 100 g × 4, arepa 115 g × 3 y pollo × 2, más antiguas
/// que 5 comidas distintas recientes (que ocupan Recientes).
Future<void> seedFrequent(StorageRepository repo) async {
  final start = DateTime(2026, 9, 10, 8);
  var day = 0;
  Future<void> at(List<MealItemRecord> items) =>
      recentMeal(repo, start.add(Duration(days: day++)), items);
  for (var i = 0; i < 4; i++) {
    await at([recentItem('huevo', 'Huevo', 100)]);
  }
  for (var i = 0; i < 3; i++) {
    await at([recentItem('arepa', 'Arepa', 115)]);
  }
  for (var i = 0; i < 2; i++) {
    await at([recentItem('pechuga_de_pollo', 'Pechuga de pollo', 150)]);
  }
  // 5 comidas distintas más recientes: Recientes.
  await at([recentItem('cafe', 'Café', 200)]);
  await at([recentItem('papa_cocida', 'Papa cocida', 100)]);
  await at([recentItem('name_cocido', 'Ñame cocido', 100)]);
  await at([recentItem('ahuyama_cocida', 'Ahuyama cocida', 100)]);
  await at([recentItem('pollo_muslo', 'Muslo de pollo', 120)]);
}

FavoriteMealItemRecord _favItem(String foodId, double grams) =>
    FavoriteMealItemRecord(
      foodId: foodId,
      mention: foodId,
      grams: grams,
      quantityBasis: 'explicitWeight',
      confidence: 'altaPrecision',
    );

void main() {
  late AppDatabase db;
  late StorageRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StorageRepository(db);
  });
  tearDown(() => db.close());

  Future<QuickMeals> load() {
    final catalog = buildFixtureCatalog();
    addTearDown(catalog.close);
    return loadQuickMeals(
      repo,
      (products) =>
          FoodQueryResolver(catalog: catalog, personalProducts: products),
      now: _now,
    );
  }

  group('SPEC-022 Frecuentes', () {
    test(
      'AC1: 4 y 3 veces en 60 días salen, en ese orden; 2 veces no',
      () async {
        await seedFrequent(repo);
        final quick = await load();
        expect(quick.frequents.map((f) => f.name), ['Huevo', 'Arepa']);
        expect(quick.frequents.first.draft.items.single.grams, 100);
      },
    );

    test(
      'AC2: una comida que está en Recientes no sale en Frecuentes',
      () async {
        await seedFrequent(repo);
        // Huevo 100 g vuelve a ser la más reciente.
        await recentMeal(repo, DateTime(2026, 10, 7, 8), [
          recentItem('huevo', 'Huevo', 100),
        ]);
        final quick = await load();
        expect(quick.recents.first.name, 'Huevo');
        expect(quick.frequents.map((f) => f.name), ['Arepa']);
      },
    );

    test('R1: fuera de los 60 días no cuenta', () async {
      for (var i = 0; i < 3; i++) {
        await recentMeal(repo, DateTime(2026, 7, 1 + i, 8), [
          recentItem('huevo', 'Huevo', 100),
        ]);
      }
      expect((await load()).frequents, isEmpty);
    });

    test('R1: empate en veces → la más reciente primero', () {
      MealWithItems meal(int id, String foodId, DateTime at) => MealWithItems(
        meal: Meal(
          id: id,
          eatenAt: at,
          mealType: 'almuerzo',
          confidence: 'buenaEstimacion',
          catalogVersion: 't',
          createdAt: at,
          updatedAt: at,
        ),
        items: [
          MealItem(
            id: id,
            mealId: id,
            position: 0,
            mention: foodId,
            foodId: foodId,
            nameSnapshot: foodId,
            grams: 100,
            quantityBasis: 'explicitWeight',
            energyKcal: 1,
            proteinG: 0,
            carbsG: 0,
            fatG: 0,
            confidence: 'altaPrecision',
            sourceRef: 'f',
          ),
        ],
      );
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      final resolver = FoodQueryResolver(
        catalog: catalog,
        personalProducts: const [],
      );
      // Más reciente primero: arepa (3) es la más nueva; huevo (3) más vieja.
      final newestFirst = [
        for (var i = 0; i < 3; i++) meal(i, 'arepa', DateTime(2026, 10, 7 - i)),
        for (var i = 0; i < 3; i++)
          meal(10 + i, 'huevo', DateTime(2026, 10, 1 - i)),
      ];
      expect(buildFrequentMeals(newestFirst, resolver).map((f) => f.name), [
        'Arepa',
        'Huevo',
      ]);
    });
  });

  group('SPEC-022 Favoritas', () {
    test('AC3 (almacenamiento): guardar, duplicada, límite y quitar', () async {
      expect(
        await repo.saveFavoriteMeal(
          name: 'Desayuno de siempre',
          items: [_favItem('huevo', 100), _favItem('arepa', 115)],
        ),
        SaveFavoriteResult.saved,
      );
      // Mismos alimentos y gramos en otro orden: duplicada.
      expect(
        await repo.saveFavoriteMeal(
          name: 'Otra',
          items: [_favItem('arepa', 115), _favItem('huevo', 100)],
        ),
        SaveFavoriteResult.duplicate,
      );
      for (var i = 1; i < maxFavoriteMeals; i++) {
        expect(
          await repo.saveFavoriteMeal(
            name: 'F$i',
            items: [_favItem('cafe', i * 10)],
          ),
          SaveFavoriteResult.saved,
        );
      }
      expect(
        await repo.saveFavoriteMeal(name: 'Once', items: [_favItem('cafe', 1)]),
        SaveFavoriteResult.limitReached,
      );
      final favorites = await repo.favoriteMeals();
      expect(favorites, hasLength(maxFavoriteMeals));
      final breakfast = favorites.singleWhere(
        (f) => f.favorite.name == 'Desayuno de siempre',
      );
      expect(breakfast.items.map((i) => (i.foodId, i.grams)), [
        ('huevo', 100.0),
        ('arepa', 115.0),
      ]);

      await repo.deleteFavoriteMeal(breakfast.favorite.id);
      expect(await repo.favoriteMeals(), hasLength(maxFavoriteMeals - 1));
    });

    test(
      'Edge: el nombre se recorta a 40 caracteres; vacío no se guarda',
      () async {
        await repo.saveFavoriteMeal(
          name: '  ${'a' * 45}  ',
          items: [_favItem('huevo', 100)],
        );
        expect((await repo.favoriteMeals()).single.favorite.name, 'a' * 40);
        expect(
          () =>
              repo.saveFavoriteMeal(name: '   ', items: [_favItem('arepa', 1)]),
          throwsArgumentError,
        );
        expect(
          () => repo.saveFavoriteMeal(name: 'Sin alimentos', items: const []),
          throwsArgumentError,
        );
      },
    );

    test('R4: la favorita se abre con el catálogo actual, sin IA', () async {
      await repo.saveFavoriteMeal(
        name: 'Desayuno de siempre',
        items: [_favItem('huevo', 100)],
      );
      final favorite = (await load()).favorites.single;
      expect(favorite.name, 'Desayuno de siempre');
      // Huevo 143 kcal/100 g en el catálogo de prueba.
      expect(favorite.meal!.kcal, closeTo(143, 1e-9));
      expect(favorite.meal!.draft.items.single.foodId, 'huevo');
      expect(
        favorite.meal!.draft.items.single.confidence,
        ConfidenceLevel.altaPrecision,
      );
    });

    test(
      'AC6 (lógica): con un alimento que ya no existe, no se puede abrir',
      () async {
        await repo.saveFavoriteMeal(
          name: 'Con chontaduro',
          items: [_favItem('huevo', 100), _favItem('chontaduro', 80)],
        );
        final favorite = (await load()).favorites.single;
        expect(favorite.name, 'Con chontaduro');
        expect(favorite.meal, isNull);
      },
    );

    test('R2: un producto personal puede estar en una favorita', () async {
      final id = await repo.savePersonalProduct(
        nameEs: 'Yogur de prueba',
        energyKcal100: 60,
        proteinG100: 3,
        carbsG100: 8,
        fatG100: 2,
        servingGrams: 150,
        sourceRef: 'test',
      );
      final draft = MealDraft([
        MealDraftItem(
          foodId: '$personalProductIdPrefix$id',
          mention: 'yogur',
          grams: 150,
          basis: QuantityBasis.label,
          confidence: ConfidenceLevel.altaPrecision,
        ),
      ]);
      await repo.saveFavoriteMeal(name: 'Yogur', items: favoriteItemsOf(draft));
      final favorite = (await load()).favorites.single;
      expect(favorite.meal!.kcal, closeTo(90, 1e-9));
      // Borrar el producto deja la favorita sin poder abrirse.
      await repo.deletePersonalProduct(id);
      expect((await load()).favorites.single.meal, isNull);
    });

    test('AC7 (lógica): sin comidas ni favoritas, todo vacío', () async {
      final quick = await load();
      expect(quick.favorites, isEmpty);
      expect(quick.recents, isEmpty);
      expect(quick.frequents, isEmpty);
    });
  });

  test('AC5: migrar desde la v8 conserva todo y crea favoritas vacías; borrar '
      'todo las vacía; exportar las incluye', () async {
    final dir = await Directory.systemTemp.createTemp('spec022');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/user.db';

    final v8 = AppDatabase(AppDatabase.openFile(path));
    await recentMeal(StorageRepository(v8), DateTime(2026, 10, 1, 8), [
      recentItem('huevo', 'Huevo', 100),
    ]);
    // Simula un user.db de la v8: sin las tablas de favoritas.
    await v8.customStatement('DROP TABLE favorite_meal_items');
    await v8.customStatement('DROP TABLE favorite_meals');
    await v8.customStatement('PRAGMA user_version = 8');
    await v8.close();

    final v9 = AppDatabase(AppDatabase.openFile(path));
    addTearDown(v9.close);
    final migrated = StorageRepository(v9);
    expect(
      await migrated.mealsBetween(DateTime(2000), DateTime(2100)),
      hasLength(1),
    );
    expect(await migrated.favoriteMeals(), isEmpty);

    await migrated.saveFavoriteMeal(
      name: 'Desayuno de siempre',
      items: [_favItem('huevo', 100)],
    );
    final exported = await migrated.exportUserData();
    final favorite = (exported['favoriteMeals']! as List).single as Map;
    expect(favorite['name'], 'Desayuno de siempre');
    expect((favorite['items'] as List).single, {
      'foodId': 'huevo',
      'mention': 'huevo',
      'grams': 100.0,
      'quantityInput': null,
      'unitInput': null,
      'sizeInput': null,
      'quantityBasis': 'explicitWeight',
      'confidence': 'altaPrecision',
    });

    await migrated.deleteAllUserData();
    expect(await migrated.favoriteMeals(), isEmpty);
    expect(await v9.select(v9.favoriteMealItems).get(), isEmpty);
  });
}
