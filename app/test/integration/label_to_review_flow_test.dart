import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/features/capture/label_capture_controller.dart';
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

import '../features/capture/fake_image_picker.dart';
import '../support/fake_crash_reporter.dart';
import '../support/fixture_catalog.dart';

const _labelExtractionResponse = {
  'schema_version': 'label_extraction.v1',
  'product_name': 'Yogur de prueba',
  'serving_size': {'quantity': 30, 'unit': 'g'},
  'per_serving': {
    'energy_kcal': 140,
    'protein_g': 2,
    'carbs_g': 20,
    'fat_g': 6,
    'fiber_g': null,
    'sugar_g': null,
    'sodium_mg': null,
  },
  'per_100': null,
  'unreadable_fields': <String>[],
};

void main() {
  testWidgets(
    'AC5: foto -> confirmar -> "comí 45 g" -> 210 kcal, Alta precisión -> registrar',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      // SPEC-006: sin esto, MyApp muestra el onboarding en vez del diario.
      await StorageRepository(db)
          .saveConsent(policyVersion: privacyPolicyVersion);
      final catalog = buildFixtureCatalog();
      final aiClient = AiClient((data) async => {}, (data) async {
        expect(data['mime_type'], 'image/jpeg');
        return _labelExtractionResponse;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(catalog),
            aiClientProvider.overrideWithValue(aiClient),
            cameraPermissionProvider.overrideWithValue(
              FakeCameraPermission(granted: true),
            ),
            imagePickerServiceProvider.overrideWithValue(
              FakeImagePickerService(cameraResult: fakeImageBytes),
            ),
            crashReporterProvider.overrideWithValue(FakeCrashReporter()),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar etiqueta'), findsOneWidget);

      final consumedField = find.widgetWithText(
        TextField,
        '¿Cuánto comiste? (g)',
      );
      await tester.enterText(consumedField, '45');
      await tester.pump();

      final saveButton = find.widgetWithText(
        FilledButton,
        'Guardar y continuar',
      );
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Revisión: mismo pipeline que texto/voz (R8). 140 kcal * 45/30 = 210.
      // Ítem y total.
      expect(find.text('210 kcal'), findsNWidgets(2));
      expect(find.text('Alta precisión'), findsOneWidget);
      // SPEC-012 R5: la etiqueta confirmada también cuenta como fuente.
      expect(find.text('Base verificada'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('meal-detail-kcal'))).data,
        '210 kcal',
      );

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Todavía no registras nada hoy'), findsNothing);
      expect(find.textContaining('210 kcal'), findsWidgets);

      await db.close();
      catalog.close();
    },
  );

  testWidgets(
    'AC6: un producto personal ya guardado se reutiliza por nombre, sin repetir la foto',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      // SPEC-006: sin esto, MyApp muestra el onboarding en vez del diario.
      await StorageRepository(db)
          .saveConsent(policyVersion: privacyPolicyVersion);
      final catalog = buildFixtureCatalog();

      // Producto ya guardado en una sesión anterior (no se repite la foto).
      await StorageRepository(db).savePersonalProduct(
        nameEs: 'Yogur de prueba',
        energyKcal100: 140 / 30 * 100,
        proteinG100: 2 / 30 * 100,
        carbsG100: 20 / 30 * 100,
        fatG100: 6 / 30 * 100,
        servingGrams: 30,
        sourceRef: 'Etiqueta transcrita por IA y confirmada por el usuario.',
      );

      final aiClient = AiClient((data) async {
        expect(data['text'], 'comí 60 g de yogur de prueba');
        return {
          'schema_version': 'parsed_meal.v1',
          'meal_type': null,
          'items': [
            {
              'mention': '60 g de yogur de prueba',
              'food_query': 'yogur de prueba',
              'quantity': 60,
              'unit': 'g',
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

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'comí 60 g de yogur de prueba',
      );
      await tester.pump();
      await tester.tap(find.text('Analizar'));
      await tester.pumpAndSettle();

      // 140/30*100 kcal/100g * 60g = 280 kcal, sin haber tomado ninguna foto
      // en esta sesión (food_query_resolver.dart lo encontró por nombre).
      // Ítem y total.
      expect(find.text('280 kcal'), findsNWidgets(2));
      expect(find.text('Alta precisión'), findsOneWidget);

      await db.close();
      catalog.close();
    },
  );
}
