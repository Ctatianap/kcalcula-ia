import 'dart:io';

import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:calorias_ia/infra/catalog/food_match_result.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
