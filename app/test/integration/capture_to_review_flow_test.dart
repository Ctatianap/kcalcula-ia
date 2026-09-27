import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_providers.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

// Mismo esquema que data/build_catalog/lib/schema.dart, con los valores
// reales de huevo/arepa de data/curated/foods.csv (no inventados).
CatalogRepository _fixtureCatalog() {
  final db = sqlite3.openInMemory();
  db.execute(
    'CREATE TABLE meta (catalog_version TEXT NOT NULL, built_at TEXT NOT NULL)',
  );
  db.execute('''
    CREATE TABLE foods (
      id TEXT PRIMARY KEY, name_es TEXT NOT NULL, category TEXT,
      source_id TEXT NOT NULL, source_ref TEXT NOT NULL,
      energy_kcal REAL NOT NULL, protein_g REAL NOT NULL, carbs_g REAL NOT NULL,
      fat_g REAL NOT NULL, fiber_g REAL, sugar_g REAL, sodium_mg REAL,
      density_g_per_ml REAL, license_status TEXT NOT NULL DEFAULT 'ok',
      atwater_review INTEGER NOT NULL DEFAULT 0
    )
  ''');
  db.execute(
    'CREATE TABLE food_synonyms (food_id TEXT NOT NULL, term TEXT NOT NULL)',
  );
  db.execute(
    'CREATE VIRTUAL TABLE food_search USING fts5(food_id UNINDEXED, name_es, term)',
  );
  db.execute('''
    CREATE TABLE portions (
      food_id TEXT NOT NULL, descriptor TEXT NOT NULL, grams REAL NOT NULL,
      source_id TEXT NOT NULL, source_ref TEXT NOT NULL,
      is_curated_estimate INTEGER NOT NULL DEFAULT 0
    )
  ''');
  db.execute(
    'CREATE TABLE household_units (unit TEXT PRIMARY KEY, ml REAL NOT NULL, source_ref TEXT NOT NULL)',
  );
  db.execute("INSERT INTO meta VALUES ('test-1', '2026-09-27T00:00:00')");

  void food(String id, String name, double kcal, double p, double c, double f) {
    db.execute(
      "INSERT INTO foods (id, name_es, source_id, source_ref, energy_kcal, protein_g, carbs_g, fat_g) "
      "VALUES (?, ?, 'test', 'fixture', ?, ?, ?, ?)",
      [id, name, kcal, p, c, f],
    );
    db.execute(
      'INSERT INTO food_search (food_id, name_es, term) VALUES (?, ?, ?)',
      [id, name, name],
    );
  }

  void portion(String foodId, String descriptor, double grams) {
    db.execute(
      "INSERT INTO portions (food_id, descriptor, grams, source_id, source_ref) VALUES (?, ?, ?, 'test', 'fixture')",
      [foodId, descriptor, grams],
    );
  }

  food('huevo', 'Huevo', 143, 12.56, 0.72, 9.51);
  portion('huevo', 'unidad', 50);
  food('arepa', 'Arepa', 267, 5.66, 30.47, 14);
  portion('arepa', 'unidad', 115);
  portion('arepa', 'pequeno', 70);

  return CatalogRepository(db);
}

void main() {
  testWidgets(
    'AC1: "dos huevos y una arepa" -> 2 ítems en revisión, registrar -> aparece en Hoy',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final catalog = _fixtureCatalog();
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
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Diario vacío -> capturar.
      expect(find.text('Todavía no registras nada hoy.'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'dos huevos y una arepa');
      await tester.pump();
      await tester.tap(find.text('Analizar'));
      await tester.pumpAndSettle();

      // Revisión: 2 ítems, ambos matched (huevo 100g -> 143 kcal, arepa 115g -> 307 kcal).
      expect(find.text('dos huevos'), findsOneWidget);
      expect(find.text('una arepa'), findsOneWidget);
      expect(find.text('143 kcal'), findsOneWidget);
      expect(find.text('307 kcal'), findsOneWidget);
      expect(find.text('Total: 450 kcal'), findsOneWidget);

      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      // De vuelta en "Hoy": la comida registrada aparece con su total.
      expect(find.text('Todavía no registras nada hoy.'), findsNothing);
      expect(find.textContaining('450 kcal'), findsWidgets);

      await db.close();
      catalog.close();
    },
  );
}
