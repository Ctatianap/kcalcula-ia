import 'dart:io';

import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

MealItemRecord _egg() => const MealItemRecord(
  mention: 'dos huevos',
  foodId: 'huevo',
  nameSnapshot: 'Huevo',
  grams: 100,
  quantityInput: 2,
  unitInput: 'unidad',
  quantityBasis: 'unitPortion',
  energyKcal: 143,
  proteinG: 12.6,
  carbsG: 0.7,
  fatG: 9.5,
  confidence: 'buenaEstimacion',
  sourceRef: 'fixture de prueba',
);

void main() {
  test(
    'AC9: la comida registrada persiste tras cerrar y reabrir la base de datos',
    () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
      final dbPath = '${dir.path}/user_test.db';
      addTearDown(() => dir.deleteSync(recursive: true));

      final eatenAt = DateTime(2026, 9, 27, 8);

      // Sesión 1: registrar y "cerrar la app".
      final db1 = AppDatabase(AppDatabase.openFile(dbPath));
      final repo1 = StorageRepository(db1);
      await repo1.registerMeal(
        eatenAt: eatenAt,
        mealType: 'desayuno',
        confidence: 'buenaEstimacion',
        catalogVersion: 'test-1',
        items: [_egg()],
      );
      await db1.close();

      // Sesión 2: "reabrir la app" desde el mismo archivo, no en memoria.
      final db2 = AppDatabase(AppDatabase.openFile(dbPath));
      final repo2 = StorageRepository(db2);
      final meals = await repo2.mealsForDay(eatenAt);
      await db2.close();

      expect(meals, hasLength(1));
      expect(meals.first.meal.mealType, 'desayuno');
      expect(meals.first.items, hasLength(1));
      expect(meals.first.items.first.energyKcal, 143);
    },
  );

  test('mealsForDay no incluye comidas de otros días', () async {
    final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
    final dbPath = '${dir.path}/user_test.db';
    addTearDown(() => dir.deleteSync(recursive: true));

    final db = AppDatabase(AppDatabase.openFile(dbPath));
    final repo = StorageRepository(db);

    await repo.registerMeal(
      eatenAt: DateTime(2026, 9, 27, 8),
      mealType: 'desayuno',
      confidence: 'buenaEstimacion',
      catalogVersion: 'test-1',
      items: [_egg()],
    );
    await repo.registerMeal(
      eatenAt: DateTime(2026, 9, 28, 8),
      mealType: 'desayuno',
      confidence: 'buenaEstimacion',
      catalogVersion: 'test-1',
      items: [_egg()],
    );

    final day1 = await repo.mealsForDay(DateTime(2026, 9, 27));
    expect(day1, hasLength(1));

    await db.close();
  });

  group('SPEC-004: personal_products', () {
    test('savePersonalProduct + getAllPersonalProducts persiste', () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final db = AppDatabase(AppDatabase.openFile('${dir.path}/user_test.db'));
      final repo = StorageRepository(db);

      final id = await repo.savePersonalProduct(
        nameEs: 'Producto de prueba',
        energyKcal100: 466.7,
        proteinG100: 6.7,
        carbsG100: 66.7,
        fatG100: 20,
        servingGrams: 30,
        sourceRef: 'fixture de prueba',
      );

      final all = await repo.getAllPersonalProducts();
      expect(all, hasLength(1));
      expect(all.first.id, id);
      expect(all.first.nameEs, 'Producto de prueba');
      expect(all.first.energyKcal100, closeTo(466.7, 1e-9));
      expect(all.first.fiberG100, isNull);

      await db.close();
    });

    test('registerMeal con personalProductId no escribe foodId (uno u otro, nunca ambos)', () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final db = AppDatabase(AppDatabase.openFile('${dir.path}/user_test.db'));
      final repo = StorageRepository(db);

      final productId = await repo.savePersonalProduct(
        nameEs: 'Producto de prueba',
        energyKcal100: 466.7,
        proteinG100: 6.7,
        carbsG100: 66.7,
        fatG100: 20,
        servingGrams: 30,
        sourceRef: 'fixture de prueba',
      );

      await repo.registerMeal(
        eatenAt: DateTime(2026, 9, 27, 8),
        mealType: 'snack',
        confidence: 'altaPrecision',
        catalogVersion: 'test-1',
        items: [
          MealItemRecord(
            mention: 'Producto de prueba',
            personalProductId: productId,
            nameSnapshot: 'Producto de prueba',
            grams: 45,
            quantityInput: 45,
            unitInput: 'g',
            quantityBasis: 'label',
            energyKcal: 210,
            proteinG: 3,
            carbsG: 30,
            fatG: 9,
            confidence: 'altaPrecision',
            sourceRef: 'fixture de prueba',
          ),
        ],
      );

      final meals = await repo.mealsForDay(DateTime(2026, 9, 27, 8));
      expect(meals.first.items.first.foodId, isNull);
      expect(meals.first.items.first.personalProductId, productId.toString());

      await db.close();
    });
  });
}
