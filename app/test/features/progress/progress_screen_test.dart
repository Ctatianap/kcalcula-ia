import 'package:calorias_ia/features/progress/progress_screen.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sábado 3 de octubre de 2026: la "Semana" va del domingo 27 al sábado 3.
final _now = DateTime(2026, 10, 3, 18);

Future<void> _meal(
  StorageRepository repo,
  DateTime at,
  double kcal, {
  double p = 100,
  double c = 200,
  double f = 60,
}) => repo.registerMeal(
  eatenAt: at,
  mealType: 'almuerzo',
  confidence: 'altaPrecision',
  catalogVersion: 'test-1',
  items: [
    MealItemRecord(
      mention: 'x',
      foodId: 'x',
      nameSnapshot: 'X',
      grams: 100,
      quantityBasis: 'explicitWeight',
      energyKcal: kcal,
      proteinG: p,
      carbsG: c,
      fatG: f,
      confidence: 'altaPrecision',
      sourceRef: 'fixture',
    ),
  ],
);

/// Seis días con registros en la semana (el 30 sin registros), meta 2.000.
Future<void> _seedWeek(StorageRepository repo, {bool withGoal = true}) async {
  for (final (day, kcal) in [
    (DateTime(2026, 9, 27, 13), 1900.0),
    (DateTime(2026, 9, 28, 13), 2300.0),
    (DateTime(2026, 9, 29, 13), 1500.0),
    (DateTime(2026, 10, 1, 13), 2000.0),
    (DateTime(2026, 10, 2, 13), 2100.0),
    (DateTime(2026, 10, 3, 13), 1700.0),
  ]) {
    await _meal(repo, day, kcal);
  }
  if (withGoal) {
    await repo.saveNutritionGoal((
      objective: 'maintain',
      isManual: true,
      energyKcal: 2000,
      proteinG: 100,
      carbsG: 250,
      fatG: 60,
    ));
  }
}

Future<void> _pump(
  WidgetTester tester,
  Future<void> Function(StorageRepository repo) seed, {
  Size size = const Size(1080, 3000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await seed(StorageRepository(db));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: const MaterialApp(home: ProgressScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('AC3: semana con 6 días: 7 posiciones, promedio, "N de 6 días '
      'en meta" y "meta 2.000"', (tester) async {
    await _pump(tester, _seedWeek);
    expect(find.text('Promedio diario'), findsOneWidget);
    // (1.900 + 2.300 + 1.500 + 2.000 + 2.100 + 1.700) / 6 = 1.916,67.
    expect(_text(tester, 'progress-average'), '1.917 kcal');
    expect(_text(tester, 'progress-days-on-goal'), '3 de 6 días en meta');
    expect(_text(tester, 'progress-goal'), 'meta 2.000');
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('progress-bar-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('progress-bar-7')), findsNothing);
    expect(find.byKey(const Key('progress-goal-line')), findsOneWidget);
    // R5: macros con la misma regla (100 / 200 / 60 g por día).
    expect(_text(tester, 'progress-macro-protein'), '100,0 g');
    expect(_text(tester, 'progress-macro-carbs'), '200,0 g');
    expect(_text(tester, 'progress-macro-fat'), '60,0 g');
  });

  testWidgets('AC6: cada barra lleva su valor como etiqueta semántica', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _seedWeek);
    expect(
      find.bySemanticsLabel('domingo 27 de septiembre: 1.900 kcal, en tu meta'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('lunes 28 de septiembre: 2.300 kcal, por encima'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('miércoles 30 de septiembre: sin registros'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('AC4: "Mes" agrupa por semanas de lunes a domingo con el '
      'promedio diario de cada una', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _seedWeek);
    await tester.tap(find.text('Mes'));
    await tester.pumpAndSettle();
    // Del 4 de septiembre al 3 de octubre: semanas desde el lunes 31 ago.
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(Key('progress-bar-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('progress-bar-5')), findsNothing);
    expect(
      find.bySemanticsLabel(
        'Semana del 21 de septiembre: 1.900 kcal de promedio diario, en tu '
        'meta',
      ),
      findsOneWidget,
    );
    // 28 sep–3 oct: (2.300 + 1.500 + 2.000 + 2.100 + 1.700) / 5 = 1.920.
    expect(
      find.bySemanticsLabel(
        'Semana del 28 de septiembre: 1.920 kcal de promedio diario, en tu '
        'meta',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Semana del 31 de agosto: sin registros'),
      findsOneWidget,
    );

    await tester.tap(find.text('3 meses'));
    await tester.pumpAndSettle();
    // Del 6 de julio (lunes) al 3 de octubre: 13 semanas.
    expect(find.byKey(const Key('progress-bar-12')), findsOneWidget);
    expect(find.byKey(const Key('progress-bar-13')), findsNothing);
    semantics.dispose();
  });

  testWidgets('AC5: sin registros en el periodo → mensaje, sin gráfico ni '
      'promedios', (tester) async {
    await _pump(tester, (repo) async {
      // Un registro de hace 2 meses: fuera de "Semana" y "Mes".
      await _meal(repo, DateTime(2026, 8, 1, 13), 1800);
    });
    expect(find.text(noRecordsInPeriodMessage), findsOneWidget);
    expect(find.byKey(const Key('progress-bar-0')), findsNothing);
    expect(find.text('Promedio diario'), findsNothing);
    await tester.tap(find.text('3 meses'));
    await tester.pumpAndSettle();
    expect(_text(tester, 'progress-average'), '1.800 kcal');
  });

  testWidgets('AC5: sin meta → sin días en meta ni línea de meta', (
    tester,
  ) async {
    await _pump(tester, (repo) => _seedWeek(repo, withGoal: false));
    expect(_text(tester, 'progress-average'), '1.917 kcal');
    expect(find.byKey(const Key('progress-days-on-goal')), findsNothing);
    expect(find.byKey(const Key('progress-goal')), findsNothing);
    expect(find.byKey(const Key('progress-goal-line')), findsNothing);
  });

  testWidgets('texto grande (×2) en 360 px sin desbordes', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, _seedWeek, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('3 meses'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
