import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Antes de empezar'), findsOneWidget);
      expect(find.text('Hoy'), findsNothing);

      await db.close();
    },
  );

  testWidgets(
    'AC4: con consentimiento ya guardado entra directo al diario, sin mostrar el onboarding',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await StorageRepository(db).saveConsent(policyVersion: 'v1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
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
