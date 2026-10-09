import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_providers.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/crash_reporting/crash_reporting_providers.dart';
import 'package:calorias_ia/infra/legal/privacy_policy.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:calorias_ia/features/diary/diary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_crash_reporter.dart';
import '../support/fixture_catalog.dart';

void main() {
  testWidgets(
    'AC1: "dos huevos y una arepa" -> 2 ítems en revisión, registrar -> aparece en Hoy',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      // SPEC-006: sin esto, MyApp muestra el onboarding en vez del diario.
      await StorageRepository(db)
          .saveConsent(policyVersion: privacyPolicyVersion);
      final catalog = buildFixtureCatalog();
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
            crashReporterProvider.overrideWithValue(FakeCrashReporter()),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Diario vacío -> capturar.
      expect(find.text('Todavía no registras nada hoy'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'dos huevos y una arepa');
      await tester.pump();
      await tester.tap(find.text('Analizar'));
      await tester.pumpAndSettle();

      // Revisión: 2 ítems, ambos matched (huevo 100g -> 143 kcal, arepa 115g -> 307 kcal).
      expect(find.text('“dos huevos”'), findsOneWidget);
      expect(find.text('“una arepa”'), findsOneWidget);
      expect(find.text('143 kcal'), findsOneWidget);
      expect(find.text('307 kcal'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('meal-detail-kcal'))).data,
        '~450 kcal',
      );

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // De vuelta en "Hoy": la comida registrada aparece con su total.
      expect(find.text('Todavía no registras nada hoy'), findsNothing);
      expect(find.textContaining('450 kcal'), findsWidgets);

      await db.close();
      catalog.close();
    },
  );

  for (final tab in ['Historial', 'Progreso']) {
    testWidgets(
      'SPEC-010: registrar con + desde $tab vuelve a Hoy con la comida',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await StorageRepository(db)
            .saveConsent(policyVersion: privacyPolicyVersion);
        final catalog = buildFixtureCatalog();
        addTearDown(catalog.close);
        final aiClient = AiClient(
          (data) async => {
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
            ],
          },
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              catalogRepositoryProvider.overrideWithValue(catalog),
              aiClientProvider.overrideWithValue(aiClient),
              crashReporterProvider.overrideWithValue(FakeCrashReporter()),
            ],
            child: const MyApp(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(Key('nav-$tab')));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'dos huevos');
        await tester.pump();
        await tester.tap(find.text('Analizar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        expect(find.byType(DiaryScreen), findsOneWidget);
        expect(find.textContaining('143 kcal'), findsWidgets);
        expect(find.text('Todavía no registras nada hoy'), findsNothing);
      },
    );
  }
}
