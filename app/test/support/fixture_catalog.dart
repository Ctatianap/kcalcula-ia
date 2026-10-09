import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:sqlite3/sqlite3.dart';

/// Mismo esquema que data/build_catalog/lib/schema.dart, duplicado aquí a
/// propósito como fixture de test (no como build real).
const catalogFixtureSchema = [
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

/// Catálogo de fixtures con huevo (unidad=50g) y arepa (unidad=115g,
/// pequeno=70g) — los mismos valores reales de data/curated/foods.csv,
/// suficientes para AC1/AC7 (texto o voz -> "dos huevos y una arepa").
CatalogRepository buildFixtureCatalog({
  String catalogVersion = 'test-1',
  double eggKcal = 143,
}) {
  final db = sqlite3.openInMemory();
  for (final statement in catalogFixtureSchema) {
    db.execute(statement);
  }
  db.execute('INSERT INTO meta (catalog_version, built_at) VALUES (?, ?)', [
    catalogVersion,
    '2026-09-27T00:00:00',
  ]);

  void food(
    String id,
    String name,
    double kcal, {
    double p = 1,
    double c = 1,
    double f = 1,
    double? density,
  }) {
    db.execute(
      'INSERT INTO foods (id, name_es, source_id, source_ref, energy_kcal, protein_g, carbs_g, fat_g, density_g_per_ml) '
      "VALUES (?, ?, 'test', 'fixture', ?, ?, ?, ?, ?)",
      [id, name, kcal, p, c, f, density],
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

  food('huevo', 'Huevo', eggKcal, p: 12.56, c: 0.72, f: 9.51);
  portion('huevo', 'unidad', 50);

  food('arepa', 'Arepa', 267, p: 5.66, c: 30.47, f: 14);
  portion('arepa', 'unidad', 115);
  portion('arepa', 'pequeno', 70);

  food('pechuga_de_pollo', 'Pechuga de pollo', 165, p: 31.02, c: 0, f: 3.57);
  food('pollo_muslo', 'Muslo de pollo', 200, p: 26, c: 0, f: 10);
  synonym('pechuga_de_pollo', 'pollo');
  synonym('pollo_muslo', 'pollo');

  // SPEC-018: otra arepa y el café con su sinónimo "tinto" (valores de
  // prueba, no del catálogo real).
  food('arepa_de_queso', 'Arepa de queso', 300, p: 9, c: 30, f: 16);
  food('cafe', 'Café', 1, p: 0.1, c: 0, f: 0);
  synonym('cafe', 'tinto');
  // Orden alfabético con "Ñ" (valores de prueba).
  food('papa_cocida', 'Papa cocida', 87);
  food('name_cocido', 'Ñame cocido', 116);
  food('ahuyama_cocida', 'Ahuyama cocida', 20);
  // SPEC-020: nombre y sinónimo con "ü" (valores de prueba).
  food('pinguino_de_prueba', 'Pingüino de prueba', 50);
  synonym('pinguino_de_prueba', 'agüita de prueba');

  // SPEC-024: pan integral y arroz con densidad (valores de prueba, no del
  // catálogo real) para la corrección conversacional.
  food('pan_integral', 'Pan integral', 250);
  portion('pan_integral', 'unidad', 30);
  food('arroz_blanco', 'Arroz blanco', 130, density: 0.8);

  db.execute(
    "INSERT INTO household_units (unit, ml, source_ref) VALUES ('cucharada', 15, 'fixture')",
  );
  db.execute(
    "INSERT INTO household_units (unit, ml, source_ref) VALUES ('taza', 240, 'fixture')",
  );

  return CatalogRepository(db);
}
