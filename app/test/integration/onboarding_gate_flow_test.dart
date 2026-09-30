import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/infra/crash_reporting/crash_reporting_providers.dart';
import 'package:calorias_ia/infra/legal/privacy_policy.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_crash_reporter.dart';

/// La persistencia real del consentimiento a través de cerrar y reabrir
/// `user.db` (archivo real, no en memoria) ya está cubierta a nivel de
/// repositorio en `storage_repository_test.dart` ("saveConsent persiste y
/// sobrevive a cerrar/reabrir la base (AC3, AC4)"). Aquí solo se prueba que
/// `_RootGate` (`app.dart`) elige la pantalla correcta según el estado de
/// `ConsentRecord` — mismo patrón de `NativeDatabase.memory()` que el resto
/// de los tests de integración de esta suite.
void main() {
  testWidgets(
    'AC1: primer lanzamiento sin consentimiento muestra el onboarding, no el diario',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final crashReporter = FakeCrashReporter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            crashReporterProvider.overrideWithValue(crashReporter),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Antes de empezar'), findsOneWidget);
      expect(find.text('Hoy'), findsNothing);
      // SPEC-007 R4: nunca se activa el reporte de fallos sin consentimiento.
      expect(crashReporter.collectionEnabled, isNull);

      await db.close();
    },
  );

  testWidgets(
    'AC4/AC8: con consentimiento vigente entra directo al diario y activa el reporte de fallos',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final crashReporter = FakeCrashReporter();
      await StorageRepository(db)
          .saveConsent(policyVersion: privacyPolicyVersion);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            crashReporterProvider.overrideWithValue(crashReporter),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Antes de empezar'), findsNothing);
      // SPEC-007 R5: consentimiento vigente -> se activa Crashlytics.
      expect(crashReporter.collectionEnabled, isTrue);

      await db.close();
    },
  );

  testWidgets(
    'AC7: policyVersion desactualizado vuelve a mostrar el onboarding, sin activar el reporte de fallos',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final crashReporter = FakeCrashReporter();
      // Usuario que aceptó una versión anterior de la política (antes de
      // sumar Crashlytics) — no es lo mismo que la versión vigente.
      await StorageRepository(db).saveConsent(policyVersion: 'v1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            crashReporterProvider.overrideWithValue(crashReporter),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Antes de empezar'), findsOneWidget);
      expect(find.text('Hoy'), findsNothing);
      expect(crashReporter.collectionEnabled, isNull);

      await db.close();
    },
  );

  testWidgets(
    'AC12: si activar el reporte de fallos falla, la app igual entra al diario',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final crashReporter = FakeCrashReporter(shouldThrow: true);
      await StorageRepository(db)
          .saveConsent(policyVersion: privacyPolicyVersion);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            crashReporterProvider.overrideWithValue(crashReporter),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Antes de empezar'), findsNothing);

      await db.close();
    },
  );
}
