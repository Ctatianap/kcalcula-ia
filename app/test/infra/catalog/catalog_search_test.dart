import 'package:calorias_ia/format/text_es.dart';
import 'package:calorias_ia/infra/catalog/catalog_repository.dart';
import 'package:calorias_ia/infra/catalog/food_match_result.dart';
import 'package:calorias_ia/infra/food_resolution/food_query_resolver.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';

import '../../support/fixture_catalog.dart';

void main() {
  test('AC1: "arep" encuentra las arepas con sus kcal por 100 g', () {
    final catalog = buildFixtureCatalog();
    addTearDown(catalog.close);
    final hits = catalog.search('arep');
    expect(hits.map((h) => (h.nameEs, h.energyKcal100g)), [
      ('Arepa', 267.0),
      ('Arepa de queso', 300.0),
    ]);
  });

  test('AC1: "tinto" encuentra el café por sinónimo; tildes y mayúsculas da '
      'igual', () {
    final catalog = buildFixtureCatalog();
    addTearDown(catalog.close);
    expect(catalog.search('tinto').map((h) => h.id), ['cafe']);
    expect(catalog.search('CAFÉ').map((h) => h.id), ['cafe']);
    expect(catalog.search('pollo').map((h) => h.nameEs), [
      'Muslo de pollo',
      'Pechuga de pollo',
    ]);
  });

  test(
    'desde 2 letras, hasta el límite, y sin errores con caracteres de FTS',
    () {
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      expect(catalog.search('a'), isEmpty);
      expect(catalog.search('ar', limit: 1), hasLength(1));
      expect(catalog.search('"arep*'), hasLength(2));
      expect(catalog.search('chontaduro'), isEmpty);
      expect(catalog.search('" OR *'), isEmpty);
    },
  );

  test('AC6: los productos personales aparecen en la búsqueda', () async {
    final catalog = buildFixtureCatalog();
    addTearDown(catalog.close);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StorageRepository(db);
    final id = await repo.savePersonalProduct(
      nameEs: 'Arepa congelada de prueba',
      energyKcal100: 250,
      proteinG100: 5,
      carbsG100: 40,
      fatG100: 8,
      servingGrams: 80,
      sourceRef: 'etiqueta confirmada',
    );
    final resolver = FoodQueryResolver(
      catalog: catalog,
      personalProducts: await repo.getAllPersonalProducts(),
    );
    final hits = resolver.search('arepa');
    expect(hits.first.id, 'personal:$id');
    expect(hits.first.energyKcal100g, 250);
    expect(hits.map((h) => h.nameEs), contains('Arepa'));
  });

  test('una sola regla de "2 letras": sin contar espacios ni signos', () {
    expect(isSearchableQuery('a.'), isFalse);
    expect(isSearchableQuery(' a '), isFalse);
    expect(isSearchableQuery('ñu'), isTrue);
    expect(isSearchableQuery('té'), isTrue);
  });

  test('orden alfabético sin tildes ("Ñame" junto a la n, no al final)', () {
    final catalog = buildFixtureCatalog();
    addTearDown(catalog.close);
    expect(catalog.search('cocid').map((h) => h.nameEs), [
      'Ahuyama cocida',
      'Ñame cocido',
      'Papa cocida',
    ]);
  });

  group('SPEC-020: "ü" se busca como "u"', () {
    test(
      'normalizeFoodText quita tildes, "ñ" y "ü" (también en mayúscula)',
      () {
        expect(normalizeFoodText(' PINGÜINO '), 'pinguino');
        expect(normalizeFoodText('Ñame cocido'), 'name cocido');
        expect(normalizeFoodText('Café'), 'cafe');
        expect(normalizeFoodText('üa'), 'ua');
        expect(normalizeFoodText('agüü'), 'aguu');
      },
    );

    test('AC1: "pingüino", "pinguino" y "PINGÜINO" encuentran el alimento', () {
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      for (final query in ['pingüino', 'pinguino', 'PINGÜINO', 'pingü']) {
        expect(catalog.search(query).map((h) => h.id), [
          'pinguino_de_prueba',
        ], reason: query);
      }
    });

    test('AC2: resolve("agüita") y resolve("aguita") dan lo mismo', () {
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      String describe(FoodMatchResult r) => switch (r) {
        FoodMatched(:final food) => 'matched:${food.id}',
        FoodAmbiguous(:final candidates) =>
          'ambiguous:${candidates.map((c) => c.id).join(',')}',
        FoodNotFound() => 'not_found',
      };
      final withMark = describe(catalog.resolve('agüita de prueba'));
      expect(withMark, describe(catalog.resolve('aguita de prueba')));
      expect(withMark, contains('pinguino_de_prueba'));
      expect(
        describe(catalog.resolve('agüita')),
        describe(catalog.resolve('aguita')),
      );
      expect(
        describe(catalog.resolve('Pingüino de prueba')),
        describe(catalog.resolve('pinguino de prueba')),
      );
    });

    test(
      'AC3: un producto personal con "ü" aparece al buscar sin ella',
      () async {
        final catalog = buildFixtureCatalog();
        addTearDown(catalog.close);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = StorageRepository(db);
        final id = await repo.savePersonalProduct(
          nameEs: 'Yogur de agüita',
          energyKcal100: 60,
          proteinG100: 3,
          carbsG100: 8,
          fatG100: 2,
          servingGrams: 150,
          sourceRef: 'etiqueta confirmada',
        );
        final resolver = FoodQueryResolver(
          catalog: catalog,
          personalProducts: await repo.getAllPersonalProducts(),
        );
        expect(
          resolver.search('aguita').map((h) => h.id),
          contains('personal:$id'),
        );
        expect(resolver.resolve('yogur de aguita'), isNot(isA<FoodNotFound>()));
      },
    );

    test('Edge: solo "ü" no es buscable', () {
      expect(isSearchableQuery('ü'), isFalse);
      expect(isSearchableQuery('üa'), isTrue);
    });
  });
}
