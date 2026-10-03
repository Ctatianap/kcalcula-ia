import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/diary/diary_screen.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/ui/components/progress_ring.dart';
import 'package:calorias_ia/ui/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sábado 3 de octubre de 2026, 10:00 (semana: lunes 28 sep → domingo 4 oct).
final _now = DateTime(2026, 10, 3, 10);

MealItemRecord _item(
  double kcal, {
  String name = 'Huevo',
  String confidence = 'altaPrecision',
  double p = 20,
  double c = 30,
  double f = 10,
}) => MealItemRecord(
  mention: name.toLowerCase(),
  foodId: name.toLowerCase(),
  nameSnapshot: name,
  grams: 100,
  quantityBasis: 'explicitWeight',
  energyKcal: kcal,
  proteinG: p,
  carbsG: c,
  fatG: f,
  confidence: confidence,
  sourceRef: 'fixture de prueba',
);

Future<void> _meal(
  StorageRepository repo,
  DateTime at,
  double kcal, {
  String type = 'almuerzo',
  String name = 'Huevo',
  String confidence = 'altaPrecision',
}) => repo.registerMeal(
  eatenAt: at,
  mealType: type,
  confidence: confidence,
  catalogVersion: 'test-1',
  items: [_item(kcal, name: name, confidence: confidence)],
);

NutritionGoalValues _goal(double kcal) => (
  objective: 'maintain',
  isManual: false,
  energyKcal: kcal,
  proteinG: 100,
  carbsG: 275,
  fatG: 55.6,
);

Future<AppDatabase> _pump(WidgetTester tester, {AppDatabase? db}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final database = db ?? AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp(
        initialRoute: AppRoutes.today,
        routes: {
          AppRoutes.today: (_) => const DiaryScreen(),
          AppRoutes.objective: (_) =>
              const Scaffold(body: Text('Pantalla de objetivo')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return database;
}

void main() {
  testWidgets('R1: saludo y fecha', (tester) async {
    final db = await _pump(tester);
    addTearDown(db.close);
    expect(find.text('Buenos días'), findsOneWidget);
    expect(find.text('sábado 3 de octubre'), findsOneWidget);
    expect(find.byTooltip('Ajustes'), findsOneWidget);
  });

  testWidgets(
    'AC3: semana con anillos por estado; hoy resaltado; futuro sin anillo',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = StorageRepository(db);
      await repo.saveNutritionGoal(_goal(2000));
      await _meal(repo, DateTime(2026, 9, 28, 13), 1500); // lunes
      await _meal(repo, DateTime(2026, 9, 29, 13), 2300); // martes

      await _pump(tester, db: db);

      final monday = tester.widget<ProgressRing>(
        find.byKey(const Key('week-ring-28')),
      );
      expect(monday.clampedFraction, closeTo(0.75, 1e-9));
      expect(monday.color, DayGoalStatus.belowGoal.color);
      final tuesday = tester.widget<ProgressRing>(
        find.byKey(const Key('week-ring-29')),
      );
      expect(tuesday.clampedFraction, 1);
      expect(tuesday.color, DayGoalStatus.aboveGoal.color);
      expect(
        find.byKey(const Key('week-ring-30')),
        findsNothing,
      ); // sin registros
      expect(find.byKey(const Key('week-ring-4')), findsNothing); // futuro
      expect(
        find.bySemanticsLabel('lunes 28 de septiembre, Por debajo'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('sábado 3 de octubre, hoy'), findsOneWidget);
    },
  );

  testWidgets('AC4: tarjeta de kcal y anillos de macros con meta', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    await repo.saveNutritionGoal(_goal(2000));
    await _meal(repo, DateTime(2026, 10, 3, 8, 15), 893);

    await _pump(tester, db: db);

    expect(find.text('893'), findsWidgets);
    expect(find.text('/2.000'), findsOneWidget);
    expect(find.text('kcal consumidas · quedan 1.107'), findsOneWidget);
    expect(find.text('de 100 g'), findsOneWidget);
    expect(find.text('de 275 g'), findsOneWidget);
    expect(find.text('de 56 g'), findsOneWidget);
    expect(find.bySemanticsLabel('Proteína: 20 de 100 g'), findsOneWidget);
  });

  testWidgets('AC4: por encima de la meta, texto neutro', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    await repo.saveNutritionGoal(_goal(2000));
    await _meal(repo, DateTime(2026, 10, 3, 8), 2150.2);

    await _pump(tester, db: db);

    expect(
      find.text('kcal consumidas · 150 por encima de la meta'),
      findsOneWidget,
    );
  });

  testWidgets(
    'AC5: comidas de hoy en orden por hora, con tipo, hora y macros',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = StorageRepository(db);
      await _meal(repo, DateTime(2026, 10, 3, 13, 2), 496, name: 'Pechuga');
      await _meal(
        repo,
        DateTime(2026, 10, 3, 8, 15),
        397,
        type: 'desayuno',
        name: 'Arepa',
      );

      await _pump(tester, db: db);

      expect(find.text('Agregado hoy'), findsOneWidget);
      final breakfast = tester.getTopLeft(find.text('Desayuno')).dy;
      final lunch = tester.getTopLeft(find.text('Almuerzo')).dy;
      expect(breakfast, lessThan(lunch));
      expect(find.text('8:15'), findsOneWidget);
      expect(find.text('13:02'), findsOneWidget);
      expect(find.text('Arepa 100 g'), findsOneWidget);
      expect(find.text('397 kcal'), findsOneWidget);
      expect(find.text('P 20g'), findsWidgets);
    },
  );

  testWidgets('AC6: sin meta → "Calcular mi meta" y sin anillos de meta', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _meal(StorageRepository(db), DateTime(2026, 10, 3, 9), 500);

    await _pump(tester, db: db);

    expect(find.text('kcal consumidas hoy'), findsOneWidget);
    expect(find.text('Proteína'), findsNothing);
    await tester.tap(find.text('Calcular mi meta'));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla de objetivo'), findsOneWidget);
  });

  testWidgets('AC6: sin comidas hoy → estado vacío', (tester) async {
    final db = await _pump(tester);
    addTearDown(db.close);
    expect(find.text('Todavía no registras nada hoy'), findsOneWidget);
    expect(
      find.text(
        'Toca + y cuéntame qué comiste: con una foto, por texto o con tu voz.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('SPEC-008 AC12: "~" si alguna comida es estimada', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    await repo.saveNutritionGoal(_goal(2000));
    await _meal(repo, DateTime(2026, 10, 3, 9), 500, confidence: 'estimacion');

    await _pump(tester, db: db);

    expect(find.text('~500'), findsOneWidget);
  });
}
