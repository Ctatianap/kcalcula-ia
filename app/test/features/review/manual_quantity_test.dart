import 'package:calorias_ia/features/review/manual_quantity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../support/fixture_catalog.dart';

void main() {
  test('AC2: huevo con 2 unidades → 100 g, como nutrition_core', () {
    final catalog = buildFixtureCatalog();
    addTearDown(catalog.close);
    final egg = catalog.getFoodById('huevo')!;
    final options = quantityOptionsFor(egg, catalog.householdUnitMlByUnit());
    expect(options.map((o) => o.key), ['unidad', 'gramos']);
    final item = manualDraftItem(egg, options.first, 2, const {})!;
    expect(item.grams, 100);
    expect(item.basis, QuantityBasis.unitPortion);
    expect(item.confidence, ConfidenceLevel.buenaEstimacion);
    expect((item.quantityInput, item.unitInput), (2.0, 'unidad'));
  });

  test('gramos: peso explícito; tamaños de la arepa; cantidad inválida', () {
    final catalog = buildFixtureCatalog();
    addTearDown(catalog.close);
    final arepa = catalog.getFoodById('arepa')!;
    final options = quantityOptionsFor(arepa, catalog.householdUnitMlByUnit());
    expect(options.map((o) => o.key), ['unidad', 'pequeno', 'gramos']);
    final small = options.firstWhere((o) => o.key == 'pequeno');
    final smallItem = manualDraftItem(arepa, small, 1, const {})!;
    expect(smallItem.grams, 70);
    expect(smallItem.confidence, ConfidenceLevel.estimacion);
    final grams = options.last;
    final gramsItem = manualDraftItem(arepa, grams, 85, const {})!;
    expect(gramsItem.basis, QuantityBasis.explicitWeight);
    expect(gramsItem.unitInput, 'g');
    expect(manualDraftItem(arepa, grams, 0, const {}), isNull);
  });

  test('edge case: alimento sin porciones → solo gramos', () {
    final catalog = buildFixtureCatalog();
    addTearDown(catalog.close);
    final chicken = catalog.getFoodById('pechuga_de_pollo')!;
    expect(
      quantityOptionsFor(
        chicken,
        catalog.householdUnitMlByUnit(),
      ).map((o) => o.key),
      ['gramos'],
    );
  });
}
