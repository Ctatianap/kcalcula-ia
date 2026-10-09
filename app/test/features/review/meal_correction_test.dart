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
      item: _item(
        'un pan integral',
        'pan integral',
        quantity: 1,
        unit: 'unidad',
      ),
    ),
  ]);

  testWidgets(
    'AC1: "no era arepa…" → vista previa "Arepa → Pan integral" y al aplicar el ítem 2 es el pan con sus kcal',
    (tester) async {
      final (:h, :fake) = await _openDetail(tester, {
        'no era arepa, era pan integral': replaceArepa,
      });
      expect(_kcal(tester), '~450 kcal');
      await _say(tester, 'no era arepa, era pan integral');

      expect(find.byKey(const Key('correction-preview')), findsOneWidget);
      expect(find.text('• Arepa → Pan integral'), findsOneWidget);
      await _confirm(tester);

      expect(find.text('Pan integral'), findsWidgets);
      expect(find.text('Arepa'), findsNothing);
      // 143 (huevo 100 g) + 75 (pan 30 g × 250/100), calculado por
      // nutrition_core.
      expect(_kcal(tester), '~218 kcal');
      expect(fake.sent, hasLength(1));
    },
  );

  testWidgets(
    'AC2: "el arroz fue una taza" → taza × densidad y la confianza baja a Estimación',
    (tester) async {
      await _openDetail(
        tester,
        {
          'el arroz fue una taza': _correction([
            _op('set_quantity', index: 0, quantity: 1, unit: 'taza'),
          ]),
        },
        meal: parsedMeal([
          _item('150 g de arroz', 'arroz blanco', quantity: 150, unit: 'g'),
        ]),
      );
      Finder level(String text) => find.descendant(
        of: find.byKey(const Key('ingredient-confidence-150 g de arroz')),
        matching: find.text(text),
      );
      // Antes: peso dicho → Buena estimación.
      expect(level('Buena estimación'), findsOneWidget);
      await _say(tester, 'el arroz fue una taza');
      expect(find.text('• Arroz blanco: 1 taza'), findsOneWidget);
      await _confirm(tester);
      // 240 ml × 0,8 g/ml = 192 g (household_units × densidad).
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('ingredient-quantity-150 g de arroz')),
            )
            .data,
        '192 g',
      );
      expect(level('Estimación'), findsOneWidget);
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
    await _openDetail(tester, {'no era arepa, era pan integral': replaceArepa});
    await _say(tester, 'no era arepa, era pan integral');
    await _confirm(tester);
    expect(_kcal(tester), '~218 kcal');

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
      'no era arepa, era pan integral': replaceArepa,
      'quita los huevos': _correction([_op('remove', index: 0)]),
    });
    await _say(tester, 'no era arepa, era pan integral');
    await _confirm(tester);
    await _say(tester, 'quita los huevos');
    expect(find.text('• Quitar Huevo'), findsOneWidget);
    await _confirm(tester);
    expect(_kcal(tester), '~75 kcal');

    await tester.ensureVisible(find.byKey(const Key('correction-undo')));
    await tester.tap(find.byKey(const Key('correction-undo')));
    await tester.pumpAndSettle();
    expect(_kcal(tester), '~218 kcal');
    expect(find.text('Pan integral'), findsWidgets);
  });

  testWidgets('R4: "Cancelar" en la vista previa no cambia nada', (
    tester,
  ) async {
    await _openDetail(tester, {'no era arepa, era pan integral': replaceArepa});
    await _say(tester, 'no era arepa, era pan integral');
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

  testWidgets(
    'Revisor: cambiar solo el tamaño conserva la cantidad ("las arepas eran pequeñas")',
    (tester) async {
      await _openDetail(
        tester,
        {
          'las arepas eran pequeñas': _correction([
            _op('set_quantity', index: 0, size: 'pequeno'),
          ]),
        },
        meal: parsedMeal([
          _item('dos arepas', 'arepa', quantity: 2, unit: 'unidad'),
        ]),
      );
      await _say(tester, 'las arepas eran pequeñas');
      expect(find.text('• Arepa: 2 pequeño'), findsOneWidget);
      await _confirm(tester);
      // 2 × 70 g, no 1 × 70 g.
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('ingredient-quantity-dos arepas')),
            )
            .data,
        '140 g',
      );
    },
  );

  testWidgets(
    'Revisor: una edición a mano después de corregir quita "Deshacer"',
    (tester) async {
      await _openDetail(tester, {
        'no era arepa, era pan integral': replaceArepa,
      });
      await _say(tester, 'no era arepa, era pan integral');
      await _confirm(tester);
      expect(find.byKey(const Key('correction-undo')), findsOneWidget);
      final plus = find.byTooltip('Más').first;
      await tester.ensureVisible(plus);
      await tester.tap(plus);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('correction-undo')), findsNothing);
    },
  );

  testWidgets('Revisor: con más de 30 ingredientes se pide corregir a mano', (
    tester,
  ) async {
    final (:h, :fake) = await _openDetail(
      tester,
      {},
      meal: parsedMeal([
        for (var i = 0; i < 31; i++)
          _item('huevo $i', 'huevo', quantity: 1, unit: 'unidad'),
      ]),
    );
    await _say(tester, 'quita un huevo');
    expect(find.text(tooManyItemsForCorrectionMessage), findsOneWidget);
    expect(fake.sent, isEmpty);
  });

  testWidgets('Revisor: cambiar el tipo de comida no quita "Deshacer"', (
    tester,
  ) async {
    await _openDetail(tester, {'no era arepa, era pan integral': replaceArepa});
    await _say(tester, 'no era arepa, era pan integral');
    await _confirm(tester);
    final snack = find.byKey(const Key('meal-type-snack'));
    await tester.ensureVisible(snack);
    await tester.tap(snack);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('correction-undo')), findsOneWidget);
  });
}
