import 'package:calorias_ia/features/review/meal_detail_view.dart';
import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/ui/components/meal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/meal_flow_harness.dart';

Map<String, dynamic> _item(
  String mention,
  String query, {
  double? quantity,
  String? unit,
}) => parsedItem(mention, query, quantity: quantity, unit: unit);

Map<String, dynamic> _op(
  String op, {
  int? index,
  Map<String, dynamic>? item,
  double? quantity,
  String? unit,
  String? size,
}) => {
  'op': op,
  'index': index,
  'item': item,
  'quantity': quantity,
  'unit': unit,
  'size': size,
};

Map<String, dynamic> _correction(List<Map<String, dynamic>> ops) => {
  'schema_version': 'meal_correction.v1',
  'operations': ops,
};

/// `correctMeal` falso: guarda lo que se le envía y responde según el texto.
class _FakeCorrect {
  final Map<String, Map<String, dynamic>> responses;
  final sent = <Map<String, dynamic>>[];

  _FakeCorrect(this.responses);

  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    sent.add(data);
    return responses[data['correction']] ?? _correction([]);
  }
}

/// "dos huevos y una arepa" → detalle; `correctMeal` con [responses].
Future<({MealFlowHarness h, _FakeCorrect fake})> _openDetail(
  WidgetTester tester,
  Map<String, Map<String, dynamic>> responses, {
  Map<String, dynamic>? meal,
}) async {
  final fake = _FakeCorrect(responses);
  final h = await MealFlowHarness.pump(
    tester,
    aiClient: AiClient((_) async => meal ?? eggsAndArepa, null, fake.call),
  );
  await h.openCaptureAndType(tester, 'dos huevos y una arepa');
  await tester.ensureVisible(find.text('Analizar'));
  await tester.tap(find.text('Analizar'));
  await tester.pumpAndSettle();
  return (h: h, fake: fake);
}

Future<void> _say(WidgetTester tester, String text) async {
  final input = find.byKey(const Key('correction-input'));
  await tester.ensureVisible(input);
  await tester.enterText(input, text);
  await tester.pump();
  await tester.tap(find.byKey(const Key('correction-apply')));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Aplicar').last);
  await tester.pumpAndSettle();
}

String _kcal(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('meal-detail-kcal'))).data!;

void main() {
  final replaceArepa = _correction([
    _op(
      'replace',
      index: 1,
      item: _item('una papa cocida', 'papa cocida', quantity: 100, unit: 'g'),
    ),
  ]);

  testWidgets(
    'AC1: "no era arepa…" → vista previa "Arepa → Papa cocida" y al aplicar el ítem 2 es la papa con sus kcal',
    (tester) async {
      final (:h, :fake) = await _openDetail(tester, {
        'no era arepa, era papa cocida': replaceArepa,
      });
      expect(_kcal(tester), '~450 kcal');
      await _say(tester, 'no era arepa, era papa cocida');

      expect(find.byKey(const Key('correction-preview')), findsOneWidget);
      expect(find.text('• Arepa → Papa cocida'), findsOneWidget);
      await _confirm(tester);

      expect(find.text('Papa cocida'), findsWidgets);
      expect(find.text('Arepa'), findsNothing);
      // 143 (huevo 100 g) + 87 (papa 100 g), calculado por nutrition_core.
      expect(_kcal(tester), '~230 kcal');
      expect(fake.sent, hasLength(1));
    },
  );

  testWidgets(
    'AC2: "fue una cucharada" → set_quantity con medida casera y Estimación por regla',
    (tester) async {
      await _openDetail(
        tester,
        {
          'fue una cucharada': _correction([
            _op('set_quantity', index: 0, quantity: 1, unit: 'cucharada'),
          ]),
        },
        meal: parsedMeal([
          _item('un tinto', 'café', quantity: 1, unit: 'unidad'),
        ]),
      );
      await _say(tester, 'fue una cucharada');
      expect(find.text('• Café: 1 cucharada'), findsOneWidget);
      await _confirm(tester);
      // 15 ml × 1 g/ml (sin densidad) = 15 g.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('ingredient-quantity-un tinto')))
            .data,
        '15 g',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('ingredient-confidence-un tinto')),
          matching: find.text('Estimación'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AC3 (app): la petición lleva solo lo dicho de cada ítem, sin nutrientes, gramos ni confianza',
    (tester) async {
      final (:h, :fake) = await _openDetail(tester, {});
      await _say(tester, 'está bien así');
      final items = fake.sent.single['items'] as List;
      expect(items, hasLength(2));
      for (final item in items) {
        expect((item as Map).keys.toSet(), {
          'mention',
          'food_query',
          'quantity',
          'unit',
          'size',
        });
      }
      expect(fake.sent.single['correction'], 'está bien así');
      expect(fake.sent.single['locale'], 'es-CO');
    },
  );

  testWidgets(
    'AC4: un índice que no existe → no se aplica nada y se pide decirlo de otra forma',
    (tester) async {
      await _openDetail(tester, {
        'quita el pan': _correction([_op('remove', index: 7)]),
      });
      await _say(tester, 'quita el pan');
      expect(find.byKey(const Key('correction-preview')), findsNothing);
      expect(find.text(correctionInvalidMessage), findsOneWidget);
      expect(_kcal(tester), '~450 kcal');
    },
  );

  testWidgets('Edge: sin operaciones → "No vi nada que cambiar."', (
    tester,
  ) async {
    await _openDetail(tester, {});
    await _say(tester, 'está bien así');
    expect(find.text(noCorrectionChangesMessage), findsOneWidget);
    expect(find.byKey(const Key('correction-undo')), findsNothing);
  });

  testWidgets('AC5: "Deshacer" restaura exactamente el borrador anterior', (
    tester,
  ) async {
    await _openDetail(tester, {'no era arepa, era papa cocida': replaceArepa});
    await _say(tester, 'no era arepa, era papa cocida');
    await _confirm(tester);
    expect(_kcal(tester), '~230 kcal');

    await tester.ensureVisible(find.byKey(const Key('correction-undo')));
    await tester.tap(find.byKey(const Key('correction-undo')));
    await tester.pumpAndSettle();
    expect(_kcal(tester), '~450 kcal');
    expect(find.text('Arepa'), findsWidgets);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('ingredient-quantity-una arepa')))
          .data,
      '115 g',
    );
    expect(find.byKey(const Key('correction-undo')), findsNothing);
  });

  testWidgets('AC9: dos correcciones y "Deshacer" → queda la primera', (
    tester,
  ) async {
    await _openDetail(tester, {
      'no era arepa, era papa cocida': replaceArepa,
      'quita los huevos': _correction([_op('remove', index: 0)]),
    });
    await _say(tester, 'no era arepa, era papa cocida');
    await _confirm(tester);
    await _say(tester, 'quita los huevos');
    expect(find.text('• Quitar Huevo'), findsOneWidget);
    await _confirm(tester);
    expect(_kcal(tester), '~87 kcal');

    await tester.ensureVisible(find.byKey(const Key('correction-undo')));
    await tester.tap(find.byKey(const Key('correction-undo')));
    await tester.pumpAndSettle();
    expect(_kcal(tester), '~230 kcal');
    expect(find.text('Papa cocida'), findsWidgets);
  });

  testWidgets('R4: "Cancelar" en la vista previa no cambia nada', (
    tester,
  ) async {
    await _openDetail(tester, {'no era arepa, era papa cocida': replaceArepa});
    await _say(tester, 'no era arepa, era papa cocida');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(_kcal(tester), '~450 kcal');
    expect(find.byKey(const Key('correction-undo')), findsNothing);
  });

  testWidgets('R2: "también…" añade el ítem al final', (tester) async {
    await _openDetail(tester, {
      'también un muslo de pollo': _correction([
        _op(
          'add',
          item: _item(
            'un muslo de pollo',
            'muslo de pollo',
            quantity: 100,
            unit: 'g',
          ),
        ),
      ]),
    });
    await _say(tester, 'también un muslo de pollo');
    expect(find.text('• Añadir Muslo de pollo'), findsOneWidget);
    await _confirm(tester);
    // 450 + 200.
    expect(_kcal(tester), '~650 kcal');
  });

  testWidgets(
    'AC8: vacío o de más de 300 caracteres → "Aplicar" deshabilitado',
    (tester) async {
      await _openDetail(tester, {});
      final input = find.byKey(const Key('correction-input'));
      await tester.ensureVisible(input);
      FilledButton apply() => tester.widget<FilledButton>(
        find.byKey(const Key('correction-apply')),
      );
      expect(apply().onPressed, isNull);
      await tester.enterText(input, '   ');
      await tester.pump();
      expect(apply().onPressed, isNull);
      await tester.enterText(input, 'a' * 301);
      await tester.pump();
      expect(apply().onPressed, isNull);
      await tester.enterText(input, 'a' * 300);
      await tester.pump();
      expect(apply().onPressed, isNotNull);
    },
  );

  testWidgets('R1: en "Editar comida" (comida guardada) no aparece el campo', (
    tester,
  ) async {
    await _openDetail(tester, {});
    expect(find.byKey(const Key('correction-input')), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    // Hoy → tocar la comida → "Editar comida".
    await tester.tap(find.byType(MealCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Editar comida'), findsOneWidget);
    expect(find.byKey(const Key('correction-input')), findsNothing);
  });
}
