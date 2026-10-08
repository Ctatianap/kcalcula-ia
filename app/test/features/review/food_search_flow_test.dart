import 'package:calorias_ia/features/review/food_search_screen.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/meal_flow_harness.dart';

const _timeout = AiClientException(
  AiClientErrorType.network,
  'Sin conexión. Revisa tu internet e intenta de nuevo.',
  code: 'deadline-exceeded',
);

/// Hoy → + → texto → Analizar, con la IA respondiendo [eggsAndArepa].
Future<MealFlowHarness> _openDetail(WidgetTester tester) async {
  final h = await MealFlowHarness.pump(
    tester,
    aiClient: FakeParseMeal((_) => eggsAndArepa).client,
  );
  await h.openCaptureAndType(tester, 'dos huevos y una arepa');
  await tester.ensureVisible(find.text('Analizar'));
  await tester.tap(find.text('Analizar'));
  await tester.pumpAndSettle();
  return h;
}

Future<void> _openSearchFromDetail(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Añadir ingrediente'));
  await tester.tap(find.text('Añadir ingrediente'));
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('food-search-input')), text);
  await tester.pump();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('AC1: "arep" muestra las arepas con kcal por 100 g; "tinto" '
      'encuentra el café', (tester) async {
    await _openDetail(tester);
    await _openSearchFromDetail(tester);
    expect(find.text('Buscar alimento'), findsOneWidget);
    await _search(tester, 'arep');
    expect(find.text('Arepa'), findsOneWidget);
    expect(find.text('267 kcal por 100 g'), findsOneWidget);
    expect(find.text('Arepa de queso'), findsOneWidget);
    expect(find.text('300 kcal por 100 g'), findsOneWidget);
    await _search(tester, 'tinto');
    expect(find.text('Café'), findsOneWidget);
  });

  // SPEC-040 R6: desde "Añadir ingrediente" el mensaje sugiere la etiqueta;
  // desde el error de análisis sigue el de R5
  // (`add_ingredient_with_label_test.dart`).
  testWidgets('AC5: sin resultados → mensaje (SPEC-040 R6 desde el Detalle)', (
    tester,
  ) async {
    await _openDetail(tester);
    await _openSearchFromDetail(tester);
    await _search(tester, 'a.');
    expect(find.text('Escribe al menos 2 letras.'), findsOneWidget);
    await _search(tester, 'chontaduro');
    expect(find.text(noSearchResultsWithLabelMessage), findsOneWidget);
    expect(find.textContaining('Crear'), findsNothing);
  });

  testWidgets('AC2: Huevo con 2 unidades: vista previa con los valores de '
      'nutrition_core para 100 g', (tester) async {
    await _openDetail(tester);
    await _openSearchFromDetail(tester);
    await _search(tester, 'huevo');
    await tester.tap(find.byKey(const Key('food-hit-huevo')));
    await tester.pumpAndSettle();
    expect(find.text('Elegir cantidad'), findsOneWidget);
    expect(find.text('Unidad · 50,0 g'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('quantity-amount')), '2');
    await tester.pump();
    // calculateItemNutrients(huevo, 100 g): 143 kcal, 12,56 / 0,72 / 9,51.
    expect(_text(tester, 'quantity-preview-kcal'), '100,0 g · ~143 kcal');
    expect(
      _text(tester, 'quantity-preview-macros'),
      'P ~12,6 g · C ~0,7 g · G ~9,5 g',
    );
    // Gramos a mano.
    await tester.tap(find.byKey(const Key('quantity-option-gramos')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('quantity-amount')), '0');
    await tester.pump();
    expect(find.text(invalidAmountMessage), findsOneWidget);
    final add = find.widgetWithText(FilledButton, 'Añadir');
    expect(tester.widget<FilledButton>(add).onPressed, isNull);
  });

  testWidgets('AC3: "Añadir" desde el detalle agrega el ítem y recalcula los '
      'totales', (tester) async {
    await _openDetail(tester);
    expect(_text(tester, 'meal-detail-kcal'), '~450 kcal');
    await _openSearchFromDetail(tester);
    await _search(tester, 'pechuga');
    await tester.tap(find.byKey(const Key('food-hit-pechuga_de_pollo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quantity-amount')), '100');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Añadir'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de comida'), findsOneWidget);
    expect(find.text('Huevo, Arepa y Pechuga de pollo'), findsOneWidget);
    // 450 + 165 = 615.
    expect(_text(tester, 'meal-detail-kcal'), '~615 kcal');
    expect(find.text('Base verificada'), findsOneWidget);
  });

  testWidgets('AC4: desde el error de la IA, buscar y elegir abre el detalle '
      'con ese alimento y se guarda sin volver a llamar a la IA', (
    tester,
  ) async {
    final fake = FakeParseMeal((_) => throw _timeout);
    final h = await MealFlowHarness.pump(tester, aiClient: fake.client);
    await h.openCaptureAndType(tester, 'algo raro');
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    expect(find.text('Algo salió mal'), findsOneWidget);

    await tester.ensureVisible(find.text('Buscar en la base manualmente'));
    await tester.tap(find.text('Buscar en la base manualmente'));
    await tester.pumpAndSettle();
    await _search(tester, 'huevo');
    await tester.tap(find.byKey(const Key('food-hit-huevo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quantity-amount')), '2');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Añadir'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle de comida'), findsOneWidget);
    expect(find.text('Huevo'), findsWidgets);
    expect(find.text('100 g'), findsOneWidget);
    // Se pueden añadir más.
    expect(find.text('Añadir ingrediente'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final meals = await h.storage.mealsBetween(DateTime(2000), DateTime(2100));
    expect(meals.single.items.single.foodId, 'huevo');
    expect(meals.single.items.single.quantityInput, 2);
    expect(meals.single.items.single.unitInput, 'unidad');
    expect(fake.texts, ['algo raro']);
  });

  testWidgets('"Corregir" desde un detalle abierto por búsqueda vuelve al '
      'texto', (tester) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => throw _timeout).client,
    );
    await h.openCaptureAndType(tester, 'algo raro');
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Buscar en la base manualmente'));
    await tester.tap(find.text('Buscar en la base manualmente'));
    await tester.pumpAndSettle();
    await _search(tester, 'huevo');
    await tester.tap(find.byKey(const Key('food-hit-huevo')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Añadir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corregir'));
    await tester.pumpAndSettle();
    expect(find.text('algo raro'), findsOneWidget);
  });

  testWidgets('texto grande (×2) en 360 px: búsqueda y cantidad sin '
      'desbordes', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openDetail(tester);
    await _openSearchFromDetail(tester);
    await _search(tester, 'arep');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('food-hit-arepa')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
