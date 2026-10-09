import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/diary/diary_screen.dart';
import 'package:calorias_ia/features/history/history_screen.dart';
import 'package:calorias_ia/features/review/review_screen.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/ui/components/meal_actions.dart';
import 'package:calorias_ia/ui/components/meal_card.dart';
import 'package:calorias_ia/ui/favorite_flow.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';

final _now = DateTime(2026, 10, 8, 12);

MealItemRecord _egg(double kcal) => MealItemRecord(
  mention: 'huevo',
  foodId: 'huevo',
  nameSnapshot: 'Huevo',
  grams: 100,
  quantityBasis: 'explicitWeight',
  energyKcal: kcal,
  proteinG: 12,
  carbsG: 1,
  fatG: 9,
  confidence: 'altaPrecision',
  sourceRef: 'fixture',
);

Future<int> _meal(
  StorageRepository repo,
  DateTime at,
  String type,
  double kcal,
) => repo.registerMeal(
  eatenAt: at,
  mealType: type,
  confidence: 'altaPrecision',
  catalogVersion: 'test-1',
  items: [_egg(kcal)],
);

class _FailingDelete extends StorageRepository {
  _FailingDelete(super.db);

  @override
  Future<void> deleteMeal(int id) =>
      Future.error(StateError('SqliteException: DELETE … huevo'));
}

Future<AppDatabase> _pump(
  WidgetTester tester, {
  required Widget home,
  bool failingDelete = false,
  Future<void> Function(StorageRepository repo)? seed,
}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (seed != null) await tester.runAsync(() => seed(StorageRepository(db)));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (failingDelete)
          storageRepositoryProvider.overrideWithValue(_FailingDelete(db)),
        catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp(
        home: home,
        onGenerateRoute: (settings) => switch (settings.name) {
          AppRoutes.editMeal => MaterialPageRoute(
            settings: settings,
            builder: (_) =>
                Scaffold(body: Text('Editar (mock) ${settings.arguments}')),
          ),
          AppRoutes.review => MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Repetir (mock)')),
          ),
          _ => null,
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Future<void> _todayTwoMeals(StorageRepository repo) async {
  await _meal(repo, DateTime(2026, 10, 8, 8, 30), 'desayuno', 300);
  await _meal(repo, DateTime(2026, 10, 8, 11), 'almuerzo', 200);
}

Finder _card(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(MealCard));

Future<void> _longPress(WidgetTester tester, String label) async {
  await tester.ensureVisible(_card(label));
  await tester.longPress(_card(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AC1 + SPEC-038 AC4: en Hoy, el menú tiene Editar, "Repetir ahora" y Eliminar',
    (tester) async {
      await _pump(tester, home: const DiaryScreen(), seed: _todayTwoMeals);
      await _longPress(tester, 'Desayuno');
      expect(find.text(editMealAction), findsOneWidget);
      expect(find.text(deleteMealAction), findsOneWidget);
      expect(find.text(repeatTodayAction), findsNothing);
      expect(find.text(repeatNowAction), findsOneWidget);

      await tester.tap(find.text(repeatNowAction));
      await tester.pumpAndSettle();
      expect(find.text('Repetir (mock)'), findsOneWidget);
    },
  );

  testWidgets(
    'SPEC-038 AC6: una comida de hoy con un alimento que ya no existe no ofrece "Repetir ahora"',
    (tester) async {
      await _pump(
        tester,
        home: const DiaryScreen(),
        seed: (repo) => repo.registerMeal(
          eatenAt: DateTime(2026, 10, 8, 8),
          mealType: 'desayuno',
          confidence: 'altaPrecision',
          catalogVersion: 'test-1',
          items: const [
            MealItemRecord(
              mention: 'pan',
              personalProductId: 999,
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
        ),
      );
      await _longPress(tester, 'Desayuno');
      expect(find.text(editMealAction), findsOneWidget);
      expect(find.text(repeatNowAction), findsNothing);
    },
  );

  testWidgets(
    'AC2: eliminar confirma, quita la tarjeta, baja las kcal, avisa y sigue en Hoy',
    (tester) async {
      final db = await _pump(
        tester,
        home: const DiaryScreen(),
        seed: _todayTwoMeals,
      );
      expect(find.text('500'), findsOneWidget);
      await _longPress(tester, 'Desayuno');
      await tester.tap(find.text(deleteMealAction));
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar el desayuno de las 8:30?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
      await tester.pumpAndSettle();

      expect(find.text(mealDeletedMessage), findsOneWidget);
      expect(_card('Desayuno'), findsNothing);
      expect(_card('Almuerzo'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.byType(DiaryScreen), findsOneWidget);
      final meals = await tester.runAsync(
        () => StorageRepository(db).mealsForDay(DateTime(2026, 10, 8)),
      );
      expect(meals, hasLength(1));
    },
  );

  testWidgets('AC3: cancelar no cambia nada', (tester) async {
    await _pump(tester, home: const DiaryScreen(), seed: _todayTwoMeals);
    await _longPress(tester, 'Desayuno');
    await tester.tap(find.text(deleteMealAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(_card('Desayuno'), findsOneWidget);
    expect(find.text(mealDeletedMessage), findsNothing);
  });

  testWidgets(
    'AC4: en Historial (ayer), el menú tiene Repetir hoy y eliminar actualiza el día',
    (tester) async {
      await _pump(
        tester,
        home: HistoryScreen(initialDay: DateTime(2026, 10, 7)),
        seed: (repo) => _meal(repo, DateTime(2026, 10, 7, 13), 'cena', 400),
      );
      await _longPress(tester, 'Cena');
      expect(find.text(editMealAction), findsOneWidget);
      expect(find.text(repeatTodayAction), findsOneWidget);
      expect(find.text(deleteMealAction), findsOneWidget);
      await tester.tap(find.text(deleteMealAction));
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar la cena de las 13:00?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
      await tester.pumpAndSettle();
      expect(find.byType(MealCard), findsNothing);
      expect(find.text(mealDeletedMessage), findsOneWidget);
      // R2: el día ya no tiene registros (ni kcal ni tarjetas).
      expect(find.byKey(const Key('history-kcal')), findsNothing);
    },
  );

  testWidgets(
    'R1: sin "Repetir hoy" si algún alimento ya no existe (como SPEC-026 R4)',
    (tester) async {
      await _pump(
        tester,
        home: HistoryScreen(initialDay: DateTime(2026, 10, 7)),
        seed: (repo) => repo.registerMeal(
          eatenAt: DateTime(2026, 10, 7, 13),
          mealType: 'cena',
          confidence: 'altaPrecision',
          catalogVersion: 'test-1',
          items: const [
            MealItemRecord(
              mention: 'pan',
              personalProductId: 999, // producto borrado
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
        ),
      );
      await _longPress(tester, 'Cena');
      expect(find.text(editMealAction), findsOneWidget);
      expect(find.text(repeatTodayAction), findsNothing);
      expect(find.text(deleteMealAction), findsOneWidget);
    },
  );

  testWidgets('AC4: "Repetir hoy" desde Historial abre el Detalle', (
    tester,
  ) async {
    await _pump(
      tester,
      home: HistoryScreen(initialDay: DateTime(2026, 10, 7)),
      seed: (repo) => _meal(repo, DateTime(2026, 10, 7, 13), 'cena', 400),
    );
    await _longPress(tester, 'Cena');
    await tester.tap(find.text(repeatTodayAction));
    await tester.pumpAndSettle();
    expect(find.text('Repetir (mock)'), findsOneWidget);
  });

  testWidgets('AC5: si borrar falla, aviso y la comida sigue', (tester) async {
    await _pump(
      tester,
      home: const DiaryScreen(),
      seed: _todayTwoMeals,
      failingDelete: true,
    );
    await _longPress(tester, 'Desayuno');
    await tester.tap(find.text(deleteMealAction));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();
    expect(find.text(deleteMealErrorMessage), findsOneWidget);
    expect(find.textContaining('Sqlite'), findsNothing);
    expect(_card('Desayuno'), findsOneWidget);
  });

  testWidgets('AC6: "Editar comida" abre esa comida', (tester) async {
    late int breakfastId;
    await _pump(
      tester,
      home: const DiaryScreen(),
      seed: (repo) async {
        breakfastId = await _meal(
          repo,
          DateTime(2026, 10, 8, 8, 30),
          'desayuno',
          300,
        );
      },
    );
    await _longPress(tester, 'Desayuno');
    await tester.tap(find.text(editMealAction));
    await tester.pumpAndSettle();
    expect(find.text('Editar (mock) $breakfastId'), findsOneWidget);
  });

  testWidgets('R4: la tarjeta anuncia el gesto y ofrece "Más opciones"', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, home: const DiaryScreen(), seed: _todayTwoMeals);
    final node = tester.getSemantics(
      find
          .descendant(of: _card('Desayuno'), matching: find.byType(Semantics))
          .first,
    );
    final data = node.getSemanticsData();
    expect(data.hint, mealCardHint);
    expect(
      data.customSemanticsActionIds,
      contains(
        CustomSemanticsAction.getIdentifier(
          const CustomSemanticsAction(label: moreOptionsAction),
        ),
      ),
    );
    handle.dispose();
  });

  testWidgets(
    'SPEC-038: en Historial con el día de hoy, el menú dice "Repetir ahora"',
    (tester) async {
      await _pump(
        tester,
        home: HistoryScreen(initialDay: DateTime(2026, 10, 8)),
        seed: _todayTwoMeals,
      );
      await _longPress(tester, 'Desayuno');
      expect(find.text(repeatNowAction), findsOneWidget);
      expect(find.text(repeatTodayAction), findsNothing);
    },
  );

  testWidgets(
    'SPEC-022 AC8: en Hoy, mantener presionada → "Guardar como favorita" la guarda',
    (tester) async {
      final db = await _pump(
        tester,
        home: const DiaryScreen(),
        seed: _todayTwoMeals,
      );
      await _longPress(tester, 'Desayuno');
      await tester.tap(find.text(saveFavoriteAction));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('favorite-name')),
        'Desayuno de siempre',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(find.text(favoriteSavedMessage), findsOneWidget);
      final favorites = await tester.runAsync(
        () => StorageRepository(db).favoriteMeals(),
      );
      expect(favorites!.single.favorite.name, 'Desayuno de siempre');
      expect(favorites.single.items.single.foodId, 'huevo');
      expect(favorites.single.items.single.grams, 100);
    },
  );

  testWidgets(
    'SPEC-022 R2: con un alimento que ya no existe no ofrece "Guardar como favorita"',
    (tester) async {
      await _pump(
        tester,
        home: const DiaryScreen(),
        seed: (repo) => repo.registerMeal(
          eatenAt: DateTime(2026, 10, 8, 8),
          mealType: 'desayuno',
          confidence: 'altaPrecision',
          catalogVersion: 'test-1',
          items: const [
            MealItemRecord(
              mention: 'pan',
              personalProductId: 999,
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
        ),
      );
      await _longPress(tester, 'Desayuno');
      expect(find.text(saveFavoriteAction), findsNothing);
    },
  );

  testWidgets(
    'SPEC-022 R2: el detalle de una comida guardada tiene "Guardar como favorita"',
    (tester) async {
      late int id;
      final db = await _pump(
        tester,
        home: const SizedBox.shrink(),
        seed: (repo) async =>
            id = await _meal(repo, DateTime(2026, 10, 7, 8), 'desayuno', 143),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
            clockProvider.overrideWithValue(() => _now),
          ],
          child: MaterialApp(home: ReviewScreen(editMealId: id)),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(const Key('meal-detail-save-favorite'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      // Sin nombre: los alimentos.
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      final favorites = await tester.runAsync(
        () => StorageRepository(db).favoriteMeals(),
      );
      expect(favorites!.single.favorite.name, 'Huevo');
    },
  );
}
