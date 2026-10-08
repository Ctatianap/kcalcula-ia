import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/ui/favorite_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../infra/food_resolution/frequent_and_favorite_meals_test.dart'
    show seedFrequent;
import '../../support/meal_flow_harness.dart';
import '../../support/recent_fixtures.dart';

/// Llamadas a `parseMeal` (AC4: deben ser 0).
var _aiCalls = 0;

AiClient _noAi() => AiClient((data) async {
  _aiCalls++;
  fail('No debe llamarse a la IA al repetir una favorita.');
});

final _now = DateTime(2026, 10, 8, 13, 30);

String? _title(WidgetTester tester, String key) => tester
    .widget<Text>(
      find
          .descendant(of: find.byKey(Key(key)), matching: find.byType(Text))
          .first,
    )
    .data;

Future<void> _openCapture(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
}

/// Mantener presionada [key] → la acción del menú.
Future<void> _menu(WidgetTester tester, String key, String action) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.longPress(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AC1: "Frecuentes" muestra huevo y luego arepa, no la de 2 veces',
    (tester) async {
      final h = await MealFlowHarness.pump(
        tester,
        aiClient: _noAi(),
        clock: () => _now,
      );
      await seedFrequent(h.storage);
      await _openCapture(tester);
      expect(find.text('Frecuentes'), findsOneWidget);
      expect(_title(tester, 'frequent-meal-0'), 'Huevo');
      expect(_title(tester, 'frequent-meal-1'), 'Arepa');
      expect(find.byKey(const Key('frequent-meal-2')), findsNothing);
    },
  );

  testWidgets(
    'AC3: "Guardar como favorita" con nombre la muestra primero; quitarla la saca',
    (tester) async {
      final h = await MealFlowHarness.pump(
        tester,
        aiClient: _noAi(),
        clock: () => _now,
      );
      await recentMeal(h.storage, DateTime(2026, 10, 7, 8), [
        recentItem('huevo', 'Huevo', 100),
        recentItem('arepa', 'Arepa', 115),
      ]);
      await _openCapture(tester);
      expect(find.text('Favoritas'), findsNothing);

      await _menu(tester, 'recent-meal-0', saveFavoriteAction);
      await tester.enterText(
        find.byKey(const Key('favorite-name')),
        'Desayuno de siempre',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(find.text(favoriteSavedMessage), findsOneWidget);
      expect(find.text('Favoritas'), findsOneWidget);
      expect(_title(tester, 'favorite-meal-0'), 'Desayuno de siempre');
      // Favoritas va antes que Recientes.
      expect(
        tester.getTopLeft(find.text('Favoritas')).dy,
        lessThan(tester.getTopLeft(find.text('Recientes')).dy),
      );

      // Dos veces la misma: aviso, sin otra favorita.
      await _menu(tester, 'recent-meal-0', saveFavoriteAction);
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(find.text(favoriteDuplicateMessage), findsOneWidget);
      expect(find.byKey(const Key('favorite-meal-1')), findsNothing);

      await _menu(tester, 'favorite-meal-0', removeFavoriteAction);
      expect(find.text('Favoritas'), findsNothing);
      expect(await h.storage.favoriteMeals(), isEmpty);
    },
  );

  testWidgets('R2: sin nombre, la favorita se llama como sus alimentos', (
    tester,
  ) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: _noAi(),
      clock: () => _now,
    );
    await recentMeal(h.storage, DateTime(2026, 10, 7, 8), [
      recentItem('huevo', 'Huevo', 100),
      recentItem('arepa', 'Arepa', 115),
    ]);
    await _openCapture(tester);
    await _menu(tester, 'recent-meal-0', saveFavoriteAction);
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(_title(tester, 'favorite-meal-0'), 'Huevo y Arepa');
  });

  testWidgets(
    'AC4: tocar una favorita abre el detalle sin IA y guardar crea una comida '
    'con la hora actual',
    (tester) async {
      _aiCalls = 0;
      final h = await MealFlowHarness.pump(
        tester,
        aiClient: _noAi(),
        clock: () => _now,
      );
      await h.storage.saveFavoriteMeal(
        name: 'Desayuno de siempre',
        items: const [
          FavoriteMealItemRecord(
            foodId: 'huevo',
            mention: 'dos huevos',
            grams: 100,
            quantityInput: 2,
            unitInput: 'unidad',
            quantityBasis: 'unitPortion',
            confidence: 'buenaEstimacion',
          ),
        ],
      );
      await _openCapture(tester);
      await tester.tap(find.byKey(const Key('favorite-meal-0')));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de comida'), findsOneWidget);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final meals = await h.storage.mealsBetween(
        DateTime(2000),
        DateTime(2100),
      );
      expect(meals.single.meal.eatenAt, _now);
      expect(meals.single.items.single.foodId, 'huevo');
      expect(meals.single.items.single.grams, 100);
      expect(meals.single.items.single.quantityInput, 2);
      expect(_aiCalls, 0);
      // Sigue en favoritas.
      expect(await h.storage.favoriteMeals(), hasLength(1));
    },
  );

  testWidgets(
    'AC6: una favorita con un alimento que ya no existe muestra el aviso y no se abre',
    (tester) async {
      final h = await MealFlowHarness.pump(
        tester,
        aiClient: _noAi(),
        clock: () => _now,
      );
      await h.storage.saveFavoriteMeal(
        name: 'Con chontaduro',
        items: const [
          FavoriteMealItemRecord(
            foodId: 'chontaduro',
            mention: 'chontaduro',
            grams: 80,
            quantityBasis: 'explicitWeight',
            confidence: 'altaPrecision',
          ),
        ],
      );
      await _openCapture(tester);
      expect(find.text(favoriteUnavailableMessage), findsOneWidget);
      await tester.tap(find.byKey(const Key('favorite-meal-0')));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de comida'), findsNothing);
      // Se puede quitar.
      await _menu(tester, 'favorite-meal-0', removeFavoriteAction);
      expect(await h.storage.favoriteMeals(), isEmpty);
    },
  );

  testWidgets('AC7: sin frecuentes ni favoritas, las secciones no aparecen', (
    tester,
  ) async {
    await MealFlowHarness.pump(tester, aiClient: _noAi(), clock: () => _now);
    await _openCapture(tester);
    expect(find.text('Favoritas'), findsNothing);
    expect(find.text('Frecuentes'), findsNothing);
    expect(find.text('Recientes'), findsNothing);
  });

  testWidgets('Edge: con 10 favoritas no deja añadir otra', (tester) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: _noAi(),
      clock: () => _now,
    );
    for (var i = 1; i <= maxFavoriteMeals; i++) {
      await h.storage.saveFavoriteMeal(
        name: 'F$i',
        items: [
          FavoriteMealItemRecord(
            foodId: 'cafe',
            mention: 'café',
            grams: i * 10,
            quantityBasis: 'explicitWeight',
            confidence: 'altaPrecision',
          ),
        ],
      );
    }
    await recentMeal(h.storage, DateTime(2026, 10, 7, 8), [
      recentItem('huevo', 'Huevo', 100),
    ]);
    await _openCapture(tester);
    await _menu(tester, 'recent-meal-0', saveFavoriteAction);
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.text(favoriteLimitMessage), findsOneWidget);
    expect(await h.storage.favoriteMeals(), hasLength(maxFavoriteMeals));
  });

  testWidgets(
    'SPEC-009: si guardar o quitar falla, mensaje en español sin el texto de SQLite',
    (tester) async {
      final h = await MealFlowHarness.pump(
        tester,
        aiClient: _noAi(),
        clock: () => _now,
        storage: (db) => _FailingFavorites(db),
      );
      await recentMeal(h.storage, DateTime(2026, 10, 7, 8), [
        recentItem('huevo', 'Huevo', 100),
      ]);
      await (h.storage as _FailingFavorites).saveFavoriteMealDirect('Mía');
      await _openCapture(tester);

      await _menu(tester, 'recent-meal-0', saveFavoriteAction);
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      expect(find.text(favoriteSaveErrorMessage), findsOneWidget);
      expect(find.textContaining('Sqlite'), findsNothing);

      await _menu(tester, 'favorite-meal-0', removeFavoriteAction);
      expect(find.text(favoriteRemoveErrorMessage), findsOneWidget);
      expect(find.textContaining('Sqlite'), findsNothing);
    },
  );

  testWidgets(
    'Accesibilidad: las tarjetas tienen "Más opciones" para el lector',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await MealFlowHarness.pump(
        tester,
        aiClient: _noAi(),
        clock: () => _now,
      );
      await recentMeal(h.storage, DateTime(2026, 10, 7, 8), [
        recentItem('huevo', 'Huevo', 100),
      ]);
      await _openCapture(tester);
      final node = tester.getSemantics(find.byKey(const Key('recent-meal-0')));
      final data = node.getSemanticsData();
      expect(data.hint, 'Mantén presionado para más opciones');
      final action = data.customSemanticsActionIds!
          .map(CustomSemanticsAction.getAction)
          .single;
      expect(action!.label, 'Más opciones');
      semantics.dispose();
    },
  );
}

/// Guardar y quitar favoritas fallan como fallaría SQLite.
class _FailingFavorites extends StorageRepository {
  _FailingFavorites(super.db);

  @override
  Future<SaveFavoriteResult> saveFavoriteMeal({
    required String name,
    required List<FavoriteMealItemRecord> items,
  }) => Future.error(StateError('SqliteException: INSERT … huevo'));

  @override
  Future<void> deleteFavoriteMeal(int id) =>
      Future.error(StateError('SqliteException: DELETE … $id'));

  /// Para sembrar una favorita sin pasar por el método que falla.
  Future<void> saveFavoriteMealDirect(String name) => super.saveFavoriteMeal(
    name: name,
    items: const [
      FavoriteMealItemRecord(
        foodId: 'arepa',
        mention: 'arepa',
        grams: 115,
        quantityBasis: 'unitPortion',
        confidence: 'buenaEstimacion',
      ),
    ],
  );
}
