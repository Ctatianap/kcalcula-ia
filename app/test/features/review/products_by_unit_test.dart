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
import 'package:nutrition_core/nutrition_core.dart';

import '../../support/fixture_catalog.dart';
import '../../support/meal_flow_harness.dart';

/// Producto personal "huevo" de prueba (porción 60 g; valores de prueba).
Future<int> _egg(StorageRepository repo, {double? unitGrams}) async {
  final id = await repo.savePersonalProduct(
    nameEs: 'huevo',
    energyKcal100: 140,
    proteinG100: 12,
    carbsG100: 1,
    fatG100: 10,
    servingGrams: 60,
    sourceRef: 'test',
  );
  await repo.updatePersonalProduct(
    id: id,
    nameEs: 'huevo',
    servingUnit: 'g',
    aliases: const [],
    unitGrams: unitGrams,
  );
  return id;
}

final _twoEggs = parsedMeal([
  parsedItem('dos huevos', 'huevo', quantity: 2, unit: 'unidad'),
]);

void main() {
  group('SPEC-045 resolución', () {
    late AppDatabase db;
    late StorageRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StorageRepository(db);
    });
    tearDown(() => db.close());

    Future<FoodCatalogEntry> food() async {
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      final r = FoodQueryResolver(
        catalog: catalog,
        personalProducts: await repo.getAllPersonalProducts(),
      );
      return (r.resolve('huevo') as FoodMatched).food;
    }

    const twoUnits = QuantityInput(
      quantity: 2,
      unit: QuantityUnit.unidad,
      isVague: false,
    );

    test('AC1: con peso de unidad 60 → 2 unidad = 120 g, unit_portion, Buena estimación', () async {
      await _egg(repo, unitGrams: 60);
      final egg = await food();
      final r = resolveGrams(input: twoUnits, food: egg, isLabelProduct: true);
      expect(r.resolvable, isTrue);
      expect(r.grams, 120);
      expect(r.basis, QuantityBasis.unitPortion);
      expect(
        itemConfidence(
          basis: r.basis,
          isVague: false,
          usedCuratedEstimatePortion: r.usedCuratedEstimatePortion,
          usedDensityFallback: r.usedDensityFallback,
        ),
        ConfidenceLevel.buenaEstimacion,
      );
    });

    test(
      'AC2: sin peso de unidad, "unidad" no tiene equivalencia (como hoy)',
      () async {
        await _egg(repo);
        final egg = await food();
        expect(
          resolveGrams(
            input: twoUnits,
            food: egg,
            isLabelProduct: true,
          ).resolvable,
          isFalse,
        );
        expect(egg.portions.map((p) => p.descriptor), ['porcion']);
      },
    );

    test('Edge: "1 porción" sigue usando la porción de la etiqueta', () async {
      await _egg(repo, unitGrams: 55);
      final egg = await food();
      final r = resolveGrams(
        input: const QuantityInput(
          quantity: 1,
          unit: QuantityUnit.porcion,
          isVague: false,
        ),
        food: egg,
        isLabelProduct: true,
      );
      expect(r.grams, 60);
    });
  });

  testWidgets('AC1: "dos huevos" en el detalle → 120 g y Buena estimación', (
    tester,
  ) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => _twoEggs).client,
    );
    await _egg(h.storage, unitGrams: 60);
    await h.openCaptureAndType(tester, 'dos huevos');
    await tester.ensureVisible(find.text('Analizar'));
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    expect(find.text(withoutEquivalenceLabel), findsNothing);
    expect(find.text('Cantidad dicha por ti'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('ingredient-confidence-dos huevos')),
        matching: find.text('Buena estimación'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('120 g'), findsOneWidget);
  });

  group('AC3: "Editar producto"', () {
    Future<(AppDatabase, int)> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = StorageRepository(db);
      final id = (await tester.runAsync(() => _egg(repo)))!;
      final product = (await tester.runAsync(
        () => repo.getPersonalProductById(id),
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
      return (db, id);
    }

    Future<void> save(WidgetTester tester, String text) async {
      await tester.enterText(
        find.byKey(const Key('edit-product-unit-grams')),
        text,
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
    }

    testWidgets('"55,5" se guarda como 55,5', (tester) async {
      final (db, id) = await pump(tester);
      await save(tester, '55,5');
      final saved = await tester.runAsync(
        () => StorageRepository(db).getPersonalProductById(id),
      );
      expect(saved!.unitGrams, 55.5);
    });

    testWidgets('vacío = sin peso', (tester) async {
      final (db, id) = await pump(tester);
      await save(tester, '');
      final saved = await tester.runAsync(
        () => StorageRepository(db).getPersonalProductById(id),
      );
      expect(saved!.unitGrams, isNull);
    });

    for (final bad in ['0', '-3', '5001', 'abc']) {
      testWidgets('"$bad" → mensaje y no se guarda', (tester) async {
        final (db, id) = await pump(tester);
        await save(tester, bad);
        expect(find.text(unitGramsInvalidMessage), findsOneWidget);
        expect(find.byType(EditProductScreen), findsOneWidget);
        final saved = await tester.runAsync(
          () => StorageRepository(db).getPersonalProductById(id),
        );
        expect(saved!.unitGrams, isNull);
      });
    }
  });

  test('AC4: migrar desde la v10 deja el peso nulo; exportar lo incluye; borrar todo lo borra', () async {
    final dir = await Directory.systemTemp.createTemp('spec045');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/user.db';

    final v10 = AppDatabase(AppDatabase.openFile(path));
    final id = await _egg(StorageRepository(v10));
    await v10.customStatement(
      'ALTER TABLE personal_products DROP COLUMN unit_grams',
    );
    await v10.customStatement('PRAGMA user_version = 10');
    await v10.close();

    final v11 = AppDatabase(AppDatabase.openFile(path));
    addTearDown(v11.close);
    final repo = StorageRepository(v11);
    final product = (await repo.getAllPersonalProducts()).single;
    expect(product.id, id);
    expect(product.unitGrams, isNull);

    await repo.updatePersonalProduct(
      id: id,
      nameEs: 'huevo',
      servingUnit: 'g',
      aliases: const [],
      unitGrams: 60,
    );
    final exported = await repo.exportUserData();
    expect(
      ((exported['personalProducts']! as List).single as Map)['unitGrams'],
      60,
    );
    await repo.deleteAllUserData();
    expect(await repo.getAllPersonalProducts(), isEmpty);
  });

  test('R1: el repositorio rechaza un peso inválido', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    final id = await _egg(repo);
    expect(
      () => repo.updatePersonalProduct(
        id: id,
        nameEs: 'huevo',
        servingUnit: 'g',
        aliases: const [],
        unitGrams: 0,
      ),
      throwsArgumentError,
    );
  });
}
