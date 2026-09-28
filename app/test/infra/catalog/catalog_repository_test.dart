import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:calorias_ia/infra/catalog/food_match_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

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
}
