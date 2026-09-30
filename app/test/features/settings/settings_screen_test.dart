import 'dart:convert';
import 'dart:io';

import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/settings/settings_screen.dart';
import 'package:calorias_ia/infra/crash_reporting/crash_reporting_providers.dart';
import 'package:calorias_ia/infra/sharing/sharing_providers.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_crash_reporter.dart';
import 'fake_sharing_service.dart';

MealItemRecord _egg() => const MealItemRecord(
  mention: 'dos huevos',
  foodId: 'huevo',
  nameSnapshot: 'Huevo',
  grams: 100,
  quantityBasis: 'unitPortion',
  energyKcal: 143,
  proteinG: 12.6,
  carbsG: 0.7,
  fatG: 9.5,
  confidence: 'buenaEstimacion',
  sourceRef: 'fixture de prueba',
);

class _Harness {
  final AppDatabase db;
  final Directory exportDir;
  final FakeSharingService sharing;
  final FakeCrashReporter crashReporter;

  _Harness({
    required this.db,
    required this.exportDir,
    required this.sharing,
    required this.crashReporter,
  });
}

Future<_Harness> _pump(
  WidgetTester tester, {
  bool sharingShouldThrow = false,
  bool crashReporterShouldThrow = false,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final exportDir = Directory.systemTemp.createTempSync('calorias_ia_export');
  final sharing = FakeSharingService(shouldThrow: sharingShouldThrow);
  final crashReporter = FakeCrashReporter(
    shouldThrow: crashReporterShouldThrow,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exportDirectoryPathProvider.overrideWithValue(exportDir.path),
        sharingServiceProvider.overrideWithValue(sharing),
        crashReporterProvider.overrideWithValue(crashReporter),
      ],
      child: MaterialApp(
        initialRoute: AppRoutes.settings,
        routes: {
          AppRoutes.settings: (_) => const SettingsScreen(),
          AppRoutes.diary: (_) =>
              const Scaffold(body: Text('Pantalla del diario')),
          AppRoutes.privacyPolicy: (_) =>
              const Scaffold(body: Text('Política completa')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(
    db: db,
    exportDir: exportDir,
    sharing: sharing,
    crashReporter: crashReporter,
  );
}

void main() {
  testWidgets('AC5: cancelar el diálogo de borrar no borra nada', (
    tester,
  ) async {
    final h = await _pump(tester);
    await StorageRepository(h.db).registerMeal(
      eatenAt: DateTime(2026, 9, 27, 8),
      mealType: 'desayuno',
      confidence: 'buenaEstimacion',
      catalogVersion: 'test-1',
      items: [_egg()],
    );

    await tester.tap(find.text('Borrar todos mis datos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    final meals = await StorageRepository(h.db)
        .mealsForDay(DateTime(2026, 9, 27));
    expect(meals, hasLength(1));

    await h.db.close();
    h.exportDir.deleteSync(recursive: true);
  });

  testWidgets('AC6: confirmar borra todos los datos del usuario', (
    tester,
  ) async {
    final h = await _pump(tester);
    await StorageRepository(h.db).registerMeal(
      eatenAt: DateTime(2026, 9, 27, 8),
      mealType: 'desayuno',
      confidence: 'buenaEstimacion',
      catalogVersion: 'test-1',
      items: [_egg()],
    );

    await tester.tap(find.text('Borrar todos mis datos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar todo'));
    await tester.pumpAndSettle();

    final meals = await StorageRepository(h.db)
        .mealsForDay(DateTime(2026, 9, 27));
    expect(meals, isEmpty);

    await h.db.close();
    h.exportDir.deleteSync(recursive: true);
  });

  testWidgets(
    'AC7, AC9: exportar entrega un JSON válido al servicio de compartir, sin metadatos de red',
    (tester) async {
      final h = await _pump(tester);
      await StorageRepository(h.db).registerMeal(
        eatenAt: DateTime(2026, 9, 27, 8),
        mealType: 'desayuno',
        confidence: 'buenaEstimacion',
        catalogVersion: 'test-1',
        items: [_egg()],
      );

      // Escribir el JSON a disco es E/S real (dart:io). Dentro de la zona de
      // tiempo simulado de los widget tests, esperar directamente esa
      // Future se cuelga — `runAsync` corre el tap y la espera fuera de esa
      // zona para que la E/S real termine de verdad.
      await tester.runAsync(() async {
        await tester.tap(find.text('Exportar mis datos'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(h.sharing.sharedPath, isNotNull);
      final file = File(h.sharing.sharedPath!);
      expect(file.existsSync(), isTrue);

      final json = jsonDecode(file.readAsStringSync()) as Map;
      final meals = json['meals'] as List;
      expect(meals, hasLength(1));
      expect((meals.first as Map)['mealType'], 'desayuno');

      final flat = file.readAsStringSync();
      expect(flat.contains('token'), isFalse);
      expect(flat.contains('appCheck'), isFalse);

      await h.db.close();
      h.exportDir.deleteSync(recursive: true);
    },
  );

  testWidgets(
    'Edge case: si el share sheet falla, muestra un error en español (no revienta)',
    (tester) async {
      final h = await _pump(tester, sharingShouldThrow: true);
      await StorageRepository(h.db).registerMeal(
        eatenAt: DateTime(2026, 9, 27, 8),
        mealType: 'desayuno',
        confidence: 'buenaEstimacion',
        catalogVersion: 'test-1',
        items: [_egg()],
      );

      await tester.runAsync(() async {
        await tester.tap(find.text('Exportar mis datos'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('Ocurrió un error. Intenta de nuevo.'), findsOneWidget);
      // Sigue en Ajustes, no se cayó la pantalla.
      expect(find.text('Ajustes'), findsOneWidget);

      await h.db.close();
      h.exportDir.deleteSync(recursive: true);
    },
  );

  testWidgets('AC13: cancelar el diálogo de revocar no cambia nada', (
    tester,
  ) async {
    final h = await _pump(tester);
    await StorageRepository(h.db).saveConsent(policyVersion: 'v1');

    await tester.tap(find.text('Revocar consentimiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(await StorageRepository(h.db).getConsentState(), isNotNull);
    expect(find.text('Ajustes'), findsOneWidget);

    await h.db.close();
    h.exportDir.deleteSync(recursive: true);
  });

  testWidgets(
    'AC14: confirmar revocar limpia el consentimiento, navega al gate, y no toca meals',
    (tester) async {
      final h = await _pump(tester);
      await StorageRepository(h.db).saveConsent(policyVersion: 'v1');
      await StorageRepository(h.db).registerMeal(
        eatenAt: DateTime(2026, 9, 27, 8),
        mealType: 'desayuno',
        confidence: 'buenaEstimacion',
        catalogVersion: 'test-1',
        items: [_egg()],
      );

      await tester.tap(find.text('Revocar consentimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revocar'));
      await tester.pumpAndSettle();

      expect(await StorageRepository(h.db).getConsentState(), isNull);
      expect(find.text('Pantalla del diario'), findsOneWidget);
      final meals = await StorageRepository(h.db)
          .mealsForDay(DateTime(2026, 9, 27));
      expect(meals, hasLength(1));
      // SPEC-007 AC6: revocar también apaga el reporte de fallos.
      expect(h.crashReporter.collectionEnabled, isFalse);

      await h.db.close();
      h.exportDir.deleteSync(recursive: true);
    },
  );

  testWidgets(
    'AC12: si desactivar el reporte de fallos falla, la revocación igual se completa',
    (tester) async {
      final h = await _pump(tester, crashReporterShouldThrow: true);
      await StorageRepository(h.db).saveConsent(policyVersion: 'v1');

      await tester.tap(find.text('Revocar consentimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revocar'));
      await tester.pumpAndSettle();

      // El consentimiento se borró de verdad y navegó al gate, pese a que
      // el crash reporter lanzó una excepción al desactivarse.
      expect(await StorageRepository(h.db).getConsentState(), isNull);
      expect(find.text('Pantalla del diario'), findsOneWidget);
      expect(find.text('Ocurrió un error. Intenta de nuevo.'), findsNothing);

      await h.db.close();
      h.exportDir.deleteSync(recursive: true);
    },
  );

  testWidgets('el enlace a la política completa navega a esa pantalla', (
    tester,
  ) async {
    final h = await _pump(tester);

    await tester.tap(find.text('Ver política de privacidad completa'));
    await tester.pumpAndSettle();

    expect(find.text('Política completa'), findsOneWidget);

    await h.db.close();
    h.exportDir.deleteSync(recursive: true);
  });
}
