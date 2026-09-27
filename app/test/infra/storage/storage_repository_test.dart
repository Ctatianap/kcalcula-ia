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
}
