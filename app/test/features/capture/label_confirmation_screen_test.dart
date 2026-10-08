import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/capture/label_confirmation_screen.dart';
import 'package:calorias_ia/infra/ai_client/label_extraction_dto.dart';
import 'package:calorias_ia/infra/ai_client/parsed_meal_dto.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _extraction = LabelExtractionDto(
  productName: 'Producto de prueba',
  servingSize: LabelServingSizeDto(quantity: 30, unit: 'g'),
  perServing: LabelNutrientSetDto(
    energyKcal: 140,
    proteinG: 2,
    carbsG: 20,
    fatG: 6,
  ),
  per100: null,
  unreadableFields: [],
);

const _atwaterInconsistentExtraction = LabelExtractionDto(
  productName: 'Producto inconsistente',
  servingSize: LabelServingSizeDto(quantity: 30, unit: 'g'),
  perServing: LabelNutrientSetDto(
    energyKcal: 500,
    proteinG: 1,
    carbsG: 1,
    fatG: 1,
  ),
  per100: null,
  unreadableFields: [],
);

const _unreadableFatExtraction = LabelExtractionDto(
  productName: 'Producto de prueba',
  servingSize: LabelServingSizeDto(quantity: 30, unit: 'g'),
  perServing: LabelNutrientSetDto(
    energyKcal: 140,
    proteinG: 2,
    carbsG: 20,
    fatG: null,
  ),
  per100: null,
  unreadableFields: ['fat_g'],
);

const _unreadableProteinExtraction = LabelExtractionDto(
  productName: 'Producto de prueba',
  servingSize: LabelServingSizeDto(quantity: 30, unit: 'g'),
  perServing: LabelNutrientSetDto(
    energyKcal: 140,
    proteinG: null,
    carbsG: 20,
    fatG: 6,
  ),
  per100: null,
  unreadableFields: ['protein_g'],
);

/// SPEC-030 AC2: valores con decimales "de máquina"; porción de 100 g para
/// que lo guardado por 100 g sea exactamente lo transcrito.
const _rawDecimalsExtraction = LabelExtractionDto(
  productName: 'Producto decimales',
  servingSize: LabelServingSizeDto(quantity: 100, unit: 'g'),
  perServing: LabelNutrientSetDto(
    energyKcal: 15.0,
    proteinG: 0,
    carbsG: 1.7799999999999998,
    fatG: 2.9,
  ),
  per100: null,
  unreadableFields: [],
);

/// SPEC-031: la etiqueta de la prueba en el teléfono (porción de 27 g).
const _serving27Extraction = LabelExtractionDto(
  productName: 'Producto 27 g',
  servingSize: LabelServingSizeDto(quantity: 27, unit: 'g'),
  perServing: LabelNutrientSetDto(
    energyKcal: 70,
    proteinG: 2.8,
    carbsG: 15,
    fatG: 0.2,
  ),
  per100: null,
  unreadableFields: [],
);

Finder _portionsField() =>
    find.widgetWithText(TextField, '¿Cuánto comiste? (porciones)');

/// SPEC-032: cambia "¿Cuánto comiste?" a g (los tests de SPEC-004/031
/// prueban ese modo).
Future<void> _toGrams(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(consumedUnitServingKey));
  await tester.tap(find.byKey(consumedUnitServingKey));
  await tester.pump();
}

Finder _servingField() => find.widgetWithText(TextField, 'Porción');
Finder _consumedField() =>
    find.widgetWithText(TextField, '¿Cuánto comiste? (g)');

String _fieldText(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

Future<AppDatabase> _pump(
  WidgetTester tester,
  LabelExtractionDto extraction, {
  NutritionGoalValues? goal,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (goal != null) {
    await tester.runAsync(() => StorageRepository(db).saveNutritionGoal(goal));
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => settings.name == AppRoutes.review
              ? Scaffold(
                  body: Column(
                    children: [
                      const Text('Revisar (mock)'),
                      // SPEC-031 R4: la cantidad que llega a Revisar.
                      Text(
                        'cantidad=${(settings.arguments as ParsedMealDto?)?.items.first.quantity}',
                      ),
                      Text(
                        'unidad=${(settings.arguments as ParsedMealDto?)?.items.first.unit}',
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        home: LabelConfirmationScreen(extraction: extraction),
      ),
    ),
  );
  return db;
}

Finder _saveButton() =>
    find.widgetWithText(FilledButton, reviewMealButtonLabel);

Future<void> _tapSave(WidgetTester tester) async {
  // Cierra el teclado del último campo editado: con la vista previa la
  // pantalla es más alta y el campo enfocado puede tapar el botón.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(_saveButton());
  await tester.pumpAndSettle();
  await tester.tap(_saveButton());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC2/AC4: muestra los valores transcritos, editables', (
    tester,
  ) async {
    await _pump(tester, _extraction);

    expect(find.text('Producto de prueba'), findsOneWidget);
    // SPEC-030 R2: sin ".0" (antes "140.0" y "30.0").
    expect(find.text('140'), findsOneWidget); // energy_kcal
    // SPEC-032 R1: "¿Cuánto comiste?" arranca en 1 porción (antes "30" en
    // g, que es lo mismo).
    expect(find.text('30'), findsOneWidget);
    expect(_fieldText(tester, _portionsField()), '1');

    await tester.enterText(
      find.widgetWithText(TextField, 'Calorías por porción (kcal)'),
      '150',
    );
    await tester.pump();
    expect(find.text('150'), findsOneWidget);
  });

  testWidgets(
    'AC4: campo no legible se etiqueta como tal y bloquea Guardar hasta completarlo',
    (tester) async {
      await _pump(tester, _unreadableFatExtraction);

      expect(find.textContaining('no se pudo leer'), findsOneWidget);

      final saveButton = find.widgetWithText(
        FilledButton,
        reviewMealButtonLabel,
      );
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(
          TextField,
          'Grasa por porción (g) (no se pudo leer)',
        ),
        '6',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    },
  );

  testWidgets(
    'AC3: Atwater fuera de rango muestra advertencia y bloquea Guardar hasta confirmar',
    (tester) async {
      await _pump(tester, _atwaterInconsistentExtraction);

      expect(find.textContaining('no cuadran entre sí'), findsOneWidget);
      final saveButton = find.widgetWithText(
        FilledButton,
        reviewMealButtonLabel,
      );
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    },
  );

  testWidgets('AC5: guardar navega a Revisar con la cantidad consumida', (
    tester,
  ) async {
    await _pump(tester, _extraction);
    await _toGrams(tester);

    await tester.enterText(
      find.widgetWithText(TextField, '¿Cuánto comiste? (g)'),
      '45',
    );
    await tester.pump();

    final saveButton = find.widgetWithText(FilledButton, reviewMealButtonLabel);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Revisar (mock)'), findsOneWidget);
  });

  group('SPEC-030', () {
    for (final typed in ['1,4', '1.4']) {
      testWidgets(
        'AC1: "$typed" en proteína habilita Guardar y se guarda 1,4',
        (tester) async {
          final db = await _pump(tester, _unreadableProteinExtraction);
          expect(tester.widget<FilledButton>(_saveButton()).onPressed, isNull);

          await tester.enterText(
            find.widgetWithText(
              TextField,
              'Proteína por porción (g) (no se pudo leer)',
            ),
            typed,
          );
          await tester.pump();
          expect(
            tester.widget<FilledButton>(_saveButton()).onPressed,
            isNotNull,
          );

          await _tapSave(tester);
          final product = await db.select(db.personalProducts).getSingle();
          // 1,4 g en una porción de 30 g → por 100 g.
          expect(product.proteinG100, closeTo(1.4 * 100 / 30, 1e-9));
        },
      );
    }

    testWidgets(
      'AC2: muestra "15", "2,9" y "1,78" y, sin editar, guarda el valor original',
      (tester) async {
        final db = await _pump(tester, _rawDecimalsExtraction);

        expect(find.text('15'), findsOneWidget);
        expect(find.text('2,9'), findsOneWidget);
        expect(find.text('1,78'), findsOneWidget);

        // Estos valores no cuadran por Atwater: se confirma para guardar.
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        await _tapSave(tester);

        final product = await db.select(db.personalProducts).getSingle();
        expect(product.carbsG100, 1.7799999999999998);
      },
    );

    for (final invalid in ['1.200', '1,234']) {
      testWidgets('AC3: "$invalid" en sodio muestra el error y queda vacío', (
        tester,
      ) async {
        final db = await _pump(tester, _extraction);
        final sodium = find.widgetWithText(
          TextField,
          'Sodio por porción (mg, opcional)',
        );
        await tester.enterText(sodium, invalid);
        await tester.pump();
        expect(find.text(labelNumberErrorMessage), findsOneWidget);

        // Opcional: el resto está completo, así que se puede guardar y el
        // sodio queda vacío.
        await _tapSave(tester);
        final product = await db.select(db.personalProducts).getSingle();
        expect(product.sodiumMg100, isNull);
      });
    }

    for (final valid in ['1,2', '0,25']) {
      testWidgets('AC3: "$valid" en sodio es válido', (tester) async {
        await _pump(tester, _extraction);
        await tester.enterText(
          find.widgetWithText(TextField, 'Sodio por porción (mg, opcional)'),
          valid,
        );
        await tester.pump();
        expect(find.text(labelNumberErrorMessage), findsNothing);
      });
    }

    testWidgets('AC4: "Falta: proteína." hasta completarla', (tester) async {
      await _pump(tester, _unreadableProteinExtraction);
      expect(find.text('Falta: proteína.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_saveButton()).onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(
          TextField,
          'Proteína por porción (g) (no se pudo leer)',
        ),
        '2',
      );
      await tester.pump();
      expect(find.textContaining('Falta:'), findsNothing);
      expect(tester.widget<FilledButton>(_saveButton()).onPressed, isNotNull);
    });
  });

  group('SPEC-031', () {
    testWidgets(
      'AC1: porción 27 → 30 cambia "¿Cuánto comiste?" y se registra 30',
      (tester) async {
        await _pump(tester, _serving27Extraction);
        await _toGrams(tester);
        expect(_fieldText(tester, _consumedField()), '27');

        await tester.enterText(_servingField(), '30');
        await tester.pump();
        expect(_fieldText(tester, _consumedField()), '30');

        await _tapSave(tester);
        expect(find.text('cantidad=30.0'), findsOneWidget);
      },
    );

    testWidgets('AC2: porción "27,5" → "¿Cuánto comiste?" muestra "27,5"', (
      tester,
    ) async {
      await _pump(tester, _serving27Extraction);
      await _toGrams(tester);
      await tester.enterText(_servingField(), '27,5');
      await tester.pump();
      expect(_fieldText(tester, _consumedField()), '27,5');
    });

    testWidgets('AC3: sin porción, "¿Cuánto comiste?" queda vacío y falta', (
      tester,
    ) async {
      await _pump(tester, _serving27Extraction);
      await _toGrams(tester);
      await tester.enterText(_servingField(), '');
      await tester.pump();
      expect(_fieldText(tester, _consumedField()), '');
      expect(find.text('Falta: porción, cuánto comiste.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_saveButton()).onPressed, isNull);
    });

    testWidgets(
      'AC4: "45" escrito a mano no cambia con la porción y se registra 45',
      (tester) async {
        await _pump(tester, _serving27Extraction);
        await _toGrams(tester);
        await tester.enterText(_consumedField(), '45');
        await tester.pump();
        await tester.enterText(_servingField(), '30');
        await tester.pump();
        expect(_fieldText(tester, _consumedField()), '45');

        await _tapSave(tester);
        expect(find.text('cantidad=45.0'), findsOneWidget);
      },
    );

    testWidgets('caso borde: porción ilegible completada después', (
      tester,
    ) async {
      await _pump(
        tester,
        const LabelExtractionDto(
          productName: 'Sin porción',
          servingSize: null,
          perServing: LabelNutrientSetDto(
            energyKcal: 70,
            proteinG: 2.8,
            carbsG: 15,
            fatG: 0.2,
          ),
          per100: null,
          unreadableFields: ['serving_size'],
        ),
      );
      await _toGrams(tester);
      expect(_fieldText(tester, _consumedField()), '');

      await tester.enterText(
        find.widgetWithText(TextField, 'Porción (no se pudo leer)'),
        '30',
      );
      await tester.pump();
      expect(_fieldText(tester, _consumedField()), '30');
    });

    testWidgets(
      'caso borde: "¿Cuánto comiste?" borrado deja de seguir a la porción',
      (tester) async {
        await _pump(tester, _serving27Extraction);
        await _toGrams(tester);
        await tester.enterText(_consumedField(), '45');
        await tester.pump();
        await tester.enterText(_consumedField(), '');
        await tester.pump();
        await tester.enterText(_servingField(), '30');
        await tester.pump();

        expect(_fieldText(tester, _consumedField()), '');
        expect(find.text('Falta: cuánto comiste.'), findsOneWidget);
      },
    );

    testWidgets('caso borde: porción "1.200" deja "¿Cuánto comiste?" vacío', (
      tester,
    ) async {
      await _pump(tester, _serving27Extraction);
      await _toGrams(tester);
      await tester.enterText(_servingField(), '1.200');
      await tester.pump();

      expect(_fieldText(tester, _consumedField()), '');
      expect(find.text('Falta: porción, cuánto comiste.'), findsOneWidget);
    });
  });

  group('SPEC-032', () {
    Future<void> typePortions(WidgetTester tester, String text) async {
      await tester.enterText(_portionsField(), text);
      await tester.pump();
    }

    testWidgets(
      'AC1: arranca en 1 porción; "3" → "3 porciones = 81 g" y se registran 81 g',
      (tester) async {
        await _pump(tester, _serving27Extraction);
        expect(_fieldText(tester, _portionsField()), '1');

        await typePortions(tester, '3');
        expect(find.text('3 porciones = 81 g'), findsOneWidget);

        await _tapSave(tester);
        expect(find.text('cantidad=81.0'), findsOneWidget);
        expect(find.text('unidad=g'), findsOneWidget);
      },
    );

    testWidgets(
      'AC2: con 3 porciones, porción 30 → "3 porciones = 90 g" y se registran 90',
      (tester) async {
        await _pump(tester, _serving27Extraction);
        await typePortions(tester, '3');
        await tester.enterText(_servingField(), '30');
        await tester.pump();
        expect(find.text('3 porciones = 90 g'), findsOneWidget);
        expect(_fieldText(tester, _portionsField()), '3');

        await _tapSave(tester);
        expect(find.text('cantidad=90.0'), findsOneWidget);
      },
    );

    testWidgets(
      'AC3: 3 porciones → g muestra "81"; "54" → porciones muestra "2"',
      (tester) async {
        await _pump(tester, _serving27Extraction);
        await typePortions(tester, '3');
        await _toGrams(tester);
        expect(_fieldText(tester, _consumedField()), '81');

        await tester.enterText(_consumedField(), '54');
        await tester.pump();
        await tester.ensureVisible(find.byKey(consumedUnitPortionsKey));
        await tester.tap(find.byKey(consumedUnitPortionsKey));
        await tester.pump();
        expect(_fieldText(tester, _portionsField()), '2');
      },
    );

    testWidgets('AC4: 3 porciones → ~210 kcal y 8,4 / 45,0 / 0,6 g', (
      tester,
    ) async {
      await _pump(tester, _serving27Extraction);
      await typePortions(tester, '3');
      expect(find.text('~210 kcal'), findsOneWidget);
      expect(find.text('8,4'), findsOneWidget);
      expect(find.text('45,0'), findsOneWidget);
      expect(find.text('0,6'), findsOneWidget);
    });

    testWidgets('AC5: con meta, "de 123 g", "de 184 g" y "de 46 g"', (
      tester,
    ) async {
      await _pump(
        tester,
        _serving27Extraction,
        goal: (
          objective: 'maintain',
          isManual: true,
          energyKcal: 1640,
          proteinG: 123,
          carbsG: 184,
          fatG: 46,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('de 123,0 g'), findsOneWidget);
      expect(find.text('de 184,0 g'), findsOneWidget);
      expect(find.text('de 46,0 g'), findsOneWidget);
    });

    testWidgets('AC5: sin meta, solo los gramos', (tester) async {
      await _pump(tester, _serving27Extraction);
      await tester.pumpAndSettle();
      expect(find.text('Vas a registrar'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^de [\d,]+ g$')), findsNothing);
    });

    testWidgets('AC6: sin proteína no hay vista previa', (tester) async {
      await _pump(tester, _unreadableProteinExtraction);
      expect(find.text('Falta: proteína.'), findsOneWidget);
      expect(find.text('Vas a registrar'), findsNothing);
    });

    testWidgets('AC7: "Revisar comida" con la línea que explica qué pasa', (
      tester,
    ) async {
      await _pump(tester, _serving27Extraction);
      expect(_saveButton(), findsOneWidget);
      expect(find.text(reviewMealNote), findsOneWidget);

      await _tapSave(tester);
      expect(find.text('Revisar (mock)'), findsOneWidget);
    });
  });
}
