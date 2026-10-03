import 'package:calorias_ia/features/history/history_controller.dart';
import 'package:calorias_ia/features/history/history_screen.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/ui/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/meal_flow_harness.dart';

/// Martes 29 de septiembre de 2026: el 30 es futuro.
final _now = DateTime(2026, 9, 29, 10);

MealItemRecord _item(double kcal) => MealItemRecord(
  mention: 'huevo',
  foodId: 'huevo',
  nameSnapshot: 'Huevo',
  grams: 100,
  quantityBasis: 'explicitWeight',
  energyKcal: kcal,
  proteinG: 10,
  carbsG: 20,
  fatG: 5,
  confidence: 'buenaEstimacion',
  sourceRef: 'fixture de prueba',
);

Future<void> _meal(
  StorageRepository repo,
  DateTime at,
  double kcal, {
  String type = 'almuerzo',
}) => repo.registerMeal(
  eatenAt: at,
  mealType: type,
  confidence: 'buenaEstimacion',
  catalogVersion: 'test-1',
  items: [_item(kcal)],
);

/// 26: 1.538 kcal (en la meta de 1.640); 28: 1.900 (por encima); 27 sin
/// registros; 15 de agosto: 1.000.
Future<void> _seed(StorageRepository repo, {bool withGoal = true}) async {
  await _meal(repo, DateTime(2026, 9, 26, 8), 400, type: 'desayuno');
  await _meal(repo, DateTime(2026, 9, 26, 13), 738);
  await _meal(repo, DateTime(2026, 9, 26, 20), 400, type: 'cena');
  await _meal(repo, DateTime(2026, 9, 28, 13), 1900);
  await _meal(repo, DateTime(2026, 8, 15, 13), 1000);
  if (withGoal) {
    await repo.saveNutritionGoal((
      objective: 'maintain',
      isManual: true,
      energyKcal: 1640,
      proteinG: 100,
      carbsG: 200,
      fatG: 50,
    ));
  }
}

Future<StorageRepository> _pump(
  WidgetTester tester, {
  bool withGoal = true,
  StorageRepository Function(AppDatabase db)? storage,
}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = StorageRepository(db);
  await _seed(repo, withGoal: withGoal);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (storage != null)
          storageRepositoryProvider.overrideWithValue(storage(db)),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: const MaterialApp(home: HistoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

BoxDecoration _decoration(WidgetTester tester, int day) =>
    tester.widget<Container>(find.byKey(Key('history-day-$day'))).decoration!
        as BoxDecoration;

Color? _borderColor(WidgetTester tester, int day) =>
    (_decoration(tester, day).border as Border?)?.top.color;

class _FailOnceStorage extends StorageRepository {
  var _failed = false;

  _FailOnceStorage(super.db);

  @override
  Future<List<MealWithItems>> mealsBetween(DateTime start, DateTime end) {
    if (!_failed) {
      _failed = true;
      throw StateError('SqliteException');
    }
    return super.mealsBetween(start, end);
  }
}

void main() {
  testWidgets('AC1: días con su color de estado, sin color sin registros y '
      'futuros sin acción', (tester) async {
    await _pump(tester);
    expect(find.text('septiembre 2026'), findsOneWidget);
    expect(_borderColor(tester, 26), DayGoalStatus.onGoal.color);
    expect(_borderColor(tester, 28), DayGoalStatus.aboveGoal.color);
    expect(_borderColor(tester, 27), isNull);
    expect(_decoration(tester, 27).color, isNull);
    // Leyenda sin rojo ni verde, y la nota de la meta actual.
    expect(find.text('En tu meta'), findsOneWidget);
    expect(find.text('Por debajo'), findsOneWidget);
    expect(find.text('Por encima'), findsOneWidget);
    expect(find.text('Comparado con tu meta actual'), findsOneWidget);

    // El 30 es futuro: no se puede tocar.
    final future = tester.widget<InkWell>(
      find.ancestor(
        of: find.byKey(const Key('history-day-30')),
        matching: find.byType(InkWell),
      ),
    );
    expect(future.onTap, isNull);
    // Por defecto, hoy (29) seleccionado y sin registros.
    expect(find.text('martes 29 de septiembre'), findsOneWidget);
    expect(find.text('Sin registros este día.'), findsOneWidget);
  });

  testWidgets('AC2: tocar el 26 muestra fecha, % de la meta, kcal y totales '
      'por tipo de comida', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('history-day-26')));
    await tester.pumpAndSettle();
    expect(find.text('sábado 26 de septiembre'), findsOneWidget);
    expect(find.text('94 % de tu meta'), findsOneWidget);
    expect(find.text('~1.538 de 1.640 kcal'), findsOneWidget);
    // El estado también en texto, no solo en color.
    expect(
      tester.widget<Text>(find.byKey(const Key('history-status'))).data,
      'En tu meta',
    );
    String typeKcal(String type) =>
        tester.widget<Text>(find.byKey(Key('history-type-$type'))).data!;
    expect(typeKcal('desayuno'), '400 kcal');
    expect(typeKcal('almuerzo'), '738 kcal');
    expect(typeKcal('cena'), '400 kcal');
    expect(typeKcal('snack'), '0 kcal');
    // Las comidas del día, como en Hoy.
    expect(find.text('Desayuno'), findsNWidgets(2));
    expect(find.text('13:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-day-28')));
    await tester.pumpAndSettle();
    expect(find.text('116 % de tu meta'), findsOneWidget);
  });

  testWidgets('AC3: "Mes anterior" muestra agosto con sus registros; "Mes '
      'siguiente" deshabilitado en el mes actual', (tester) async {
    await _pump(tester);
    IconButton next() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right),
        matching: find.byType(IconButton),
      ),
    );
    expect(next().onPressed, isNull);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('agosto 2026'), findsOneWidget);
    expect(_borderColor(tester, 15), DayGoalStatus.belowGoal.color);
    expect(next().onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('history-day-15')));
    await tester.pumpAndSettle();
    expect(find.text('sábado 15 de agosto'), findsOneWidget);
    expect(find.text('61 % de tu meta'), findsOneWidget);

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('septiembre 2026'), findsOneWidget);
    expect(next().onPressed, isNull);
  });

  testWidgets('AC4: sin meta, un solo color neutro y sin porcentaje', (
    tester,
  ) async {
    await _pump(tester, withGoal: false);
    expect(_borderColor(tester, 26), KColors.textSecondary);
    expect(_borderColor(tester, 28), KColors.textSecondary);
    expect(_decoration(tester, 26).color, KColors.surface);
    expect(find.text('Comparado con tu meta actual'), findsNothing);
    await tester.tap(find.byKey(const Key('history-day-26')));
    await tester.pumpAndSettle();
    expect(find.textContaining('% de tu meta'), findsNothing);
    expect(find.text('~1.538 kcal'), findsOneWidget);
  });

  testWidgets('edge case: grilla desde el lunes (septiembre 2026 empieza en '
      'martes)', (tester) async {
    await _pump(tester);
    final first = tester.getCenter(find.byKey(const Key('history-day-1')));
    final tuesday = tester.getCenter(find.text('M'));
    final monday = tester.getCenter(find.text('L'));
    expect((first.dx - tuesday.dx).abs(), lessThan(1));
    expect(first.dx, greaterThan(monday.dx));
  });

  testWidgets('edge case: error de lectura → mensaje y Reintentar', (
    tester,
  ) async {
    await _pump(tester, storage: _FailOnceStorage.new);
    expect(
      find.text('No pude leer tus datos. Intenta de nuevo.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('septiembre 2026'), findsOneWidget);
  });

  testWidgets('AC5: desde la semana de "Hoy", tocar un día abre el Historial '
      'en ese día', (tester) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => eggsAndArepa).client,
      clock: () => _now,
    );
    await _meal(h.storage, DateTime(2026, 9, 28, 13), 1900);
    await tester.tap(find.byKey(const Key('week-day-28')));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('lunes 28 de septiembre'), findsOneWidget);
    expect(find.text('~1.900 kcal'), findsOneWidget);
  });

  testWidgets('texto grande (×2) en 360 px sin desbordes', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _seed(StorageRepository(db));
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => _now),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-day-26')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('accesibilidad: cada día del calendario expone la acción de '
      'tocar y mide al menos 44 px de alto', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    final node = tester.getSemantics(
      find.bySemanticsLabel('sábado 26 de septiembre, En tu meta'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(
      find.semantics.byLabel('sábado 26 de septiembre, En tu meta'),
    );
    await tester.pumpAndSettle();
    expect(find.text('sábado 26 de septiembre'), findsOneWidget);
    final future = tester.getSemantics(
      find.bySemanticsLabel('miércoles 30 de septiembre'),
    );
    expect(future.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    final cell = tester.getSize(
      find.ancestor(
        of: find.byKey(const Key('history-day-26')),
        matching: find.byType(InkWell),
      ),
    );
    expect(cell.height, greaterThanOrEqualTo(44));
    semantics.dispose();
  });

  testWidgets('accesibilidad: un día de la semana de Hoy expone la acción y '
      'abre el Historial', (tester) async {
    final semantics = tester.ensureSemantics();
    await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => eggsAndArepa).client,
      clock: () => _now,
    );
    final finder = find.bySemanticsLabel(
      'lunes 28 de septiembre, sin registros',
    );
    expect(
      tester
          .getSemantics(finder)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    tester.semantics.tap(
      find.semantics.byLabel('lunes 28 de septiembre, sin registros'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('lunes 28 de septiembre'), findsOneWidget);
    semantics.dispose();
  });

  test('una comida sin tipo cuenta como snack en los totales', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    await repo.registerMeal(
      eatenAt: DateTime(2026, 9, 26, 16),
      mealType: null,
      confidence: 'buenaEstimacion',
      catalogVersion: 'test-1',
      items: [_item(250)],
    );
    final month = await loadHistoryMonth(repo, DateTime(2026, 9));
    expect(month.days[26]!.byMealType['snack']!.energyKcal, 250);
  });
}
