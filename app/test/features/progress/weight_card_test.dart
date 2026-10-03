import 'package:calorias_ia/features/progress/progress_screen.dart';
import 'package:calorias_ia/features/progress/weight_card.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/ui/number_input_es.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 3, 18);

class _FailingWeightStorage extends StorageRepository {
  _FailingWeightStorage(super.db);

  @override
  Future<bool> logWeight({required DateTime day, required double kg}) =>
      Future.error(StateError('SqliteException: parameters: $kg'));
}

Future<StorageRepository> _pump(
  WidgetTester tester, {
  Future<void> Function(StorageRepository repo)? seed,
  StorageRepository Function(AppDatabase db)? storage,
}) async {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = StorageRepository(db);
  if (seed != null) await seed(repo);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (storage != null)
          storageRepositoryProvider.overrideWithValue(storage(db)),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: const MaterialApp(home: ProgressScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

Future<void> _logWeight(WidgetTester tester, String value) async {
  await tester.ensureVisible(find.text('Anotar peso'));
  await tester.tap(find.text('Anotar peso'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('weight-input')), value);
  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

void main() {
  test('textos del cambio de peso en tono neutro', () {
    expect(weightChangeText(-0.4), '−0,4 kg esta semana');
    expect(weightChangeText(0.3), '+0,3 kg esta semana');
    expect(weightChangeText(0.04), 'sin cambios');
    expect(formatKg(62), '62,0 kg');
  });

  testWidgets('AC1: 62,0 hoy y 62,4 hace 7 días → "62,0 kg" y "−0,4 kg esta '
      'semana", con gráfico', (tester) async {
    await _pump(
      tester,
      seed: (repo) async {
        await repo.logWeight(day: DateTime(2026, 9, 26), kg: 62.4);
        await repo.logWeight(day: DateTime(2026, 10, 3), kg: 62.0);
      },
    );
    expect(_text(tester, 'weight-latest'), '62,0 kg');
    expect(_text(tester, 'weight-change'), '−0,4 kg esta semana');
    // "Semana" va del 27 sep al 3 oct: el 26 queda fuera del gráfico, pero
    // sí cuenta para el cambio de la semana.
    expect(find.byKey(const Key('weight-chart')), findsNothing);
    expect(find.text('sábado 3 de octubre · 62,0 kg'), findsOneWidget);
    await tester.tap(find.text('Mes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weight-chart')), findsOneWidget);
    expect(find.text('sábado 26 de septiembre · 62,4 kg'), findsOneWidget);
  });

  testWidgets('AC1: un solo registro → sin cambio', (tester) async {
    await _pump(
      tester,
      seed: (repo) => repo.logWeight(day: DateTime(2026, 10, 3), kg: 62.0),
    );
    expect(_text(tester, 'weight-latest'), '62,0 kg');
    expect(find.byKey(const Key('weight-change')), findsNothing);
    expect(find.byKey(const Key('weight-chart')), findsNothing);
  });

  testWidgets('anotar peso desde la tarjeta lo guarda con la fecha de hoy', (
    tester,
  ) async {
    final repo = await _pump(tester);
    expect(find.text('Todavía no anotas tu peso.'), findsOneWidget);
    await _logWeight(tester, '62,5');
    expect(_text(tester, 'weight-latest'), '62,5 kg');
    final entries = await repo.weightEntries();
    expect(entries.single.day, DateTime(2026, 10, 3));
    expect(entries.single.weightKg, 62.5);
  });

  for (final value in ['29,9', '300,1', '62,55', 'abc']) {
    testWidgets('AC6: "$value" fuera de rango → mensaje y no se guarda', (
      tester,
    ) async {
      final repo = await _pump(tester);
      await _logWeight(tester, value);
      expect(find.text(weightRangeMessage), findsOneWidget);
      expect(find.text('Anotar peso'), findsWidgets); // el diálogo sigue
      expect(await repo.weightEntries(), isEmpty);
    });
  }

  testWidgets('R5: borrar un registro pide confirmación', (tester) async {
    final repo = await _pump(
      tester,
      seed: (repo) async {
        await repo.logWeight(day: DateTime(2026, 9, 30), kg: 62.4);
        await repo.logWeight(day: DateTime(2026, 10, 3), kg: 62.0);
      },
    );
    final delete = find.byKey(const Key('weight-delete-3-10'));
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(
      find.text('¿Borrar el peso del sábado 3 de octubre (62,0 kg)?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await repo.weightEntries(), hasLength(2));

    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(await repo.weightEntries(), hasLength(1));
    expect(_text(tester, 'weight-latest'), '62,4 kg');
  });

  testWidgets('fallo de escritura: mensaje en español, sin relanzar', (
    tester,
  ) async {
    await _pump(tester, storage: _FailingWeightStorage.new);
    await _logWeight(tester, '62');
    expect(find.text(weightSaveErrorMessage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('texto grande (×2) en 360 px sin desbordes', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    await repo.logWeight(day: DateTime(2026, 9, 26), kg: 62.4);
    await repo.logWeight(day: DateTime(2026, 10, 3), kg: 62.0);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    expect(tester.takeException(), isNull);
  });
}
