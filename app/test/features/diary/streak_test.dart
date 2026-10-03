import 'dart:io';

import 'package:calorias_ia/features/diary/diary_screen.dart';
import 'package:calorias_ia/features/diary/streak.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sábado 3 de octubre de 2026, 10:00.
final _now = DateTime(2026, 10, 3, 10);

DateTime _daysAgo(int n, {int hour = 13}) =>
    DateTime(_now.year, _now.month, _now.day - n, hour);

Future<void> _meal(StorageRepository repo, DateTime at) => repo.registerMeal(
  eatenAt: at,
  mealType: 'almuerzo',
  confidence: 'buenaEstimacion',
  catalogVersion: 'test-1',
  items: const [
    MealItemRecord(
      mention: 'huevo',
      foodId: 'huevo',
      nameSnapshot: 'Huevo',
      grams: 100,
      quantityBasis: 'unitPortion',
      energyKcal: 143,
      proteinG: 12.6,
      carbsG: 0.7,
      fatG: 9.5,
      confidence: 'buenaEstimacion',
      sourceRef: 'fixture',
    ),
  ],
);

Future<void> _pump(WidgetTester tester, List<DateTime> meals) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = StorageRepository(db);
  for (final at in meals) {
    await _meal(repo, at);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: const MaterialApp(home: DiaryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AC1: racha', () {
    test('hoy, ayer y anteayer → 3', () {
      expect(streakDays([_daysAgo(0), _daysAgo(1), _daysAgo(2)], _now), 3);
    });

    test(
      'ayer y anteayer (hoy vacío) → 2: no se rompe hasta que acaba el día',
      () {
        expect(streakDays([_daysAgo(1), _daysAgo(2)], _now), 2);
      },
    );

    test('hoy y anteayer (ayer vacío) → 1', () {
      expect(streakDays([_daysAgo(0), _daysAgo(2)], _now), 1);
    });

    test('sin registros → 0; solo antier → 0', () {
      expect(streakDays(const [], _now), 0);
      expect(streakDays([_daysAgo(2)], _now), 0);
    });

    test('varias comidas el mismo día cuentan una vez; fecha local', () {
      expect(
        streakDays([
          _daysAgo(0, hour: 7),
          _daysAgo(0, hour: 20),
          _daysAgo(1, hour: 23),
          _daysAgo(2, hour: 0),
        ], _now),
        3,
      );
    });

    test('cruza el cambio de mes y de año por fecha de calendario', () {
      final now = DateTime(2027, 1, 1, 9);
      expect(
        streakDays([
          DateTime(2027, 1, 1, 8),
          DateTime(2026, 12, 31, 20),
          DateTime(2026, 12, 30, 12),
        ], now),
        3,
      );
    });

    test('edge case: tope de 400 días', () {
      final meals = [for (var i = 0; i < 450; i++) _daysAgo(i)];
      expect(streakDays(meals, _now), streakLookbackDays);
    });
  });

  testWidgets('AC2: la píldora muestra el número y su etiqueta semántica', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, [_daysAgo(0), _daysAgo(1), _daysAgo(2)]);
    expect(
      tester.widget<Text>(find.byKey(const Key('streak-count'))).data,
      '3',
    );
    expect(
      find.bySemanticsLabel('3 días seguidos registrando'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('R3: con racha 0 la píldora muestra 0 sin texto adicional', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const []);
    expect(
      tester.widget<Text>(find.byKey(const Key('streak-count'))).data,
      '0',
    );
    expect(
      find.bySemanticsLabel('0 días seguidos registrando'),
      findsOneWidget,
    );
    expect(streakSemantics(1), '1 día seguido registrando');
    semantics.dispose();
  });

  test('AC3: ningún texto de la app habla de perder la racha', () {
    final pattern = RegExp(
      r'perd|romp|se acab|no pierdas|racha',
      caseSensitive: false,
    );
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('.g.dart')) continue;
      // Solo literales de texto (entre comillas), no comentarios.
      for (final m in RegExp(
        r"'[^'\n]*'",
      ).allMatches(file.readAsStringSync())) {
        if (pattern.hasMatch(m.group(0)!)) {
          offenders.add('${file.path}: ${m.group(0)}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  testWidgets('texto grande (×2) en 360 px: el encabezado con la píldora no '
      'se desborda', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, [_daysAgo(0), _daysAgo(1)]);
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('streak-pill')), findsOneWidget);
  });
}
