/// Esquema de `catalog.db`, tal como lo define
/// `.claude/skills/nutrition-data/SKILL.md`. `atwater_review` es la única
/// extensión: marca filas fuera de ±20% Atwater que se aceptan
/// explícitamente en vez de bloquear el build.
const List<String> catalogSchemaStatements = [
  '''
  CREATE TABLE meta (
    catalog_version TEXT NOT NULL,
    built_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE sources (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    license TEXT NOT NULL,
    url TEXT NOT NULL,
    version TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE foods (
    id TEXT PRIMARY KEY,
    name_es TEXT NOT NULL,
    category TEXT,
    source_id TEXT NOT NULL,
    source_ref TEXT NOT NULL,
    energy_kcal REAL NOT NULL,
    protein_g REAL NOT NULL,
    carbs_g REAL NOT NULL,
    fat_g REAL NOT NULL,
    fiber_g REAL,
    sugar_g REAL,
    sodium_mg REAL,
    density_g_per_ml REAL,
    license_status TEXT NOT NULL DEFAULT 'ok',
    atwater_review INTEGER NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE food_synonyms (
    food_id TEXT NOT NULL REFERENCES foods(id),
    term TEXT NOT NULL
  )
  ''',
  '''
  CREATE VIRTUAL TABLE food_search USING fts5(
    food_id UNINDEXED,
    name_es,
    term
  )
  ''',
  '''
  CREATE TABLE portions (
    food_id TEXT NOT NULL REFERENCES foods(id),
    descriptor TEXT NOT NULL,
    grams REAL NOT NULL,
    source_id TEXT NOT NULL,
    source_ref TEXT NOT NULL,
    is_curated_estimate INTEGER NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE household_units (
    unit TEXT PRIMARY KEY,
    ml REAL NOT NULL,
    source_ref TEXT NOT NULL
  )
  ''',
];
