import 'dart:async';

import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_providers.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/crash_reporting/crash_reporting_providers.dart';
import 'package:calorias_ia/infra/legal/privacy_policy.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_crash_reporter.dart';
import 'fixture_catalog.dart';

Map<String, dynamic> parsedItem(
  String mention,
  String query, {
  double? quantity,
  String? unit,
  String? size,
  bool isVague = false,
}) => {
  'mention': mention,
  'food_query': query,
  'quantity': quantity,
  'unit': unit,
  'size': size,
  'preparation': null,
  'is_vague': isVague,
  'parent_index': null,
};

Map<String, dynamic> parsedMeal(
  List<Map<String, dynamic>> items, {
  String? mealType,
}) => {
  'schema_version': 'parsed_meal.v1',
  'meal_type': mealType,
  'items': items,
};

/// "dos huevos y una arepa" del catálogo de prueba (143 + 307 kcal).
final eggsAndArepa = parsedMeal([
  parsedItem('dos huevos', 'huevo', quantity: 2, unit: 'unidad'),
  parsedItem('una arepa', 'arepa', quantity: 1, unit: 'unidad'),
]);

/// `parseMeal` falso que registra los textos recibidos y responde con lo
/// que devuelva [respond] (puede tardar o fallar).
class FakeParseMeal {
  final FutureOr<Map<String, dynamic>> Function(String text) respond;
  final texts = <String>[];

  FakeParseMeal(this.respond);

  AiClient get client => AiClient((data) async {
    final text = data['text'] as String;
    texts.add(text);
    return respond(text);
  });
}

/// App completa con consentimiento, base en memoria y catálogo de prueba.
class MealFlowHarness {
  final AppDatabase db;
  final CatalogRepository catalog;
  final StorageRepository storage;

  MealFlowHarness._(this.db, this.catalog, [StorageRepository? storage])
    : storage = storage ?? StorageRepository(db);

  static Future<MealFlowHarness> pump(
    WidgetTester tester, {
    required AiClient aiClient,
    CatalogRepository? catalog,
    DateTime Function()? clock,

    /// Un repositorio propio (p. ej. uno que falla), también para la app.
    StorageRepository Function(AppDatabase db)? storage,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final harness = MealFlowHarness._(
      db,
      catalog ?? buildFixtureCatalog(),
      storage?.call(db),
    );
    addTearDown(() async {
      await db.close();
      harness.catalog.close();
    });
    await harness.storage.saveConsent(policyVersion: privacyPolicyVersion);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          catalogRepositoryProvider.overrideWithValue(harness.catalog),
          aiClientProvider.overrideWithValue(aiClient),
          crashReporterProvider.overrideWithValue(FakeCrashReporter()),
          if (clock != null) clockProvider.overrideWithValue(clock),
          if (storage != null)
            storageRepositoryProvider.overrideWithValue(harness.storage),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  /// Hoy → + → escribe [text] (sin tocar Analizar).
  Future<void> openCaptureAndType(WidgetTester tester, String text) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
  }
}

/// Providers mínimos para montar una pantalla suelta del flujo de registro.
class MealFlowScope extends StatelessWidget {
  final AppDatabase db;
  final CatalogRepository catalog;
  final AiClient aiClient;
  final StorageRepository? storage;
  final Widget child;

  const MealFlowScope({
    super.key,
    required this.db,
    required this.catalog,
    required this.aiClient,
    required this.child,
    this.storage,
  });

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      if (storage != null)
        storageRepositoryProvider.overrideWithValue(storage!),
      catalogRepositoryProvider.overrideWithValue(catalog),
      aiClientProvider.overrideWithValue(aiClient),
      crashReporterProvider.overrideWithValue(FakeCrashReporter()),
    ],
    child: child,
  );
}
