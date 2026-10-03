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
}
