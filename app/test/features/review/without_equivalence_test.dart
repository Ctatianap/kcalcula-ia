import 'package:calorias_ia/features/review/meal_detail_view.dart';
import 'package:calorias_ia/ui/confidence_texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../support/meal_flow_harness.dart';

/// SPEC-043: "2 unidades de pechuga de pollo"; el catálogo de prueba no
/// tiene porciones para la pechuga (165 kcal / 100 g).
final _twoBreasts = parsedMeal([
  parsedItem(
    '2 unidades de pechuga de pollo',
    'pechuga de pollo',
    quantity: 2,
    unit: 'unidad',
  ),
]);

const _mention = '2 unidades de pechuga de pollo';

Future<MealFlowHarness> _openDetail(WidgetTester tester) async {
  final h = await MealFlowHarness.pump(
    tester,
    aiClient: FakeParseMeal((_) => _twoBreasts).client,
  );
  await h.openCaptureAndType(tester, _mention);
  await tester.ensureVisible(find.text('Analizar'));
  await tester.tap(find.text('Analizar'));
  await tester.pumpAndSettle();
  return h;
}

Finder _levelIn(String key, String label) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.text(label));

void main() {
  testWidgets(
    'AC3: sin equivalencia → "Sin equivalencia · ajústala", Estimación y la comida en Estimación',
    (tester) async {
      await _openDetail(tester);
      expect(find.text(withoutEquivalenceLabel), findsOneWidget);
      // Respaldo de `nutrition_core`: sin porciones → 100 g.
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('ingredient-quantity-$_mention')),
            )
            .data,
        '100 g',
      );
      expect(
        _levelIn('ingredient-confidence-$_mention', 'Estimación'),
        findsOneWidget,
      );
      expect(_levelIn('meal-confidence', 'Estimación'), findsOneWidget);
    },
  );

  testWidgets(
    'AC4: "¿Por qué?" explica que «unidad» no tiene equivalencia; escribir 150 g lo corrige',
    (tester) async {
      await _openDetail(tester);
      final indicator = find.byKey(Key('ingredient-confidence-$_mention'));
      await tester.ensureVisible(indicator);
      await tester.pumpAndSettle();
      await tester.tap(indicator);
      await tester.pumpAndSettle();
      final text = confidenceExplanation(
        ConfidenceReason.withoutEquivalence,
        said: 'unidad',
      );
      expect(find.text(text.title), findsOneWidget);
      expect(
        find.text(
          'No tenemos cuánto pesa «unidad» de este alimento, así que usamos '
          'una porción típica.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(writeGramsAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('write-quantity')), '150');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Listo'));
      await tester.pumpAndSettle();

      expect(find.text(withoutEquivalenceLabel), findsNothing);
      expect(
        _levelIn('ingredient-confidence-$_mention', 'Buena estimación'),
        findsOneWidget,
      );
      await tester.tap(indicator);
      await tester.pumpAndSettle();
      expect(
        find.text(confidenceExplanation(ConfidenceReason.explicitWeight).title),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AC6: al guardar, el ítem queda con confianza estimacion y base defaultPortion',
    (tester) async {
      final h = await _openDetail(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final meals = await h.storage.mealsBetween(
        DateTime(2000),
        DateTime(2100),
      );
      final item = meals.single.items.single;
      expect(item.confidence, 'estimacion');
      expect(item.quantityBasis, 'defaultPortion');
      expect(item.grams, 100);
      expect(meals.single.meal.confidence, 'estimacion');
    },
  );

  test(
    'Edge: vaga y sin equivalencia → se explica como cantidad aproximada',
    () {
      expect(
        confidenceReasonFor(
          basis: QuantityBasis.defaultPortion,
          isVague: true,
          level: ConfidenceLevel.estimacion,
          withoutEquivalence: true,
        ),
        ConfidenceReason.vague,
      );
    },
  );
}
