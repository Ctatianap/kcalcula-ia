import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:calorias_ia/infra/catalog/food_match_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';
import 'package:sqlite3/sqlite3.dart';

// Mismo esquema que data/build_catalog/lib/schema.dart (paquete separado:
// se duplica aquí solo como fixture de test, no como build real).
const _schema = [
  'CREATE TABLE meta (catalog_version TEXT NOT NULL, built_at TEXT NOT NULL)',
  '''
  CREATE TABLE foods (
    id TEXT PRIMARY KEY, name_es TEXT NOT NULL, category TEXT,
    source_id TEXT NOT NULL, source_ref TEXT NOT NULL,
    energy_kcal REAL NOT NULL, protein_g REAL NOT NULL, carbs_g REAL NOT NULL,
    fat_g REAL NOT NULL, fiber_g REAL, sugar_g REAL, sodium_mg REAL,
    density_g_per_ml REAL, license_status TEXT NOT NULL DEFAULT 'ok',
    atwater_review INTEGER NOT NULL DEFAULT 0
  )
  ''',
  'CREATE TABLE food_synonyms (food_id TEXT NOT NULL, term TEXT NOT NULL)',
  'CREATE VIRTUAL TABLE food_search USING fts5(food_id UNINDEXED, name_es, term)',
  '''
  CREATE TABLE portions (
    food_id TEXT NOT NULL, descriptor TEXT NOT NULL, grams REAL NOT NULL,
    source_id TEXT NOT NULL, source_ref TEXT NOT NULL,
    is_curated_estimate INTEGER NOT NULL DEFAULT 0
  )
  ''',
  'CREATE TABLE household_units (unit TEXT PRIMARY KEY, ml REAL NOT NULL, source_ref TEXT NOT NULL)',
];

CatalogRepository _buildFixtureCatalog() {
  final db = sqlite3.openInMemory();
  for (final statement in _schema) {
    db.execute(statement);
  }
  db.execute(
    "INSERT INTO meta (catalog_version, built_at) VALUES ('test-1', '2026-09-27T00:00:00')",
  );

  void insertFood(String id, String nameEs, double kcal) {
    db.execute(
      'INSERT INTO foods (id, name_es, source_id, source_ref, energy_kcal, protein_g, carbs_g, fat_g) '
      "VALUES (?, ?, 'test', 'fixture', ?, 1, 1, 1)",
      [id, nameEs, kcal],
    );
    db.execute(
      'INSERT INTO food_search (food_id, name_es, term) VALUES (?, ?, ?)',
      [id, nameEs, nameEs],
    );
  }

  void insertSynonym(String foodId, String term) {
    db.execute('INSERT INTO food_synonyms (food_id, term) VALUES (?, ?)', [
      foodId,
      term,
    ]);
    final nameEs = db.select('SELECT name_es FROM foods WHERE id = ?', [
      foodId,
    ]).first['name_es'];
    db.execute(
      'INSERT INTO food_search (food_id, name_es, term) VALUES (?, ?, ?)',
      [foodId, nameEs, term],
    );
  }

  insertFood('huevo', 'Huevo', 143);
  db.execute(
    "INSERT INTO portions (food_id, descriptor, grams, source_id, source_ref) "
    "VALUES ('huevo', 'unidad', 50, 'test', 'fixture')",
  );

  insertFood('pechuga_de_pollo', 'Pechuga de pollo', 165);
  insertSynonym('pechuga_de_pollo', 'pollo');

  insertFood('pollo_muslo', 'Muslo de pollo', 200);
  insertSynonym(
    'pollo_muslo',
    'pollo',
  ); // mismo término, distinto alimento -> ambiguous

  db.execute(
    "INSERT INTO household_units (unit, ml, source_ref) VALUES ('cucharada', 15, 'fixture')",
  );

  return CatalogRepository(db);
}

void main() {
  late CatalogRepository repo;

  setUp(() => repo = _buildFixtureCatalog());
  tearDown(() => repo.close());

  test('matched: nombre exacto', () {
    final result = repo.resolve('huevo');
    expect(result, isA<FoodMatched>());
    expect((result as FoodMatched).food.id, 'huevo');
  });

  test('matched: por sinónimo único', () {
    final result = repo.resolve('pechuga de pollo');
    expect(result, isA<FoodMatched>());
    expect((result as FoodMatched).food.id, 'pechuga_de_pollo');
  });

  test('ambiguous: el mismo término apunta a 2 alimentos', () {
    final result = repo.resolve('pollo');
    expect(result, isA<FoodAmbiguous>());
    expect((result as FoodAmbiguous).candidates, hasLength(2));
  });

  test('not_found: sin ningún resultado', () {
    final result = repo.resolve('unicornio');
    expect(result, isA<FoodNotFound>());
  });

  test('getFoodById trae las porciones del alimento', () {
    final food = repo.getFoodById('huevo');
    expect(food, isNotNull);
    expect(food!.portions, hasLength(1));
    expect(food.portions.first.descriptor, 'unidad');
    expect(food.portions.first.grams, 50);
  });

  test('catalogVersion lee de meta', () {
    expect(repo.catalogVersion, 'test-1');
  });

  test('householdUnitMlByUnit mapea a QuantityUnit', () {
    final units = repo.householdUnitMlByUnit();
    expect(units[QuantityUnit.cucharada], 15);
  });
}
