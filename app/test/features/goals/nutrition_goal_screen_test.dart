import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/goals/nutrition_goal_controller.dart';
import 'package:calorias_ia/features/goals/nutrition_goal_screen.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _pump(WidgetTester tester, {AppDatabase? db}) async {
  final database = db ?? AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        initialRoute: AppRoutes.nutritionGoal,
        routes: {
          AppRoutes.diary: (_) => const Scaffold(body: Text('Diario')),
          AppRoutes.nutritionGoal: (_) => const NutritionGoalScreen(),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return database;
}

FilledButton _saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'));

void main() {
  testWidgets('AC1: kcal vacía deshabilita Guardar; 2000 se guarda', (
    tester,
  ) async {
    final db = await _pump(tester);
    addTearDown(db.close);

    expect(_saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('goal-kcal')), '2000');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final goal = await StorageRepository(db).getNutritionGoal();
    expect(goal!.energyKcal, 2000);
    expect(goal.proteinG, isNull);
    expect(find.text('Diario'), findsOneWidget);
  });

  testWidgets('AC1: fuera de rango muestra el error y no guarda', (
    tester,
  ) async {
    final db = await _pump(tester);
    addTearDown(db.close);

    await tester.enterText(find.byKey(const Key('goal-kcal')), '7000');
    await tester.pump();
    expect(find.text(kcalRangeMessage), findsOneWidget);

    await tester.enterText(find.byKey(const Key('goal-kcal')), '2000');
    await tester.enterText(find.byKey(const Key('goal-protein')), '45,55');
    await tester.pump();
    expect(find.text(macroRangeMessage), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(await StorageRepository(db).getNutritionGoal(), isNull);
  });

  testWidgets('AC2: macros opcionales, con coma decimal', (tester) async {
    final db = await _pump(tester);
    addTearDown(db.close);

    await tester.enterText(find.byKey(const Key('goal-kcal')), '2000');
    await tester.enterText(find.byKey(const Key('goal-protein')), '100,5');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final goal = await StorageRepository(db).getNutritionGoal();
    expect(goal!.proteinG, 100.5);
    expect(goal.carbsG, isNull);
    expect(goal.fatG, isNull);
  });

  testWidgets('AC14: 1.199 advierte y deja guardar; 1.200 no advierte', (
    tester,
  ) async {
    final db = await _pump(tester);
    addTearDown(db.close);

    await tester.enterText(find.byKey(const Key('goal-kcal')), '1199');
    await tester.pump();
    expect(find.text(lowGoalWarningMessage), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNotNull);

    await tester.enterText(find.byKey(const Key('goal-kcal')), '1200');
    await tester.pump();
    expect(find.text(lowGoalWarningMessage), findsNothing);
  });

  testWidgets('carga la meta guardada para editarla', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await StorageRepository(db)
        .saveNutritionGoal(energyKcal: 1800, proteinG: 90);

    await _pump(tester, db: db);

    expect(find.text('1800'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
  });

  testWidgets('AC8: "Borrar mis datos para la sugerencia" conserva la meta', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    await repo.saveNutritionGoal(energyKcal: 2000);
    await repo.saveGoalEstimationInputs(
      weightKg: 63,
      heightCm: 165,
      ageYears: 22,
      sex: 'female',
      activityLevel: 'lowActive',
    );

    await _pump(tester, db: db);
    await tester.tap(find.text('Borrar mis datos para la sugerencia'));
    await tester.pumpAndSettle();

    expect(await repo.getGoalEstimationInputs(), isNull);
    expect((await repo.getNutritionGoal())!.energyKcal, 2000);
    expect(find.text('Borrar mis datos para la sugerencia'), findsNothing);
  });
}
