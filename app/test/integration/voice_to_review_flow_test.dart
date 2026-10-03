import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/features/capture/voice_input_controller.dart';
import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_providers.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/crash_reporting/crash_reporting_providers.dart';
import 'package:calorias_ia/infra/legal/privacy_policy.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/capture/fake_voice_input.dart';
import '../support/fake_crash_reporter.dart';
import '../support/fixture_catalog.dart';

void main() {
  testWidgets(
    'AC7: un resultado de voz simulado llega al mismo resultado que el mismo texto escrito',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      // SPEC-006: sin esto, MyApp muestra el onboarding en vez del diario.
      await StorageRepository(db)
          .saveConsent(policyVersion: privacyPolicyVersion);
      final catalog = buildFixtureCatalog();
      final recognizer = FakeSpeechRecognizer();
      final aiClient = AiClient((data) async {
        expect(data['text'], 'dos huevos y una arepa');
        return {
          'schema_version': 'parsed_meal.v1',
          'meal_type': null,
          'items': [
            {
              'mention': 'dos huevos',
              'food_query': 'huevo',
              'quantity': 2,
              'unit': 'unidad',
              'size': null,
              'preparation': null,
              'is_vague': false,
              'parent_index': null,
            },
            {
              'mention': 'una arepa',
              'food_query': 'arepa',
              'quantity': 1,
              'unit': 'unidad',
              'size': null,
              'preparation': null,
              'is_vague': false,
              'parent_index': null,
            },
          ],
        };
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(catalog),
            aiClientProvider.overrideWithValue(aiClient),
            microphonePermissionProvider.overrideWithValue(
              FakeMicrophonePermission(granted: true),
            ),
            speechRecognizerProvider.overrideWithValue(recognizer),
            crashReporterProvider.overrideWithValue(FakeCrashReporter()),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // En vez de escribir, se usa un resultado de voz simulado.
      await tester.tap(find.text('Voz'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      recognizer.emitResult('dos huevos y una arepa', isFinal: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // Mismo resultado que el flujo por texto (capture_to_review_flow_test.dart).
      await tester.tap(find.text('Analizar'));
      await tester.pumpAndSettle();

      expect(find.text('143 kcal'), findsOneWidget);
      expect(find.text('307 kcal'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('meal-detail-kcal'))).data,
        '~450 kcal',
      );

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Todavía no registras nada hoy'), findsNothing);
      expect(find.textContaining('450 kcal'), findsWidgets);

      await db.close();
      catalog.close();
    },
  );
}
