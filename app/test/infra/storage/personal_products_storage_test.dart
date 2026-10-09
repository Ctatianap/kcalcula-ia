import 'dart:io';

import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _saveBread(StorageRepository repo) => repo.savePersonalProduct(
  nameEs: 'Pan',
  energyKcal100: 260,
  proteinG100: 9,
  carbsG100: 48,
  fatG100: 3,
  servingGrams: 27,
  sourceRef: 'test',
);

Future<void> _registerWith(StorageRepository repo, int productId) =>
    repo.registerMeal(
      eatenAt: DateTime(2026, 10, 7, 8),
      mealType: 'breakfast',
      confidence: 'altaPrecision',
      catalogVersion: 'test',
      items: [
        MealItemRecord(
          mention: 'pan',
          personalProductId: productId,
          nameSnapshot: 'Pan',
          grams: 27,
          quantityBasis: 'label',
          energyKcal: 70,
          proteinG: 2.4,
          carbsG: 13,
          fatG: 0.8,
          confidence: 'altaPrecision',
          sourceRef: 'test',
        ),
      ],
    );

void main() {
  test('SPEC-034 AC1/AC6 (integración): renombrar o borrar un producto no cambia la comida registrada', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    final id = await _saveBread(repo);
    await _registerWith(repo, id);

    await repo.updatePersonalProduct(
      id: id,
      nameEs: 'Pan tajado integral',
      servingUnit: 'g',
      aliases: ['mi pan'],
    );
    expect(
      (await repo.getPersonalProductById(id))!.nameEs,
      'Pan tajado integral',
    );
    var meals = await repo.mealsForDay(DateTime(2026, 10, 7));
    expect(meals.single.items.single.nameSnapshot, 'Pan');

    await repo.deletePersonalProduct(id);
    expect(await repo.getAllPersonalProducts(), isEmpty);
    expect(await repo.getPersonalProductAliases(), isEmpty);
    meals = await repo.mealsForDay(DateTime(2026, 10, 7));
    expect(meals.single.items.single.nameSnapshot, 'Pan');
    expect(meals.single.items.single.energyKcal, 70);
  });

  test('SPEC-034 R2: actualizar reemplaza los alias', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    final id = await _saveBread(repo);
    await repo.updatePersonalProduct(
      id: id,
      nameEs: 'Pan',
      servingUnit: 'g',
      aliases: ['mi pan', 'pan tajado'],
    );
    await repo.updatePersonalProduct(
      id: id,
      nameEs: 'Pan',
      servingUnit: 'ml',
      aliases: ['pan tajado'],
    );
    expect(await repo.getPersonalProductAliases(), {
      id: ['pan tajado'],
    });
    expect((await repo.getPersonalProductById(id))!.servingUnit, 'ml');
  });

  test('SPEC-034 AC8: migrar desde la v7 conserva los productos, unidad "g" y sin alias; borrar todo y exportar', () async {
    final dir = await Directory.systemTemp.createTemp('spec034');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/user.db';

    final v7 = AppDatabase(AppDatabase.openFile(path));
    final id = await _saveBread(StorageRepository(v7));
    // Simula un user.db de la v7: sin la columna ni la tabla de alias.
    await v7.customStatement('DROP TABLE personal_product_aliases');
    await v7.customStatement(
      'ALTER TABLE personal_products DROP COLUMN serving_unit',
    );
    await v7.customStatement('PRAGMA user_version = 7');
    await v7.close();

    final v8 = AppDatabase(AppDatabase.openFile(path));
    addTearDown(v8.close);
    final repo = StorageRepository(v8);
    final product = (await repo.getAllPersonalProducts()).single;
    expect(product.id, id);
    expect(product.nameEs, 'Pan');
    expect(product.servingUnit, 'g');
    expect(await repo.getPersonalProductAliases(), isEmpty);
    final version = await v8
        .customSelect('PRAGMA user_version')
        .map((row) => row.read<int>('user_version'))
        .getSingle();
    // La versión vigente (SPEC-025 la subió a 10).
    expect(version, v8.schemaVersion);

    await repo.updatePersonalProduct(
      id: id,
      nameEs: 'Pan',
      servingUnit: 'ml',
      aliases: ['mi pan'],
    );
    final exported = await repo.exportUserData();
    final exportedProduct =
        (exported['personalProducts']! as List).single as Map;
    expect(exportedProduct['servingUnit'], 'ml');
    expect(exportedProduct['aliases'], ['mi pan']);

    await repo.deleteAllUserData();
    expect(await repo.getAllPersonalProducts(), isEmpty);
    expect(await repo.getPersonalProductAliases(), isEmpty);
  });

  test('SPEC-034: migrar desde la v1 crea productos (con unidad) y alias, y conserva las comidas', () async {
    final dir = await Directory.systemTemp.createTemp('spec034v1');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/user.db';

    final v1 = AppDatabase(AppDatabase.openFile(path));
    final repo1 = StorageRepository(v1);
    final id = await _saveBread(repo1);
    await _registerWith(repo1, id);
    // Simula la v1: solo comidas.
    for (final table in [
      'personal_product_aliases',
      'personal_products',
      'consent_record',
      'user_profile',
      'nutrition_goals',
      'weight_log',
    ]) {
      await v1.customStatement('DROP TABLE $table');
    }
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    final v8 = AppDatabase(AppDatabase.openFile(path));
    addTearDown(v8.close);
    final repo = StorageRepository(v8);
    expect(await repo.mealsForDay(DateTime(2026, 10, 7)), hasLength(1));
    final newId = await _saveBread(repo);
    expect((await repo.getPersonalProductById(newId))!.servingUnit, 'g');
    await repo.updatePersonalProduct(
      id: newId,
      nameEs: 'Pan',
      servingUnit: 'g',
      aliases: ['mi pan'],
    );
    expect(await repo.getPersonalProductAliases(), {
      newId: ['mi pan'],
    });
  });
}
