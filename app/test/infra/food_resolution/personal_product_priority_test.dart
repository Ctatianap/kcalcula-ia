import 'package:calorias_ia/infra/catalog/food_match_result.dart';
import 'package:calorias_ia/infra/food_resolution/food_query_resolver.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';

/// SPEC-034 R4: el nombre exacto o un alias de un producto personal gana
/// sobre el catálogo.
void main() {
  late AppDatabase db;
  late StorageRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StorageRepository(db);
  });
  tearDown(() => db.close());

  Future<int> product(String name) => repo.savePersonalProduct(
    nameEs: name,
    energyKcal100: 260,
    proteinG100: 9,
    carbsG100: 48,
    fatG100: 3,
    servingGrams: 27,
    sourceRef: 'test',
  );

  Future<FoodQueryResolver> resolver() async => FoodQueryResolver(
    catalog: buildFixtureCatalog(),
    personalProducts: await repo.getAllPersonalProducts(),
    aliases: await repo.getPersonalProductAliases(),
  );

  test(
    'AC2: el alias "mi pan" da matched con el producto, sin preguntar',
    () async {
      final id = await product('Pan tajado integral');
      await repo.updatePersonalProduct(
        id: id,
        nameEs: 'Pan tajado integral',
        servingUnit: 'g',
        aliases: ['mi pan'],
      );
      final result = (await resolver()).resolve('Mi Pan');
      expect(result, isA<FoodMatched>());
      expect((result as FoodMatched).food.id, 'personal:$id');
    },
  );

  test('AC3: nombre exacto de un producto gana a la coincidencia exacta del catálogo', () async {
    // El catálogo de fixtures tiene "Arepa" (coincidencia exacta). Antes de
    // SPEC-034 esto daba ambiguo entre el catálogo y el producto.
    final id = await product('Arepa');
    final result = (await resolver()).resolve('arepa');
    expect(result, isA<FoodMatched>());
    expect((result as FoodMatched).food.id, 'personal:$id');
  });

  test('AC4: dos productos con el alias "pan" → ambiguo entre ellos', () async {
    final a = await product('Pan blanco');
    final b = await product('Pan integral');
    for (final (id, name) in [(a, 'Pan blanco'), (b, 'Pan integral')]) {
      await repo.updatePersonalProduct(
        id: id,
        nameEs: name,
        servingUnit: 'g',
        aliases: ['pan'],
      );
    }
    final result = (await resolver()).resolve('pan');
    expect(result, isA<FoodAmbiguous>());
    expect((result as FoodAmbiguous).candidates.map((c) => c.id).toSet(), {
      'personal:$a',
      'personal:$b',
    });
  });

  test(
    'AC5: sin igualdad exacta, la regla de antes (contiene) no cambia',
    () async {
      final id = await product('Arepa congelada de prueba');
      final withAliases = await resolver();
      final before = FoodQueryResolver(
        catalog: buildFixtureCatalog(),
        personalProducts: await repo.getAllPersonalProducts(),
      );
      for (final query in ['arepa', 'congelada', 'huevo', 'pollo', 'nada']) {
        final now = withAliases.resolve(query);
        final old = before.resolve(query);
        expect(now.runtimeType, old.runtimeType, reason: query);
        if (now is FoodAmbiguous && old is FoodAmbiguous) {
          expect(
            now.candidates.map((c) => c.id),
            old.candidates.map((c) => c.id),
            reason: query,
          );
        }
        if (now is FoodMatched && old is FoodMatched) {
          expect(now.food.id, old.food.id, reason: query);
        }
      }
      expect(id, isPositive);
    },
  );

  test('R5: servingUnitOf devuelve la unidad guardada', () async {
    final id = await repo.savePersonalProduct(
      nameEs: 'Leche',
      energyKcal100: 45,
      proteinG100: 3,
      carbsG100: 5,
      fatG100: 1.5,
      servingGrams: 200,
      sourceRef: 'test',
      servingUnit: 'ml',
    );
    final r = await resolver();
    expect(r.servingUnitOf('personal:$id'), 'ml');
    expect(r.servingUnitOf('huevo'), 'g');
  });
}
