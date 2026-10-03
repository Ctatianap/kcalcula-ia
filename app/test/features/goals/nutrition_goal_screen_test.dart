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
  // Pantalla alta: el formulario completo cabe sin que el ListView descarte
  // los campos de la meta al bajar a la sugerencia.
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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

  Future<void> openSuggestion(WidgetTester tester) async {
    await tester.tap(find.text('Calcular una sugerencia'));
    await tester.pumpAndSettle();
  }

  Future<void> fillSuggestion(WidgetTester tester, {String age = '22'}) async {
    await tester.enterText(find.byKey(const Key('estimation-weight')), '63');
    await tester.enterText(find.byKey(const Key('estimation-height')), '165');
    await tester.enterText(find.byKey(const Key('estimation-age')), age);
    await tester.pump();
    await tester.ensureVisible(find.text('Femenino'));
    await tester.tap(find.text('Femenino'));
    await tester.pump();
    await tester.ensureVisible(find.text('Algo activo'));
    await tester.tap(find.text('Algo activo'));
    await tester.pump();
  }

  testWidgets('AC15: los 4 niveles de actividad con su texto y la nota', (
    tester,
  ) async {
    final db = await _pump(tester);
    addTearDown(db.close);
    await openSuggestion(tester);

    for (final (title, subtitle) in activityLevelTexts.values) {
      expect(find.text(title), findsOneWidget);
      expect(find.text(subtitle), findsOneWidget);
    }
    expect(find.text(activityLevelNote), findsOneWidget);
  });

  testWidgets(
    'AC5: la sugerencia rellena los 4 campos con "~", muestra el aviso y no guarda',
    (tester) async {
      final db = await _pump(tester);
      addTearDown(db.close);
      final calculate = find.widgetWithText(FilledButton, 'Calcular');

      await openSuggestion(tester);
      await tester.ensureVisible(calculate);
      expect(tester.widget<FilledButton>(calculate).onPressed, isNull);

      await fillSuggestion(tester);
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      // DRI 2023: mujer, 22 años, 165 cm, 63 kg, low active → 2.275 kcal.
      // Proteína 1,11 × 63 = 69,93 g = 12,3 % < 14 % → 14 % = 79,6 g;
      // grasa 27,5 % = 69,5 g; carbohidratos el resto = 332,8 g (sobre 2.275,37 sin redondear).
      expect(find.text('2275'), findsOneWidget);
      expect(find.text('79,6'), findsOneWidget);
      expect(find.text('69,5'), findsOneWidget);
      expect(find.text('332,8'), findsOneWidget);
      expect(find.text('~'), findsNWidgets(4));
      expect(find.text(estimationDisclaimer), findsOneWidget);

      final repo = StorageRepository(db);
      expect(await repo.getNutritionGoal(), isNull);
      expect(await repo.getGoalEstimationInputs(), isNull);

      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final goal = await repo.getNutritionGoal();
      expect(goal!.energyKcal, 2275);
      expect(goal.proteinG, 79.6);
      final inputs = await repo.getGoalEstimationInputs();
      expect(inputs!.sex, 'female');
      expect(inputs.activityLevel, 'lowActive');
    },
  );

  testWidgets('editar un campo sugerido le quita el "~"', (tester) async {
    final db = await _pump(tester);
    addTearDown(db.close);
    await openSuggestion(tester);
    await fillSuggestion(tester);
    final calculate = find.widgetWithText(FilledButton, 'Calcular');
    await tester.ensureVisible(calculate);
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('goal-kcal')), '2100');
    await tester.pump();

    expect(find.text('~'), findsNWidgets(3));
  });

  testWidgets('con 18 años la sugerencia no se calcula', (tester) async {
    final db = await _pump(tester);
    addTearDown(db.close);
    await openSuggestion(tester);
    await fillSuggestion(tester, age: '18');

    expect(find.text(ageUnavailableMessage), findsOneWidget);
    final calculate = find.widgetWithText(FilledButton, 'Calcular');
    await tester.ensureVisible(calculate);
    expect(tester.widget<FilledButton>(calculate).onPressed, isNull);
  });

  testWidgets('sin usar la sugerencia no se guardan datos personales', (
    tester,
  ) async {
    final db = await _pump(tester);
    addTearDown(db.close);
    await openSuggestion(tester);
    await fillSuggestion(tester);

    await tester.enterText(find.byKey(const Key('goal-kcal')), '2000');
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(await StorageRepository(db).getGoalEstimationInputs(), isNull);
  });
}
