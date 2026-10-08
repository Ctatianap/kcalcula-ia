import 'package:calorias_ia/features/history/history_screen.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 8, 12);

MealItemRecord _item(String name) => MealItemRecord(
  mention: name.toLowerCase(),
  foodId: name.toLowerCase(),
  nameSnapshot: name,
  grams: 100,
  quantityBasis: 'explicitWeight',
  energyKcal: 200,
  proteinG: 5,
  carbsG: 30,
  fatG: 7,
  confidence: 'altaPrecision',
  sourceRef: 'fixture',
);

Future<void> _meal(StorageRepository repo, DateTime at, List<String> foods) =>
    repo.registerMeal(
      eatenAt: at,
      mealType: 'desayuno',
      confidence: 'altaPrecision',
      catalogVersion: 'test-1',
      items: [for (final f in foods) _item(f)],
    );

Future<void> _seed(StorageRepository repo) async {
  await _meal(repo, DateTime(2026, 9, 20, 8), ['Arepa de queso']);
  await _meal(repo, DateTime(2026, 10, 2, 8), ['Huevo', 'Arepa']);
  await _meal(repo, DateTime(2026, 10, 2, 13), ['Arepa']);
  await _meal(repo, DateTime(2026, 10, 6, 8), ['Pan']);
}

void main() {
  group('SPEC-036 searchMealDays', () {
    late AppDatabase db;
    late StorageRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = StorageRepository(db);
      await _seed(repo);
    });
    tearDown(() => db.close());

    test(
      'AC1: días con arepa, del más reciente al más antiguo, sin repetir',
      () async {
        final hits = await repo.searchMealDays('arepa');
        expect(hits.map((h) => h.day), [
          DateTime(2026, 10, 2),
          DateTime(2026, 9, 20),
        ]);
        expect(hits.first.foods, ['Arepa']);
        expect(hits.last.foods, ['Arepa de queso']);
      },
    );

    test('AC3: "Arepa" y "arepá" dan lo mismo', () async {
      final a = await repo.searchMealDays('Arepa');
      final b = await repo.searchMealDays('arepá');
      expect(b.map((h) => h.day), a.map((h) => h.day));
    });

    test('cada palabra por prefijo, como SPEC-018', () async {
      // "queso arepa" encuentra "Arepa de queso" (orden distinto).
      final both = await repo.searchMealDays('queso arepa');
      expect(both.map((h) => h.day), [DateTime(2026, 9, 20)]);
      // "pa" no encuentra "Arepa" por la mitad de la palabra; sí "Pan".
      final pa = await repo.searchMealDays('pa');
      expect(pa.map((h) => h.day), [DateTime(2026, 10, 6)]);
    });

    test('menos de 2 letras no busca', () async {
      expect(await repo.searchMealDays('a'), isEmpty);
    });

    test('hasta 50 días', () async {
      for (var i = 0; i < 60; i++) {
        await _meal(repo, DateTime(2026, 1, 1).add(Duration(days: i)), [
          'Mango',
        ]);
      }
      final hits = await repo.searchMealDays('mango');
      expect(hits, hasLength(50));
      expect(
        hits.first.day,
        DateTime(2026, 1, 1).add(const Duration(days: 59)),
      );
    });
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() => _seed(StorageRepository(db)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => _now),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('history-search')), text);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'AC1: buscar "arepa" lista los días y tocar uno lo abre en el calendario',
    (tester) async {
      await pump(tester);
      await search(tester, 'arepa');
      expect(find.text('viernes 2 de octubre'), findsOneWidget);
      expect(find.text('domingo 20 de septiembre'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('viernes 2 de octubre')).dy,
        lessThan(tester.getTopLeft(find.text('domingo 20 de septiembre')).dy),
      );

      await tester.tap(find.text('domingo 20 de septiembre'));
      await tester.pumpAndSettle();
      expect(find.text('septiembre 2026'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('history-selected-date')))
            .data,
        contains('20 de septiembre'),
      );
    },
  );

  testWidgets('AC2: sin resultados, el mensaje', (tester) async {
    await pump(tester);
    await search(tester, 'pizza');
    expect(find.text(noFoodInHistoryMessage), findsOneWidget);
  });

  testWidgets('menos de 2 letras: pide más y no busca', (tester) async {
    await pump(tester);
    await search(tester, 'a');
    expect(find.text('Escribe al menos 2 letras.'), findsOneWidget);
    expect(find.text(noFoodInHistoryMessage), findsNothing);
  });

  testWidgets('borrar la búsqueda vuelve al calendario', (tester) async {
    await pump(tester);
    await search(tester, 'arepa');
    await tester.tap(find.byTooltip('Borrar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('octubre 2026'), findsOneWidget);
    expect(find.text('domingo 20 de septiembre'), findsNothing);
  });
}
