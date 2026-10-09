import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';
import '../../support/meal_flow_harness.dart';
import '../../support/recent_fixtures.dart';

/// Llamadas a `parseMeal` (AC2: deben ser 0).
var _aiCalls = 0;

/// `parseMeal` que cuenta las llamadas y falla si se llama.
AiClient _noAi() => AiClient((data) async {
  _aiCalls++;
  fail('No debe llamarse a la IA al repetir una comida reciente.');
});

final _now = DateTime(2026, 10, 3, 13, 30);

void main() {
  testWidgets('AC1: Recientes muestra 5 comidas distintas, en orden', (
    tester,
  ) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: _noAi(),
      clock: () => _now,
    );
    await seedSevenMeals(h.storage);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Recientes'), findsOneWidget);
    final names = [
      for (var i = 0; i < 5; i++)
        tester
            .widget<Text>(
              find
                  .descendant(
                    of: find.byKey(Key('recent-meal-$i')),
                    matching: find.byType(Text),
                  )
                  .first,
            )
            .data,
    ];
    expect(names, [
      'Arepa',
      'Huevo y Arepa',
      'Muslo de pollo',
      'Pechuga de pollo',
      'Huevo',
    ]);
    expect(find.byKey(const Key('recent-meal-5')), findsNothing);
    // Kcal con el catálogo actual: arepa 267 kcal/100 g × 115 g = 307.
    expect(
      tester.widget<Text>(find.byKey(const Key('recent-meal-kcal-0'))).data,
      '~307 kcal',
    );
  });

  testWidgets('AC3: la tarjeta muestra las kcal del catálogo actual', (
    tester,
  ) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: _noAi(),
      catalog: buildFixtureCatalog(eggKcal: 155),
    );
    await recentMeal(h.storage, DateTime(2026, 10, 1, 8), [
      recentItem('huevo', 'Huevo', 100, kcal: 143),
    ]);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('recent-meal-kcal-0'))).data,
      '~155 kcal',
    );
  });

  testWidgets('R5: sin comidas previas no aparece "Recientes"', (tester) async {
    await MealFlowHarness.pump(tester, aiClient: _noAi());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Recientes'), findsNothing);
  });

  testWidgets('AC2 + AC5: tocar una abre el detalle con los mismos alimentos '
      'y gramos sin llamar a la IA; guardar crea una comida nueva con la hora '
      'actual', (tester) async {
    _aiCalls = 0;
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: _noAi(),
      clock: () => _now,
    );
    await seedSevenMeals(h.storage);
    final before = await h.storage.mealsBetween(DateTime(2000), DateTime(2100));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('recent-meal-1')));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de comida'), findsOneWidget);
    expect(find.text('Huevo y Arepa'), findsOneWidget);
    expect(find.text('50 g'), findsOneWidget);
    expect(find.text('70 g'), findsOneWidget);
    // R3: tipo de comida por la hora actual (13:30 → almuerzo).
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('meal-type-almuerzo')))
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final after = await h.storage.mealsBetween(DateTime(2000), DateTime(2100));
    expect(after, hasLength(before.length + 1));
    final created = after.last;
    expect(created.meal.eatenAt, _now);
    expect(created.items.map((i) => (i.foodId, i.grams)), [
      ('huevo', 50.0),
      ('arepa', 70.0),
    ]);
    expect(_aiCalls, 0);
  });

  testWidgets('texto grande (×2) en 360 px: Recientes sin desbordes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = await MealFlowHarness.pump(tester, aiClient: _noAi());
    await seedSevenMeals(h.storage);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('recent-meal-4')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
