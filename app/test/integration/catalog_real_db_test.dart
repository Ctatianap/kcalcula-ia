import 'dart:io';

import 'package:calorias_ia/format/text_es.dart';
import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:calorias_ia/infra/catalog/food_match_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// SPEC-003 AC6: `CatalogRepository.resolve(...)` (sin cambios de código)
/// resuelve correctamente 5 `food_query` elegidos al azar entre los
/// alimentos nuevos, contra el `catalog.db` real ya regenerado (no un
/// fixture) — a diferencia del resto de tests, que usan
/// `support/fixture_catalog.dart` a propósito para no depender del build.
void main() {
  final dbPath = File('assets/catalog/catalog.db').existsSync()
      ? 'assets/catalog/catalog.db'
      : '${Directory.current.path}/assets/catalog/catalog.db';

  test('resuelve 5 food_query nuevos de SPEC-003 contra catalog.db real', () {
    final repo = CatalogRepository.openFile(dbPath);
    addTearDown(repo.close);

    const cases = {
      'mango': 'mango',
      'guayaba': 'guayaba',
      'aceite de coco': 'aceite_de_coco',
      'queso mozzarella': 'queso_mozzarella',
      'avena cocida': 'avena_cocida',
    };

    for (final entry in cases.entries) {
      final result = repo.resolve(entry.key);
      expect(
        result,
        isA<FoodMatched>(),
        reason: '"${entry.key}" debería resolver a "${entry.value}"',
      );
      expect((result as FoodMatched).food.id, entry.value);
    }
  });

  test('SPEC-028 AC2: los nombres y sinónimos con tilde, "ñ" o "ü" se '
      'reconocen directamente, con y sin marcas', () {
    final raw = sqlite3.open(dbPath, mode: OpenMode.readOnly);
    addTearDown(raw.close);
    final terms = raw.select('''
      SELECT id AS food_id, name_es AS term FROM foods
      UNION ALL
      SELECT food_id, term FROM food_synonyms
    ''');
    final marked = [
      for (final row in terms)
        if (normalizeFoodText(row['term'] as String) !=
            (row['term'] as String).trim().toLowerCase())
          (row['food_id'] as String, row['term'] as String),
    ];
    // Medición de la SPEC (2026-10-03): 32 términos con marcas.
    expect(marked.length, greaterThanOrEqualTo(32));

    final repo = CatalogRepository.openFile(dbPath);
    addTearDown(repo.close);
    for (final (foodId, term) in marked) {
      for (final query in [term, normalizeFoodText(term)]) {
        final result = repo.resolve(query);
        expect(result, isA<FoodMatched>(), reason: '"$query" → $foodId');
        expect((result as FoodMatched).food.id, foodId, reason: query);
      }
    }
  });
}
