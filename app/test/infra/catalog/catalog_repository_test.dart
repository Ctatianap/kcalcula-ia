import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:calorias_ia/infra/catalog/food_match_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/fixture_catalog.dart';

void main() {
  late CatalogRepository repo;

  setUp(() => repo = buildFixtureCatalog());
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

  group('SPEC-028: coincidencia exacta sin tildes', () {
    test('AC1: "café", "cafe" y "CAFÉ" dan matched con el café; "ñame cocido" '
        'y "name cocido" con el ñame', () {
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      for (final query in ['café', 'cafe', 'CAFÉ', '  Café ']) {
        final result = catalog.resolve(query);
        expect(result, isA<FoodMatched>(), reason: query);
        expect((result as FoodMatched).food.id, 'cafe');
      }
      for (final query in ['ñame cocido', 'name cocido', 'Ñame cocido']) {
        final result = catalog.resolve(query);
        expect(result, isA<FoodMatched>(), reason: query);
        expect((result as FoodMatched).food.id, 'name_cocido');
      }
    });

    test('AC3: si el término sin tildes es de dos alimentos, no hay matched', () {
      final db = sqlite3.openInMemory();
      for (final statement in catalogFixtureSchema) {
        db.execute(statement);
      }
      void food(String id, String name) {
        db.execute(
          'INSERT INTO foods (id, name_es, source_id, source_ref, energy_kcal, '
          "protein_g, carbs_g, fat_g) VALUES (?, ?, 'test', 'fixture', 1, 0, 0, 0)",
          [id, name],
        );
        db.execute(
          'INSERT INTO food_search (food_id, name_es, term) VALUES (?, ?, ?)',
          [id, name, name],
        );
      }

      food('papa_tilde', 'Papá de prueba');
      food('otro', 'Otro de prueba');
      db.execute(
        "INSERT INTO food_synonyms (food_id, term) VALUES ('otro', 'Papa de prueba')",
      );
      db.execute(
        "INSERT INTO food_search (food_id, name_es, term) VALUES ('otro', 'Otro de prueba', 'Papa de prueba')",
      );
      final catalog = CatalogRepository(db);
      addTearDown(catalog.close);

      for (final query in ['papa de prueba', 'papá de prueba']) {
        // R2: sin matched; sigue por FTS5 con los dos candidatos.
        final result = catalog.resolve(query);
        expect(result, isA<FoodAmbiguous>(), reason: query);
        expect((result as FoodAmbiguous).candidates.map((c) => c.id).toSet(), {
          'papa_tilde',
          'otro',
        });
      }
    });

    test(
      'Edge: un texto parcial no es coincidencia exacta y sigue por FTS',
      () {
        final catalog = buildFixtureCatalog();
        addTearDown(catalog.close);
        expect(catalog.resolve('cafe con leche'), isNot(isA<FoodMatched>()));
      },
    );
  });
}
