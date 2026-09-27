import 'package:calorias_ia/infra/ai_client/parsed_meal_dto.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/features/review/review_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

// Mismo esquema real que data/build_catalog/lib/schema.dart.
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

  void food(String id, String name, double kcal) {
    db.execute(
      "INSERT INTO foods (id, name_es, source_id, source_ref, energy_kcal, protein_g, carbs_g, fat_g) "
      "VALUES (?, ?, 'test', 'fixture', ?, 1, 1, 1)",
      [id, name, kcal],
    );
    db.execute(
      'INSERT INTO food_search (food_id, name_es, term) VALUES (?, ?, ?)',
      [id, name, name],
    );
  }

  void synonym(String foodId, String term) {
    db.execute('INSERT INTO food_synonyms (food_id, term) VALUES (?, ?)', [
      foodId,
      term,
    ]);
    final name = db.select('SELECT name_es FROM foods WHERE id = ?', [
      foodId,
    ]).first['name_es'];
    db.execute(
      'INSERT INTO food_search (food_id, name_es, term) VALUES (?, ?, ?)',
      [foodId, name, term],
    );
  }

  void portion(String foodId, String descriptor, double grams) {
    db.execute(
      "INSERT INTO portions (food_id, descriptor, grams, source_id, source_ref) VALUES (?, ?, ?, 'test', 'fixture')",
      [foodId, descriptor, grams],
    );
  }

  food('huevo', 'Huevo', 143);
  portion('huevo', 'unidad', 50);

  // Dos alimentos comparten el sinónimo "pollo" -> ambiguous.
  food('pechuga_de_pollo', 'Pechuga de pollo', 165);
  synonym('pechuga_de_pollo', 'pollo');
  food('pollo_muslo', 'Muslo de pollo', 200);
  synonym('pollo_muslo', 'pollo');

  return CatalogRepository(db);
}

ParsedMealDto _parsedMeal() => ParsedMealDto(
  mealType: null,
  items: [
    const ParsedMealItemDto(
      mention: 'dos huevos',
      foodQuery: 'huevo',
      quantity: 2,
      unit: 'unidad',
      isVague: false,
    ),
    const ParsedMealItemDto(
      mention: 'pollo',
      foodQuery: 'pollo',
      isVague: true,
    ),
  ],
);

Future<void> _pumpReviewScreen(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  final catalog = _fixtureCatalog();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalog),
      ],
      child: MaterialApp(home: ReviewScreen(parsedMeal: _parsedMeal())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AC7: un ítem ambiguous muestra hasta 3 candidatos y deshabilita Registrar',
    (tester) async {
      await _pumpReviewScreen(tester);

      expect(find.text('Pechuga de pollo'), findsOneWidget);
      expect(find.text('Muslo de pollo'), findsOneWidget);

      final registrarButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Registrar'),
      );
      expect(registrarButton.onPressed, isNull);

      await tester.tap(find.text('Pechuga de pollo'));
      await tester.pumpAndSettle();

      final registrarButtonAfter = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Registrar'),
      );
      expect(registrarButtonAfter.onPressed, isNotNull);
    },
  );

  testWidgets(
    'AC8: editar la cantidad con +/- recalcula kcal sin llamadas de red',
    (tester) async {
      await _pumpReviewScreen(tester);

      // "dos huevos" -> 100 g -> 143 kcal.
      expect(find.text('143 kcal'), findsOneWidget);
      expect(find.text('100 g'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();

      // +5 g -> 105 g -> 143 * 1.05 = 150.15 -> 150 kcal. Sin AiClient
      // configurado (aiClientProvider no se sobrescribió): si esto llamara a
      // la red, lanzaría UnimplementedError y el test fallaría.
      expect(find.text('105 g'), findsOneWidget);
      expect(find.text('150 kcal'), findsOneWidget);
    },
  );
}
