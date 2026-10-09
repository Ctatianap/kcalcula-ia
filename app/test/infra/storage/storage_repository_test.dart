import 'dart:convert';
import 'dart:io';

import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
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

  group('SPEC-006: consentimiento', () {
    test('getConsentState sin fila guardada devuelve null (AC1)', () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final db = AppDatabase(AppDatabase.openFile('${dir.path}/user_test.db'));
      final repo = StorageRepository(db);

      expect(await repo.getConsentState(), isNull);

      await db.close();
    });

    test(
      'saveConsent persiste y sobrevive a cerrar/reabrir la base (AC3, AC4)',
      () async {
        final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
        final dbPath = '${dir.path}/user_test.db';
        addTearDown(() => dir.deleteSync(recursive: true));

        final db1 = AppDatabase(AppDatabase.openFile(dbPath));
        await StorageRepository(db1).saveConsent(policyVersion: 'v1');
        await db1.close();

        final db2 = AppDatabase(AppDatabase.openFile(dbPath));
        final state = await StorageRepository(db2).getConsentState();
        await db2.close();

        expect(state, isNotNull);
        expect(state!.ageConfirmed, isTrue);
        expect(state.consentGiven, isTrue);
        expect(state.policyVersion, 'v1');
      },
    );

    test('saveConsent llamado dos veces reemplaza la fila única', () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final db = AppDatabase(AppDatabase.openFile('${dir.path}/user_test.db'));
      final repo = StorageRepository(db);

      await repo.saveConsent(policyVersion: 'v1');
      await repo.saveConsent(policyVersion: 'v2');
      final state = await repo.getConsentState();

      expect(state!.policyVersion, 'v2');

      await db.close();
    });

    test('revokeConsent borra la fila sin tocar meals/meal_items/personal_products (AC14)', () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final db = AppDatabase(AppDatabase.openFile('${dir.path}/user_test.db'));
      final repo = StorageRepository(db);

      await repo.saveConsent(policyVersion: 'v1');
      await repo.registerMeal(
        eatenAt: DateTime(2026, 9, 27, 8),
        mealType: 'desayuno',
        confidence: 'buenaEstimacion',
        catalogVersion: 'test-1',
        items: [_egg()],
      );

      await repo.revokeConsent();

      expect(await repo.getConsentState(), isNull);
      final meals = await repo.mealsForDay(DateTime(2026, 9, 27));
      expect(meals, hasLength(1));

      await db.close();
    });

    test('revokeConsent sin consentimiento guardado no falla', () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final db = AppDatabase(AppDatabase.openFile('${dir.path}/user_test.db'));
      final repo = StorageRepository(db);

      await repo.revokeConsent();
      expect(await repo.getConsentState(), isNull);

      await db.close();
    });
  });

  group('SPEC-006: borrar todo y exportar', () {
    test(
      'deleteAllUserData deja meals/meal_items/personal_products vacíos (AC6)',
      () async {
        final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
        addTearDown(() => dir.deleteSync(recursive: true));
        final db = AppDatabase(
          AppDatabase.openFile('${dir.path}/user_test.db'),
        );
        final repo = StorageRepository(db);

        await repo.registerMeal(
          eatenAt: DateTime(2026, 9, 27, 8),
          mealType: 'desayuno',
          confidence: 'buenaEstimacion',
          catalogVersion: 'test-1',
          items: [_egg()],
        );
        await repo.savePersonalProduct(
          nameEs: 'Producto de prueba',
          energyKcal100: 466.7,
          proteinG100: 6.7,
          carbsG100: 66.7,
          fatG100: 20,
          servingGrams: 30,
          sourceRef: 'fixture de prueba',
        );

        await repo.deleteAllUserData();

        expect(await repo.mealsForDay(DateTime(2026, 9, 27)), isEmpty);
        expect(await repo.getAllPersonalProducts(), isEmpty);

        await db.close();
      },
    );

    test('deleteAllUserData con la base ya vacía no falla', () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final db = AppDatabase(AppDatabase.openFile('${dir.path}/user_test.db'));
      final repo = StorageRepository(db);

      await repo.deleteAllUserData();
      expect(await repo.mealsForDay(DateTime(2026, 9, 27)), isEmpty);

      await db.close();
    });

    test(
      'exportUserData con el diario vacío da arreglos vacíos, sin error (AC8)',
      () async {
        final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
        addTearDown(() => dir.deleteSync(recursive: true));
        final db = AppDatabase(
          AppDatabase.openFile('${dir.path}/user_test.db'),
        );
        final repo = StorageRepository(db);

        final json = await repo.exportUserData();

        expect(json['meals'], isEmpty);
        expect(json['personalProducts'], isEmpty);
        expect(json['exportedAt'], isNotNull);

        await db.close();
      },
    );

    test('exportUserData con datos existentes produce la estructura documentada (AC7, AC9)', () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final db = AppDatabase(AppDatabase.openFile('${dir.path}/user_test.db'));
      final repo = StorageRepository(db);

      await repo.registerMeal(
        eatenAt: DateTime(2026, 9, 27, 8),
        mealType: 'desayuno',
        confidence: 'buenaEstimacion',
        catalogVersion: 'test-1',
        items: [_egg()],
      );
      await repo.savePersonalProduct(
        nameEs: 'Producto de prueba con tildes: ñoño',
        energyKcal100: 466.7,
        proteinG100: 6.7,
        carbsG100: 66.7,
        fatG100: 20,
        servingGrams: 30,
        sourceRef: 'fixture de prueba',
      );

      final json = await repo.exportUserData();

      final meals = json['meals'] as List;
      expect(meals, hasLength(1));
      final meal = meals.first as Map<String, Object?>;
      expect(meal['mealType'], 'desayuno');
      final items = meal['items'] as List;
      expect(items, hasLength(1));
      expect((items.first as Map)['energyKcal'], 143);

      final personalProducts = json['personalProducts'] as List;
      expect(personalProducts, hasLength(1));
      expect(
        (personalProducts.first as Map)['nameEs'],
        'Producto de prueba con tildes: ñoño',
      );

      // AC9: no debe llevar tokens de App Check ni metadatos de red.
      final flat = jsonEncode(json);
      expect(flat.contains('token'), isFalse);
      expect(flat.contains('appCheck'), isFalse);

      await db.close();
    });
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

  test('SPEC-011: mealsBetween es [inicio, fin) y ordena por hora', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    Future<void> at(DateTime t) => repo.registerMeal(
      eatenAt: t,
      mealType: 'snack',
      confidence: 'buenaEstimacion',
      catalogVersion: 'test-1',
      items: [_egg()],
    );
    await at(DateTime(2026, 10, 3, 13));
    await at(DateTime(2026, 10, 3)); // 00:00 del inicio: incluida
    await at(DateTime(2026, 10, 4)); // 00:00 del fin: excluida
    await at(DateTime(2026, 10, 3, 8));

    final meals = await repo.mealsBetween(
      DateTime(2026, 10, 3),
      DateTime(2026, 10, 4),
    );

    expect(meals.map((m) => m.meal.eatenAt.hour), [0, 8, 13]);
  });

  test('SPEC-014: mealsBetween carga los ítems en lote, cada uno con su '
      'comida y en orden', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    MealItemRecord item(String name) => MealItemRecord(
      mention: name,
      foodId: name,
      nameSnapshot: name,
      grams: 100,
      quantityBasis: 'explicitWeight',
      energyKcal: 100,
      proteinG: 1,
      carbsG: 1,
      fatG: 1,
      confidence: 'buenaEstimacion',
      sourceRef: 'fixture',
    );
    for (var d = 1; d <= 3; d++) {
      await repo.registerMeal(
        eatenAt: DateTime(2026, 9, d, 8),
        mealType: 'desayuno',
        confidence: 'buenaEstimacion',
        catalogVersion: 'test-1',
        items: [item('a$d'), item('b$d'), item('c$d')],
      );
    }
    final meals = await repo.mealsBetween(
      DateTime(2026, 9),
      DateTime(2026, 10),
    );
    expect(
      [for (final m in meals) m.items.map((i) => i.nameSnapshot).join()],
      ['a1b1c1', 'a2b2c2', 'a3b3c3'],
    );
  });
}
