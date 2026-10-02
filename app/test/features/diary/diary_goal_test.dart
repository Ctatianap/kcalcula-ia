import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/diary/diary_screen.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

MealItemRecord _item(double kcal, {String confidence = 'altaPrecision'}) =>
    MealItemRecord(
      mention: 'algo',
      foodId: 'algo',
      nameSnapshot: 'Algo',
      grams: 100,
      quantityBasis: 'explicitWeight',
      energyKcal: kcal,
      proteinG: 45.26,
      carbsG: 10,
      fatG: 5,
      confidence: confidence,
      sourceRef: 'fixture de prueba',
    );

Future<void> _meal(
  StorageRepository repo,
  double kcal, {
  String confidence = 'altaPrecision',
}) => repo.registerMeal(
  eatenAt: DateTime.now(),
  mealType: 'almuerzo',
  confidence: confidence,
  catalogVersion: 'test-1',
  items: [_item(kcal, confidence: confidence)],
);

Future<void> _pump(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        initialRoute: AppRoutes.diary,
        routes: {
          AppRoutes.diary: (_) => const DiaryScreen(),
          AppRoutes.nutritionGoal: (_) =>
              const Scaffold(body: Text('Pantalla de meta')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('textos de progreso (AC6)', () {
    test('kcal por debajo y por encima de la meta', () {
      expect(
        kcalProgressText(
          const GoalProgress(consumed: 1249.6, goal: 2000),
          approximate: false,
        ),
        '1.250 / 2.000 kcal · quedan 750',
      );
      expect(
        kcalProgressText(
          const GoalProgress(consumed: 2150.2, goal: 2000),
          approximate: false,
        ),
        '2.150 / 2.000 kcal · 150 por encima de la meta',
      );
    });

    test('macros con coma decimal', () {
      expect(
        macroProgressText(
          'Proteína',
          const GoalProgress(consumed: 45.26, goal: 100),
          approximate: true,
        ),
        'Proteína: ~45,3 / 100,0 g · quedan 54,7 g',
      );
    });
  });

  testWidgets('AC7: sin meta muestra el total y el enlace a fijar una meta', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _meal(StorageRepository(db), 500);

    await _pump(tester, db);

    expect(find.text('Total del día: 500 kcal'), findsOneWidget);
    await tester.tap(find.text('Fijar una meta diaria'));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla de meta'), findsOneWidget);
  });

  testWidgets('AC6/AC2: con meta de kcal y proteína muestra solo esas dos', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    await repo.saveNutritionGoal(energyKcal: 2000, proteinG: 100);
    await _meal(repo, 1249.6);

    await _pump(tester, db);

    expect(find.text('1.250 / 2.000 kcal · quedan 750'), findsOneWidget);
    expect(find.textContaining('Proteína:'), findsOneWidget);
    expect(find.textContaining('Carbohidratos:'), findsNothing);
    expect(find.textContaining('Grasa:'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(find.text('Fijar una meta diaria'), findsNothing);
  });

  testWidgets('AC12: una comida "Estimación" pone "~" en el consumido', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    await repo.saveNutritionGoal(energyKcal: 2000);
    await _meal(repo, 1000);
    await _meal(repo, 249.6, confidence: 'estimacion');

    await _pump(tester, db);

    expect(find.text('~1.250 / 2.000 kcal · quedan 750'), findsOneWidget);
  });

  testWidgets('día sin comidas con meta: 0 / meta y el texto de vacío', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await StorageRepository(db).saveNutritionGoal(energyKcal: 2000);

    await _pump(tester, db);

    expect(find.text('0 / 2.000 kcal · quedan 2.000'), findsOneWidget);
    expect(find.text('Todavía no registras nada hoy.'), findsOneWidget);
  });
}
