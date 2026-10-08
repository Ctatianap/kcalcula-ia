import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/history/history_screen.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 8, 12);

Future<int> _meal(
  StorageRepository repo,
  DateTime at,
  String type,
  String food,
  double kcal,
) => repo.registerMeal(
  eatenAt: at,
  mealType: type,
  confidence: 'altaPrecision',
  catalogVersion: 'test-1',
  items: [
    MealItemRecord(
      mention: food.toLowerCase(),
      foodId: food.toLowerCase(),
      nameSnapshot: food,
      grams: 100,
      quantityBasis: 'explicitWeight',
      energyKcal: kcal,
      proteinG: 5,
      carbsG: 20,
      fatG: 5,
      confidence: 'altaPrecision',
      sourceRef: 'fixture',
    ),
  ],
);

Future<({int breakfast, int snack1, int snack2})> _pump(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final ids = await tester.runAsync(() async {
    final repo = StorageRepository(db);
    return (
      breakfast: await _meal(
        repo,
        DateTime(2026, 10, 7, 8),
        'desayuno',
        'Huevo',
        300,
      ),
      snack1: await _meal(repo, DateTime(2026, 10, 7, 10), 'snack', 'Pan', 70),
      snack2: await _meal(
        repo,
        DateTime(2026, 10, 7, 16),
        'snack',
        'Fruta',
        90,
      ),
    );
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp(
        home: HistoryScreen(initialDay: DateTime(2026, 10, 7)),
        onGenerateRoute: (settings) => settings.name == AppRoutes.editMeal
            ? MaterialPageRoute(
                settings: settings,
                builder: (_) =>
                    Scaffold(body: Text('Editar (mock) ${settings.arguments}')),
              )
            : null,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ids!;
}

void main() {
  testWidgets('AC1: tocar "Desayuno" con un desayuno lo abre', (tester) async {
    final ids = await _pump(tester);
    await tester.tap(find.byKey(const Key('history-type-row-desayuno')));
    await tester.pumpAndSettle();
    expect(find.text('Editar (mock) ${ids.breakfast}'), findsOneWidget);
  });

  testWidgets('AC2: con dos snacks, una hoja para elegir', (tester) async {
    final ids = await _pump(tester);
    await tester.tap(find.byKey(const Key('history-type-row-snack')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('history-type-sheet-${ids.snack1}')), findsOneWidget);
    expect(find.byKey(Key('history-type-sheet-${ids.snack2}')), findsOneWidget);
    await tester.tap(find.byKey(Key('history-type-sheet-${ids.snack2}')));
    await tester.pumpAndSettle();
    expect(find.text('Editar (mock) ${ids.snack2}'), findsOneWidget);
  });

  testWidgets('AC3: "Almuerzo 0 kcal" no se puede tocar ni muestra ">"', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const Key('history-type-row-almuerzo')), findsNothing);
    final row = find.ancestor(
      of: find.byKey(const Key('history-type-almuerzo')),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(
        of: row.first,
        matching: find.byIcon(Icons.chevron_right),
      ),
      findsNothing,
    );
  });

  testWidgets('R4: la fila se anuncia como botón', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Desayuno, 300 kcal\. Toca para ver la comida$'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
