import 'package:calorias_ia/features/review/food_search_screen.dart';
import 'package:calorias_ia/features/review/personal_product_picker_screen.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/food_resolution/food_query_resolver.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';

/// Guarda "Pan tajado integral" (alias "mi pan") y "Leche" (sin alias).
Future<int> _seed(StorageRepository repo) async {
  final bread = await repo.savePersonalProduct(
    nameEs: 'Pan tajado integral',
    energyKcal100: 260,
    proteinG100: 9,
    carbsG100: 48,
    fatG100: 3,
    servingGrams: 27,
    sourceRef: 'test',
  );
  await repo.updatePersonalProduct(
    id: bread,
    nameEs: 'Pan tajado integral',
    servingUnit: 'g',
    aliases: ['mi pan', 'pan integral'],
  );
  await repo.savePersonalProduct(
    nameEs: 'Leche',
    energyKcal100: 45,
    proteinG100: 3,
    carbsG100: 5,
    fatG100: 1.5,
    servingGrams: 200,
    sourceRef: 'test',
    servingUnit: 'ml',
  );
  return bread;
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.runAsync(() => _seed(StorageRepository(db)));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SPEC-035 search', () {
    late AppDatabase db;
    late StorageRepository repo;
    late int bread;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = StorageRepository(db);
      bread = await _seed(repo);
    });
    tearDown(() => db.close());

    Future<FoodQueryResolver> resolver() async => FoodQueryResolver(
      catalog: buildFixtureCatalog(),
      personalProducts: await repo.getAllPersonalProducts(),
      aliases: await repo.getPersonalProductAliases(),
    );

    test(
      'AC1: "mi pan" encuentra el producto una vez, con su nombre',
      () async {
        final hits = (await resolver()).search('mi pan');
        final personal = hits.where((h) => h.id == 'personal:$bread').toList();
        expect(personal, hasLength(1));
        expect(personal.single.nameEs, 'Pan tajado integral');
      },
    );

    test(
      'AC2: coincide por nombre y por alias a la vez → una sola vez',
      () async {
        // "pan" está en el nombre y en los dos alias.
        final hits = (await resolver()).search('pan');
        expect(hits.where((h) => h.id == 'personal:$bread'), hasLength(1));
      },
    );

    test('caso borde: un alias que también está en el catálogo sale primero (SPEC-018)', () async {
      await repo.updatePersonalProduct(
        id: bread,
        nameEs: 'Pan tajado integral',
        servingUnit: 'g',
        aliases: ['mi arepa'],
      );
      final hits = (await resolver()).search('arepa');
      expect(hits.first.id, 'personal:$bread');
      expect(hits.skip(1).map((h) => h.id), contains('arepa'));
    });

    test('sin alias, igual que antes', () async {
      final hits = (await resolver()).search('leche');
      expect(hits.first.nameEs, 'Leche');
    });
  });

  testWidgets('AC3: "Buscar alimento" con "mi pan" muestra el producto', (
    tester,
  ) async {
    await _pump(tester, const FoodSearchScreen());
    await tester.enterText(
      find.byKey(const Key('food-search-input')),
      'mi pan',
    );
    await tester.pumpAndSettle();
    expect(find.text('Pan tajado integral'), findsOneWidget);
  });

  testWidgets(
    'AC4: "Elegir de mis productos" filtra por alias y muestra "También:"',
    (tester) async {
      await _pump(tester, const PersonalProductPickerScreen());
      expect(find.text('Leche'), findsOneWidget);
      expect(
        find.textContaining('También: mi pan, pan integral'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('personal-product-search')),
        'mi pan',
      );
      await tester.pumpAndSettle();
      expect(find.text('Pan tajado integral'), findsOneWidget);
      expect(find.text('Leche'), findsNothing);
    },
  );
}
