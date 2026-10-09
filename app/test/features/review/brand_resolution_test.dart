import 'dart:io';

import 'package:calorias_ia/features/review/meal_detail_view.dart';
import 'package:calorias_ia/features/settings/my_products_screen.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/catalog/food_match_result.dart';
import 'package:calorias_ia/infra/food_resolution/food_query_resolver.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';
import '../../support/meal_flow_harness.dart';

/// Guarda un producto personal con [brand] (valores de prueba, no de un
/// catálogo real).
Future<int> _product(
  StorageRepository repo,
  String name, {
  String? brand,
  List<String> aliases = const [],
  String unit = 'g',
}) async {
  final id = await repo.savePersonalProduct(
    nameEs: name,
    energyKcal100: 100,
    proteinG100: 5,
    carbsG100: 10,
    fatG100: 4,
    servingGrams: 150,
    sourceRef: 'test',
    servingUnit: unit,
  );
  await repo.updatePersonalProduct(
    id: id,
    nameEs: name,
    servingUnit: unit,
    aliases: aliases,
    brand: brand,
  );
  return id;
}

void main() {
  group('SPEC-025 resolver', () {
    late AppDatabase db;
    late StorageRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StorageRepository(db);
    });
    tearDown(() => db.close());

    Future<FoodQueryResolver> resolver() async {
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      return FoodQueryResolver(
        catalog: catalog,
        personalProducts: await repo.getAllPersonalProducts(),
        aliases: await repo.getPersonalProductAliases(),
      );
    }

    test('AC1: "yogur Alpina" → mi "Yogur griego" de Alpina', () async {
      final id = await _product(repo, 'Yogur griego', brand: 'Alpina');
      final result = (await resolver()).resolve(
        'yogur Alpina',
        mention: 'un yogur Alpina',
      );
      expect(result, isA<FoodMatched>());
      expect((result as FoodMatched).food.id, 'personal:$id');
    });

    test('AC2: la marca solo en la frase también cuenta', () async {
      final id = await _product(
        repo,
        'Leche deslactosada',
        brand: 'Colanta',
        unit: 'ml',
      );
      final result = (await resolver()).resolve(
        'leche deslactosada',
        mention: 'un vaso de leche deslactosada Colanta',
      );
      expect((result as FoodMatched).food.id, 'personal:$id');
    });

    test(
      'AC3: dos productos de la marca que coinciden → "¿Cuál de estos?"',
      () async {
        await _product(repo, 'Yogur griego', brand: 'Alpina');
        await _product(repo, 'Yogur de fresa', brand: 'Alpina');
        final result = (await resolver()).resolve(
          'yogur Alpina',
          mention: 'un yogur Alpina',
        );
        expect(
          (result as FoodAmbiguous).candidates.map((c) => c.nameEs),
          unorderedEquals(['Yogur griego', 'Yogur de fresa']),
        );
      },
    );

    test(
      'AC4 (lógica): marca sin producto que coincida → como hoy y el aviso',
      () async {
        await _product(repo, 'Yogur griego', brand: 'Alpina');
        final r = await resolver();
        expect(
          r.resolve('kumis Alpina', mention: 'un kumis Alpina'),
          isA<FoodNotFound>(),
        );
        expect(r.brandWithoutProduct('kumis Alpina', 'un kumis Alpina'), (
          brand: 'Alpina',
          query: 'kumis',
        ));
        // Con producto que coincide, no hay aviso.
        expect(
          r.brandWithoutProduct('yogur Alpina', 'un yogur Alpina'),
          isNull,
        );
      },
    );

    test('AC5: normalización de la marca', () async {
      final id = await _product(repo, 'Arepa de maíz', brand: 'Doñarepa');
      final r = await resolver();
      // Mayúsculas y tildes no importan.
      expect(
        (r.resolve(
          'arepa doñarepa',
          mention: 'una arepa DOÑAREPA',
        ) as FoodMatched).food.id,
        'personal:$id',
      );
      expect(
        (r.resolve(
          'arepa Donarepa',
          mention: 'una arepa Donarepa',
        ) as FoodMatched).food.id,
        'personal:$id',
      );
      // "Doña Arepa" (dos palabras) es otra marca: no se reconoce.
      expect(
        r.resolve('arepa', mention: 'una arepa Doña Arepa'),
        isNot(
          isA<FoodMatched>().having((m) => m.food.id, 'id', 'personal:$id'),
        ),
      );
    });

    test('AC6: sin marca en la frase, la resolución no cambia', () async {
      await _product(repo, 'Yogur griego', brand: 'Alpina');
      final r = await resolver();
      expect(r.resolve('huevo', mention: 'dos huevos'), isA<FoodMatched>());
      expect(
        (r.resolve('huevo', mention: 'dos huevos') as FoodMatched).food.id,
        'huevo',
      );
      expect(r.brandWithoutProduct('huevo', 'dos huevos'), isNull);
    });

    test('R4: el nombre o alias exacto gana sobre la marca', () async {
      final exact = await _product(repo, 'yogur Alpina');
      await _product(repo, 'Yogur griego', brand: 'Alpina');
      final result = (await resolver()).resolve(
        'yogur Alpina',
        mention: 'un yogur Alpina',
      );
      expect((result as FoodMatched).food.id, 'personal:$exact');
    });

    test(
      'Edge: la marca dentro de otra palabra no cuenta; sin resto no se usa',
      () async {
        await _product(repo, 'Yogur griego', brand: 'Alpina');
        final r = await resolver();
        expect(
          r.brandWithoutProduct('yogur alpinas', 'un yogur alpinas'),
          isNull,
        );
        // Solo la marca: el resto queda vacío.
        expect(r.brandWithoutProduct('Alpina', 'un Alpina'), isNull);
      },
    );
  });

  group('SPEC-025 pantalla', () {
    final yogurAlpina = parsedMeal([
      parsedItem('un yogur Alpina', 'yogur Alpina', quantity: 150, unit: 'g'),
    ]);
    final kumisAlpina = parsedMeal([
      parsedItem('un kumis Alpina', 'kumis Alpina'),
    ]);

    testWidgets('AC1: el detalle usa mi producto Alpina con Alta precisión', (
      tester,
    ) async {
      final h = await MealFlowHarness.pump(
        tester,
        aiClient: FakeParseMeal((_) => yogurAlpina).client,
      );
      await _product(h.storage, 'Yogur griego', brand: 'Alpina');
      await h.openCaptureAndType(tester, 'un yogur Alpina');
      await tester.ensureVisible(find.text('Analizar'));
      await tester.tap(find.text('Analizar'));
      await tester.pumpAndSettle();
      expect(find.text('Yogur griego'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const Key('ingredient-confidence-un yogur Alpina')),
          matching: find.text('Alta precisión'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'AC4: "kumis Alpina" sin producto → aviso con "Usar etiqueta"',
      (tester) async {
        final h = await MealFlowHarness.pump(
          tester,
          aiClient: FakeParseMeal((_) => kumisAlpina).client,
        );
        await _product(h.storage, 'Yogur griego', brand: 'Alpina');
        await h.openCaptureAndType(tester, 'un kumis Alpina');
        await tester.ensureVisible(find.text('Analizar'));
        await tester.tap(find.text('Analizar'));
        await tester.pumpAndSettle();
        expect(
          // "kumis" no está en el catálogo de prueba: no se dice "usé el
          // genérico".
          find.text(
            brandWithoutProductMessage('Alpina', 'kumis', usedGeneric: false),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.byKey(const Key('brand-notice-un kumis Alpina')),
              matching: find.byType(Column),
            ),
            matching: find.widgetWithText(TextButton, useLabelAction),
          ),
          findsWidgets,
        );
      },
    );
  });

  testWidgets('AC7: "Editar producto" guarda la marca', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    final id = await tester.runAsync(() => _product(repo, 'Yogur griego'));
    final product = (await tester.runAsync(
      () => repo.getPersonalProductById(id!),
    ))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
        ],
        child: MaterialApp(
          home: EditProductScreen(product: product, aliases: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-product-brand')),
      '  Alpina ',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(() => repo.getPersonalProductById(id!));
    expect(saved!.brand, 'Alpina');
  });

  test('AC7: migrar desde la v9 deja la marca nula; exportar la incluye; borrar todo la borra', () async {
    final dir = await Directory.systemTemp.createTemp('spec025');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/user.db';

    final v9 = AppDatabase(AppDatabase.openFile(path));
    final id = await StorageRepository(v9).savePersonalProduct(
      nameEs: 'Yogur griego',
      energyKcal100: 100,
      proteinG100: 5,
      carbsG100: 10,
      fatG100: 4,
      servingGrams: 150,
      sourceRef: 'test',
    );
    await v9.customStatement('ALTER TABLE personal_products DROP COLUMN brand');
    await v9.customStatement('PRAGMA user_version = 9');
    await v9.close();

    final v10 = AppDatabase(AppDatabase.openFile(path));
    addTearDown(v10.close);
    final repo = StorageRepository(v10);
    final product = (await repo.getAllPersonalProducts()).single;
    expect(product.id, id);
    expect(product.brand, isNull);

    await repo.updatePersonalProduct(
      id: id,
      nameEs: 'Yogur griego',
      servingUnit: 'g',
      aliases: const [],
      brand: 'Alpina',
    );
    final exported = await repo.exportUserData();
    expect(
      ((exported['personalProducts']! as List).single as Map)['brand'],
      'Alpina',
    );
    await repo.deleteAllUserData();
    expect(await repo.getAllPersonalProducts(), isEmpty);
  });

  group('SPEC-025 MINOR', () {
    late AppDatabase db;
    late StorageRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StorageRepository(db);
    });
    tearDown(() => db.close());

    test('R1: la marca se recorta a 40 caracteres en el repositorio', () async {
      final id = await _product(repo, 'Yogur', brand: '  ${'a' * 45}  ');
      expect((await repo.getPersonalProductById(id))!.brand, 'a' * 40);
    });

    test(
      'Edge: dos marcas en la frase → se usa la que tiene producto',
      () async {
        await _product(repo, 'Pan tajado', brand: 'Bimbo');
        final id = await _product(repo, 'Yogur griego', brand: 'Alpina Plus');
        final catalog = buildFixtureCatalog();
        addTearDown(catalog.close);
        final r = FoodQueryResolver(
          catalog: catalog,
          personalProducts: await repo.getAllPersonalProducts(),
          aliases: await repo.getPersonalProductAliases(),
        );
        // "Alpina Plus" (más larga) se prueba primero y sí tiene el yogur.
        final result = r.resolve(
          'yogur Alpina Plus',
          mention: 'un yogur Alpina Plus con pan Bimbo',
        );
        expect((result as FoodMatched).food.id, 'personal:$id');
        // "pan Bimbo": Alpina Plus no tiene pan, pero Bimbo sí.
        final bread = r.resolve(
          'pan Bimbo',
          mention: 'un yogur Alpina Plus con pan Bimbo',
        );
        expect((bread as FoodMatched).food.nameEs, 'Pan tajado');
      },
    );
  });
}
