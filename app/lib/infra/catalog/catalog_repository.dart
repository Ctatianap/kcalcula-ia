import 'package:nutrition_core/nutrition_core.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../format/text_es.dart';
import 'food_match_result.dart';

/// Máximo de candidatos que se muestran cuando un `food_query` es ambiguo
/// (R10: "hasta 3 candidatos").
const _maxAmbiguousCandidates = 3;

const _householdUnitByName = {
  'cucharada': QuantityUnit.cucharada,
  'cucharadita': QuantityUnit.cucharadita,
  'taza': QuantityUnit.taza,
  'vaso': QuantityUnit.vaso,
};

/// Consultas de solo lectura sobre `catalog.db` (generado por
/// `data/build_catalog`, esquema en `.claude/skills/nutrition-data/SKILL.md`).
class CatalogRepository {
  final Database _db;

  CatalogRepository(this._db);

  factory CatalogRepository.openFile(String path) =>
      CatalogRepository(sqlite3.open(path, mode: OpenMode.readOnly));

  void close() => _db.close();

  String get catalogVersion {
    final rows = _db.select('SELECT catalog_version FROM meta LIMIT 1');
    return rows.isEmpty
        ? 'desconocida'
        : rows.first['catalog_version'] as String;
  }

  /// R8: `matched` (coincidencia exacta/cuasi-exacta de un solo alimento,
  /// por nombre o sinónimo), `ambiguous` (1-3+ resultados de FTS5, se
  /// muestran hasta 3) o `not_found` (0 resultados).
  FoodMatchResult resolve(String foodQuery) {
    final normalized = normalizeFoodText(foodQuery);
    if (normalized.isEmpty) return FoodNotFound();

    final exactIds = _db
        .select(
          '''
          SELECT DISTINCT food_id FROM (
            SELECT id AS food_id, lower(name_es) AS term FROM foods
            UNION ALL
            SELECT food_id, lower(term) AS term FROM food_synonyms
          )
          WHERE term = ?
          ''',
          [normalized],
        )
        .map((row) => row['food_id'] as String)
        .toSet();

    if (exactIds.length == 1) {
      final food = getFoodById(exactIds.first);
      if (food != null) return FoodMatched(food);
    }

    final matchQuery = _ftsQuery(normalized);
    if (matchQuery.isEmpty) return FoodNotFound();

    final candidateIds = _db
        .select(
          'SELECT DISTINCT food_id FROM food_search WHERE food_search MATCH ? LIMIT 10',
          [matchQuery],
        )
        .map((row) => row['food_id'] as String)
        .toList();

    if (candidateIds.isEmpty) return FoodNotFound();

    final candidates = candidateIds.take(_maxAmbiguousCandidates).map((id) {
      final rows = _db.select('SELECT id, name_es FROM foods WHERE id = ?', [
        id,
      ]);
      return FoodCandidate(id: id, nameEs: rows.first['name_es'] as String);
    }).toList();
    return FoodAmbiguous(candidates);
  }

  /// SPEC-018 R1: búsqueda por nombre o sinónimo mientras se escribe (desde
  /// 2 letras), con prefijo por palabra: "arep" encuentra "Arepa", "tinto"
  /// encuentra el café. Hasta [limit] alimentos, por nombre.
  List<FoodSearchHit> search(String query, {int limit = 20}) {
    if (!isSearchableQuery(query)) return const [];
    final matchQuery = _ftsPrefixQuery(normalizeFoodText(query));
    if (matchQuery.isEmpty) return const [];
    final hits = _db
        .select(
          '''
          SELECT f.id, f.name_es, f.energy_kcal FROM foods f
          WHERE f.id IN (
            SELECT food_id FROM food_search WHERE food_search MATCH ?
          )
          ''',
          [matchQuery],
        )
        .map(
          (row) => FoodSearchHit(
            id: row['id'] as String,
            nameEs: row['name_es'] as String,
            energyKcal100g: (row['energy_kcal'] as num).toDouble(),
          ),
        )
        .toList();
    // Orden alfabético sin tildes ("Ñame" junto a la n, no al final, como
    // haría la colación binaria de SQLite).
    hits.sort(
      (a, b) =>
          normalizeFoodText(a.nameEs).compareTo(normalizeFoodText(b.nameEs)),
    );
    return hits.take(limit).toList();
  }

  FoodCatalogEntry? getFoodById(String id) {
    final foodRows = _db.select('SELECT * FROM foods WHERE id = ?', [id]);
    if (foodRows.isEmpty) return null;
    final row = foodRows.first;

    final portions = _db
        .select(
          'SELECT descriptor, grams, source_id, source_ref, is_curated_estimate '
          'FROM portions WHERE food_id = ?',
          [id],
        )
        .map(
          (p) => PortionOption(
            descriptor: p['descriptor'] as String,
            grams: (p['grams'] as num).toDouble(),
            sourceId: p['source_id'] as String,
            sourceRef: p['source_ref'] as String,
            isCuratedEstimate: (p['is_curated_estimate'] as int) == 1,
          ),
        )
        .toList();

    return FoodCatalogEntry(
      id: row['id'] as String,
      nameEs: row['name_es'] as String,
      sourceId: row['source_id'] as String,
      sourceRef: row['source_ref'] as String,
      energyKcal100g: (row['energy_kcal'] as num).toDouble(),
      proteinG100g: (row['protein_g'] as num).toDouble(),
      carbsG100g: (row['carbs_g'] as num).toDouble(),
      fatG100g: (row['fat_g'] as num).toDouble(),
      densityGPerMl: (row['density_g_per_ml'] as num?)?.toDouble(),
      portions: portions,
    );
  }

  Map<QuantityUnit, double> householdUnitMlByUnit() {
    final rows = _db.select('SELECT unit, ml FROM household_units');
    final map = <QuantityUnit, double>{};
    for (final row in rows) {
      final unit = _householdUnitByName[row['unit'] as String];
      if (unit != null) map[unit] = (row['ml'] as num).toDouble();
    }
    return map;
  }
}

/// SPEC-018 R1: se busca desde 2 letras o números (sin contar espacios ni
/// signos). Única regla para la pantalla, el resolver y el catálogo.
bool isSearchableQuery(String query) =>
    normalizeFoodText(query).replaceAll(RegExp('[^a-z0-9]'), '').length >= 2;

/// Como [_ftsQuery], pero cada término busca por prefijo (`"arep"*`).
String _ftsPrefixQuery(String normalized) {
  final tokens = normalized
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty);
  return tokens.map((t) => '"$t"*').join(' ');
}

/// Une los términos en una consulta FTS5 tipo AND, citando cada uno para
/// evitar que caracteres del texto del usuario se interpreten como sintaxis
/// de FTS5.
String _ftsQuery(String normalized) {
  final tokens = normalized
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty);
  return tokens.map((t) => '"$t"').join(' ');
}
