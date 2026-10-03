import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/infra/crash_reporting/crash_reporting_providers.dart';
import 'package:calorias_ia/infra/legal/privacy_policy.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/ui/components/main_nav_bar.dart';
import 'package:calorias_ia/ui/licenses.dart';
import 'package:calorias_ia/ui/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:calorias_ia/features/diary/diary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_crash_reporter.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await StorageRepository(db).saveConsent(policyVersion: privacyPolicyVersion);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        crashReporterProvider.overrideWithValue(FakeCrashReporter()),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AC3: Hoy con barra; Historial con su calendario y Progreso con su estado vacío',
    (tester) async {
      await _pumpApp(tester);

      expect(find.byType(DiaryScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Historial'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-Historial')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Historial'), findsOneWidget);
      // SPEC-013: el calendario reemplaza el estado vacío provisional.
      expect(find.byKey(const Key('history-month')), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-Progreso')));
      await tester.pumpAndSettle();
      expect(
        find.text('Aquí verás tus promedios y tu progreso.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('nav-Hoy')));
      await tester.pumpAndSettle();
      expect(find.byType(DiaryScreen), findsOneWidget);
    },
  );

  testWidgets('AC3: + abre "¿Qué comiste?" desde Hoy y desde Progreso', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('nav-add')));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué comiste?'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-Progreso')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-add')));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué comiste?'), findsWidgets);
  });

  for (final tab in ['Historial', 'Progreso']) {
    testWidgets('Atrás en $tab vuelve a Hoy', (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.byKey(Key('nav-$tab')));
      await tester.pumpAndSettle();

      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(DiaryScreen), findsOneWidget);
    });
  }

  testWidgets('AC1: la app montada usa el tema nuevo', (tester) async {
    await _pumpApp(tester);
    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme.colorScheme.primary, KColors.accent);
    expect(theme.textTheme.bodyMedium?.fontFamily, kFontFamily);
    expect(theme.scaffoldBackgroundColor, KColors.background);
  });

  testWidgets('R2: la licencia de Outfit queda registrada', (tester) async {
    registerFontLicenses();
    final entries = await tester.runAsync(
      () => LicenseRegistry.licenses.toList(),
    );
    final outfit = entries!.where((e) => e.packages.contains('Outfit'));
    expect(outfit, isNotEmpty);
    final text = outfit.first.paragraphs.map((p) => p.text).join(' ');
    expect(text, contains('SIL Open Font License'));
    expect(text, contains('The Outfit Project Authors'));
  });

  testWidgets('AC6: botones de la barra ≥ 44 px con etiqueta en español', (
    tester,
  ) async {
    await _pumpApp(tester);
    for (final key in ['nav-Hoy', 'nav-Historial', 'nav-Progreso', 'nav-add']) {
      final size = tester.getSize(find.byKey(Key(key)));
      expect(size.width, greaterThanOrEqualTo(44), reason: key);
      expect(size.height, greaterThanOrEqualTo(44), reason: key);
    }
    for (final label in ['Hoy', 'Historial', 'Progreso', 'Agregar comida']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });

  for (final scale in [2.0, 3.0]) {
    for (final tab in MainTab.values) {
      testWidgets('T-021: la barra no se desborda con texto ×$scale en 360 px '
          '(${tab.name})', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              bottomNavigationBar: MainNavBar(current: tab, onAdd: () {}),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('nav-add')), findsOneWidget);
      });
    }
  }
}
