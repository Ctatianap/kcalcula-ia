import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/review/meal_detail_view.dart';
import 'package:calorias_ia/features/review/personal_product_picker_screen.dart';
import 'package:calorias_ia/features/review/review_controller.dart';
import 'package:calorias_ia/features/review/review_screen.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/food_resolution/food_query_resolver.dart';
import 'package:calorias_ia/infra/food_resolution/meal_draft.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/ui/components/meal_actions.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';

final _now = DateTime(2026, 10, 8, 12, 0);
final _yesterdayLunch = DateTime(2026, 10, 7, 13, 0);

MealItemRecord _egg({double grams = 100, double kcal = 143}) => MealItemRecord(
  mention: 'dos huevos',
  foodId: 'huevo',
  nameSnapshot: 'Huevo',
  grams: grams,
  quantityInput: 2,
  unitInput: 'unidad',
  quantityBasis: 'unitPortion',
  energyKcal: kcal,
  proteinG: 12.56,
  carbsG: 0.72,
  fatG: 9.51,
  confidence: 'buenaEstimacion',
  sourceRef: 'fixture',
);

MealItemRecord _arepa() => const MealItemRecord(
  mention: 'una arepa',
  foodId: 'arepa',
  nameSnapshot: 'Arepa',
  grams: 115,
  quantityInput: 1,
  unitInput: 'unidad',
  quantityBasis: 'unitPortion',
  energyKcal: 307.05,
  proteinG: 6.5,
  carbsG: 35,
  fatG: 16.1,
  confidence: 'buenaEstimacion',
  sourceRef: 'fixture',
);

Future<int> _seedMeal(StorageRepository repo, {DateTime? at}) =>
    repo.registerMeal(
      eatenAt: at ?? _yesterdayLunch,
      mealType: 'almuerzo',
      confidence: 'buenaEstimacion',
      catalogVersion: 'test-1',
      items: [_egg(), _arepa()],
    );

Future<FoodQueryResolver> _resolver(
  StorageRepository repo, {
  double eggKcal = 143,
}) async => FoodQueryResolver(
  catalog: buildFixtureCatalog(eggKcal: eggKcal),
  personalProducts: await repo.getAllPersonalProducts(),
);

class _FailingRepository extends StorageRepository {
  _FailingRepository(super.db);

  @override
  Future<void> updateMeal({
    required int id,
    required DateTime eatenAt,
    required String? mealType,
    required String confidence,
    required String catalogVersion,
    required List<MealItemRecord> items,
  }) => Future.error(StateError('SqliteException: UPDATE meals … huevo'));

  @override
  Future<void> deleteMeal(int id) =>
      Future.error(StateError('SqliteException: DELETE meals … huevo'));
}

Future<({AppDatabase db, int mealId})> _pump(
  WidgetTester tester, {
  DateTime? mealAt,
  bool failingWrites = false,
  bool withProduct = false,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = StorageRepository(db);
  final mealId = (await tester.runAsync(() => _seedMeal(repo, at: mealAt)))!;
  if (withProduct) {
    await tester.runAsync(
      () => repo.savePersonalProduct(
        nameEs: 'Huevo campesino',
        energyKcal100: 150,
        proteinG100: 13,
        carbsG100: 1,
        fatG100: 10,
        servingGrams: 60,
        sourceRef: 'test',
      ),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (failingWrites)
          storageRepositoryProvider.overrideWithValue(_FailingRepository(db)),
        catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) => switch (settings.name) {
          AppRoutes.today => MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Hoy (mock)')),
          ),
          AppRoutes.review => MaterialPageRoute(
            settings: settings,
            builder: (_) =>
                ReviewScreen(draft: settings.arguments as MealDraft),
          ),
          _ => null,
        },
        home: ReviewScreen(editMealId: mealId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (db: db, mealId: mealId);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('SPEC-026 (controlador y repositorio)', () {
    late AppDatabase db;
    late StorageRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StorageRepository(db);
    });
    tearDown(() => db.close());

    test('AC1: huevo de 100 g a 150 g conserva el id y recalcula con nutrition_core', () async {
      final id = await _seedMeal(repo);
      final controller = ReviewController.forEdit(
        meal: (await repo.getMealWithItems(id))!,
        resolver: await _resolver(repo),
        storage: repo,
      );
      controller.setGrams(0, 150);
      expect(await controller.register(), id);

      final day = await repo.mealsForDay(DateTime(2026, 10, 7));
      expect(day.single.meal.id, id);
      final egg = day.single.items.first;
      expect(egg.grams, 150);
      expect(egg.energyKcal, closeTo(143 * 1.5, 1e-9));
      // El total del día cambia con el ítem editado.
      expect(day.single.totals.energyKcal, closeTo(143 * 1.5 + 307.05, 1e-9));
    });

    test('R4: solo los cambios de datos cuentan para "Repetir hoy" (no la vista g/porciones)', () async {
      final id = await _seedMeal(repo);
      final controller = ReviewController.forEdit(
        meal: (await repo.getMealWithItems(id))!,
        resolver: await _resolver(repo),
        storage: repo,
      );
      expect(controller.hasChanges, isFalse);
      controller.setShowInGrams(0, true);
      controller.setMealType('almuerzo'); // el mismo
      expect(controller.hasChanges, isFalse);
      controller.setMealType('cena');
      expect(controller.hasChanges, isTrue);
    });

    test('AC2: mover a hoy a las 8:00 la quita de ayer', () async {
      final id = await _seedMeal(repo);
      final controller = ReviewController.forEdit(
        meal: (await repo.getMealWithItems(id))!,
        resolver: await _resolver(repo),
        storage: repo,
      );
      controller.setEatenAt(DateTime(2026, 10, 8, 8));
      await controller.register();
      expect(await repo.mealsForDay(DateTime(2026, 10, 7)), isEmpty);
      expect(
        (await repo.mealsForDay(DateTime(2026, 10, 8))).single.meal.id,
        id,
      );
    });

    test('AC2: una fecha futura no se permite', () {
      expect(
        validateEatenAt(_now.add(const Duration(minutes: 1)), _now),
        futureMealMessage,
      );
      expect(validateEatenAt(_now, _now), isNull);
      expect(validateEatenAt(DateTime(2026, 10, 1), _now), isNull);
    });

    test('AC4: el ítem no tocado conserva su instantánea aunque el catálogo cambió; el editado usa el catálogo actual', () async {
      final id = await _seedMeal(repo);
      // El catálogo ahora dice 200 kcal/100 g para el huevo.
      final controller = ReviewController.forEdit(
        meal: (await repo.getMealWithItems(id))!,
        resolver: await _resolver(repo, eggKcal: 200),
        storage: repo,
      );
      expect(controller.items.first.nutrients!.energyKcal, 143);
      controller.setGrams(1, 120); // la arepa se edita
      await controller.register();

      final items = (await repo.getMealWithItems(id))!.items;
      expect(items[0].energyKcal, 143); // huevo: instantánea
      expect(items[0].nameSnapshot, 'Huevo');
      expect(items[1].grams, 120); // arepa: catálogo actual
      expect(items[1].energyKcal, closeTo(267 * 1.2, 1e-9));
    });

    test(
      'caso borde: un producto borrado se puede ajustar con su instantánea',
      () async {
        final productId = await repo.savePersonalProduct(
          nameEs: 'Pan',
          energyKcal100: 260,
          proteinG100: 9,
          carbsG100: 48,
          fatG100: 3,
          servingGrams: 27,
          sourceRef: 'test',
        );
        final mealId = await repo.registerMeal(
          eatenAt: _yesterdayLunch,
          mealType: 'desayuno',
          confidence: 'altaPrecision',
          catalogVersion: 'test-1',
          items: [
            MealItemRecord(
              mention: 'pan',
              personalProductId: productId,
              nameSnapshot: 'Pan',
              grams: 50,
              quantityBasis: 'label',
              energyKcal: 130,
              proteinG: 4.5,
              carbsG: 24,
              fatG: 1.5,
              confidence: 'altaPrecision',
              sourceRef: 'test',
            ),
          ],
        );
        await repo.deletePersonalProduct(productId);

        final controller = ReviewController.forEdit(
          meal: (await repo.getMealWithItems(mealId))!,
          resolver: await _resolver(repo),
          storage: repo,
        );
        controller.setGrams(0, 100);
        await controller.register();
        final item = (await repo.getMealWithItems(mealId))!.items.single;
        expect(item.grams, 100);
        expect(item.energyKcal, closeTo(260, 1e-9)); // 130 × 2
        expect(item.nameSnapshot, 'Pan');
        expect(item.personalProductId, isNull);
        expect(item.foodId, isNull);
      },
    );
  });

  testWidgets('R1/R2: abre la comida guardada en modo edición', (tester) async {
    await _pump(tester);
    expect(find.text('Editar comida'), findsOneWidget);
    expect(find.byKey(const Key('meal-detail-eaten-at')), findsOneWidget);
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(find.text('Borrar comida'), findsOneWidget);
    expect(find.text(repeatTodayLabel), findsOneWidget);
  });

  testWidgets('AC2: "Cambiar" abre el calendario', (tester) async {
    await _pump(tester);
    await _tap(tester, find.byKey(const Key('meal-detail-change-eaten-at')));
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('AC3: borrar con confirmación quita la comida y sus ítems', (
    tester,
  ) async {
    final pumped = await _pump(tester);
    await _tap(tester, find.text('Borrar comida'));
    expect(find.text('¿Borrar el almuerzo de las 13:00?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();
    expect(find.text('Hoy (mock)'), findsOneWidget);
    final meal = await tester.runAsync(
      () => StorageRepository(pumped.db).getMealWithItems(pumped.mealId),
    );
    expect(meal, isNull);
    final items = await tester.runAsync(
      () => pumped.db.select(pumped.db.mealItems).get(),
    );
    expect(items, isEmpty);
  });

  testWidgets('AC3: cancelar no borra nada', (tester) async {
    final pumped = await _pump(tester);
    await _tap(tester, find.text('Borrar comida'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar comida'), findsOneWidget);
    final meal = await tester.runAsync(
      () => StorageRepository(pumped.db).getMealWithItems(pumped.mealId),
    );
    expect(meal!.items, hasLength(2));
  });

  testWidgets(
    'AC6: un fallo de escritura muestra el mensaje y deja la comida como estaba',
    (tester) async {
      final pumped = await _pump(tester, failingWrites: true);
      await _tap(tester, find.byTooltip('Más').first);
      await _tap(tester, find.text('Guardar cambios'));
      expect(find.text(registerErrorMessage), findsOneWidget);
      expect(find.textContaining('Sqlite'), findsNothing);
      final meal = await tester.runAsync(
        () => StorageRepository(pumped.db).getMealWithItems(pumped.mealId),
      );
      expect(meal!.items.first.grams, 100);
    },
  );

  testWidgets('AC7: "Repetir hoy" guarda una comida nueva con la hora actual', (
    tester,
  ) async {
    final pumped = await _pump(tester);
    await _tap(tester, find.text(repeatTodayLabel));
    expect(find.text('Detalle de comida'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
    expect(find.text('Hoy (mock)'), findsOneWidget);

    final repo = StorageRepository(pumped.db);
    final today = await tester.runAsync(
      () => repo.mealsForDay(DateTime(2026, 10, 8)),
    );
    expect(today!.single.meal.eatenAt, _now);
    expect(today.single.items.map((i) => i.grams), [100, 115]);
    final yesterday = await tester.runAsync(
      () => repo.mealsForDay(DateTime(2026, 10, 7)),
    );
    expect(yesterday!.single.meal.id, pumped.mealId);
  });

  testWidgets(
    'R4 + SPEC-038 AC5: una comida de hoy ofrece "Repetir ahora", no "Repetir hoy"',
    (tester) async {
      await _pump(tester, mealAt: DateTime(2026, 10, 8, 9));
      expect(find.text(repeatTodayLabel), findsNothing);
      expect(find.text(repeatNowAction), findsOneWidget);
    },
  );

  testWidgets(
    'SPEC-038 AC5: "Repetir ahora" se desactiva con cambios sin guardar',
    (tester) async {
      await _pump(tester, mealAt: DateTime(2026, 10, 8, 9));
      await _tap(tester, find.byTooltip('Más').first);
      final repeat = find.widgetWithText(OutlinedButton, repeatNowAction);
      await tester.ensureVisible(repeat);
      expect(tester.widget<OutlinedButton>(repeat).onPressed, isNull);
    },
  );

  testWidgets(
    'AC8: "Elegir de mis productos" al editar cambia ese ítem y conserva el id y los demás',
    (tester) async {
      final pumped = await _pump(tester, withProduct: true);
      final menu = find.byKey(const Key('ingredient-menu-dos huevos'));
      await _tap(tester, menu);
      await tester.tap(find.text(pickProductAction));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalProductPickerScreen), findsOneWidget);
      await tester.tap(find.text('Huevo campesino'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Guardar cambios'));

      final meal = await tester.runAsync(
        () => StorageRepository(pumped.db).getMealWithItems(pumped.mealId),
      );
      expect(meal!.meal.id, pumped.mealId);
      expect(meal.items.first.nameSnapshot, 'Huevo campesino');
      expect(meal.items.first.personalProductId, isNotNull);
      // Arepa: instantánea (el catálogo daría 6,509 g de proteína).
      expect(meal.items[1].proteinG, 6.5);
    },
  );

  testWidgets(
    'AC2: hoy con una hora posterior a la actual muestra el mensaje y no cambia la fecha',
    (tester) async {
      await _pump(tester);
      final before = tester
          .widget<Text>(find.byKey(const Key('meal-detail-eaten-at')))
          .data;
      await _tap(tester, find.byKey(const Key('meal-detail-change-eaten-at')));
      // Hoy (8) en el calendario; la hora propuesta es la de la comida
      // (13:00), posterior a las 12:00 de "ahora".
      // Sin depender del idioma de los textos de Material.
      final ok = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      ).okButtonLabel;
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
      expect(find.text(futureMealMessage), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('meal-detail-eaten-at'))).data,
        before,
      );
    },
  );

  testWidgets('AC6: si borrar falla, mensaje y la comida sigue', (
    tester,
  ) async {
    final pumped = await _pump(tester, failingWrites: true);
    await _tap(tester, find.text('Borrar comida'));
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();
    expect(find.text(deleteMealErrorMessage), findsOneWidget);
    expect(find.textContaining('Sqlite'), findsNothing);
    final meal = await tester.runAsync(
      () => StorageRepository(pumped.db).getMealWithItems(pumped.mealId),
    );
    expect(meal, isNotNull);
  });

  testWidgets('caso borde: la comida ya no existe', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
        ],
        child: const MaterialApp(home: ReviewScreen(editMealId: 999)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(mealGoneMessage), findsOneWidget);
  });

  testWidgets('R4: con cambios sin guardar, "Repetir hoy" se desactiva', (
    tester,
  ) async {
    await _pump(tester);
    await _tap(tester, find.byTooltip('Más').first);
    final repeat = find.widgetWithText(OutlinedButton, repeatTodayLabel);
    await tester.ensureVisible(repeat);
    expect(tester.widget<OutlinedButton>(repeat).onPressed, isNull);
  });

  test('R3: el artículo del tipo de comida', () {
    expect(mealWithArticle('cena'), 'la cena');
    expect(mealWithArticle('almuerzo'), 'el almuerzo');
    expect(mealWithArticle('desayuno'), 'el desayuno');
    expect(mealWithArticle('snack'), 'el snack');
    expect(mealWithArticle(null), 'el snack');
  });

  test('R2: guardar cambios actualiza updated_at', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    final id = await _seedMeal(repo);
    final before = (await repo.getMealWithItems(id))!.meal.updatedAt;
    await Future<void>.delayed(const Duration(seconds: 1));
    await repo.updateMeal(
      id: id,
      eatenAt: _yesterdayLunch,
      mealType: 'almuerzo',
      confidence: 'buenaEstimacion',
      catalogVersion: 'test-1',
      items: [_egg()],
    );
    final after = (await repo.getMealWithItems(id))!.meal.updatedAt;
    expect(after.isAfter(before), isTrue);
  });
}
