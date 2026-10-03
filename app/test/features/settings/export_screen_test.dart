import 'dart:io';

import 'package:calorias_ia/features/settings/export_screen.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/sharing/sharing_providers.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/export_fixtures.dart';
import 'fake_sharing_service.dart';

final _now = DateTime(2026, 10, 3, 18);

class _H {
  final StorageRepository repo;
  final FakeSharingService sharing;
  final Directory dir;

  _H(this.repo, this.sharing, this.dir);
}

Future<_H> _pump(
  WidgetTester tester, {
  Future<void> Function(StorageRepository repo)? seed,
  Size size = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = StorageRepository(db);
  if (seed != null) await seed(repo);
  final dir = Directory.systemTemp.createTempSync('kcalcula_export_screen');
  addTearDown(() => dir.deleteSync(recursive: true));
  final sharing = FakeSharingService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exportDirectoryPathProvider.overrideWithValue(dir.path),
        sharingServiceProvider.overrideWithValue(sharing),
        clockProvider.overrideWithValue(() => _now),
        pdfFontsLoaderProvider.overrideWithValue(testPdfFonts),
      ],
      child: const MaterialApp(home: ExportScreen()),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
  return _H(repo, sharing, dir);
}

/// 3 comidas en 2 días, una de hace 40 días.
Future<void> _seed(StorageRepository repo) async {
  await exportMeal(repo, DateTime(2026, 8, 24, 13), [exportItem('Viejo')]);
  await exportMeal(repo, DateTime(2026, 10, 2, 8), [exportItem('Huevo')]);
  await exportMeal(repo, DateTime(2026, 10, 2, 13), [exportItem('Arepa')]);
}

Future<void> _exportTap(WidgetTester tester) async {
  // Escribir el archivo es E/S real: fuera de la zona de tiempo simulado.
  await tester.runAsync(() async {
    await tester.tap(find.widgetWithText(FilledButton, 'Exportar'));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pumpAndSettle();
}

String _summary(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('export-summary'))).data!;

void main() {
  testWidgets('AC5: el resumen cuenta comidas y días con registros del '
      'periodo', (tester) async {
    await _pump(tester, seed: _seed);
    expect(_summary(tester), '3 comidas · 2 días');
    expect(find.text('Hoja de cálculo (CSV)'), findsOneWidget);
    expect(find.text('Resumen para imprimir (PDF)'), findsOneWidget);
    expect(find.text('Copia completa (JSON)'), findsOneWidget);
    expect(find.text(exportNote), findsOneWidget);

    await tester.tap(find.text('Últimos 30 días'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(_summary(tester), '2 comidas · 1 día');
  });

  for (final (format, label, ext) in [
    ('csv', 'Hoja de cálculo (CSV)', '.csv'),
    ('pdf', 'Resumen para imprimir (PDF)', '.pdf'),
    ('json', 'Copia completa (JSON)', '.json'),
  ]) {
    testWidgets('AC4: "Exportar" con $format entrega un archivo $ext al '
        'share sheet', (tester) async {
      final h = await _pump(tester, seed: _seed);
      await tester.tap(find.text(label));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      await _exportTap(tester);
      expect(h.sharing.sharedPath, endsWith(ext));
      expect(File(h.sharing.sharedPath!).existsSync(), isTrue);
      expect(find.text(exportReadyMessage), findsOneWidget);
    });
  }

  testWidgets('AC6: sin comidas en el periodo → mensaje y no se crea '
      'archivo', (tester) async {
    final h = await _pump(
      tester,
      seed: (repo) =>
          exportMeal(repo, DateTime(2026, 8, 24, 13), [exportItem('Viejo')]),
    );
    await tester.tap(find.text('Últimos 30 días'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(_summary(tester), noMealsInPeriodMessage);
    final button = find.widgetWithText(FilledButton, 'Exportar');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(h.sharing.sharedPath, isNull);
    expect(h.dir.listSync(), isEmpty);
  });

  testWidgets('la copia completa (JSON) ignora el periodo', (tester) async {
    await _pump(tester, seed: _seed);
    await tester.tap(find.text('Copia completa (JSON)'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Últimos 30 días'), findsNothing);
    expect(_summary(tester), '3 comidas · 2 días');
  });

  testWidgets('texto grande (×2) en 360 px sin desbordes', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, seed: _seed, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Elegir fechas" abre el selector de rango', (tester) async {
    await _pump(tester, seed: _seed);
    await tester.tap(find.text('Elegir fechas'));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    expect(find.text('Elige las fechas'), findsOneWidget);
  });
}
