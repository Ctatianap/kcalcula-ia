import 'dart:async';

import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/capture/ingredient_label_screen.dart';
import 'package:calorias_ia/features/capture/label_capture_controller.dart';
import 'package:calorias_ia/features/capture/label_confirmation_screen.dart';
import 'package:calorias_ia/features/review/meal_detail_view.dart';
import 'package:calorias_ia/features/review/personal_product_picker_screen.dart';
import 'package:calorias_ia/features/review/review_screen.dart';
import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_providers.dart';
import 'package:calorias_ia/infra/ai_client/parsed_meal_dto.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/food_resolution/ingredient_label_result.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/ui/personal_products_texts.dart';
import 'package:calorias_ia/ui/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';
import '../capture/fake_image_picker.dart';

Map<String, Object?> _label({
  required String? name,
  required double servingGrams,
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
  String unit = 'g',
}) => {
  'schema_version': 'label_extraction.v1',
  'product_name': name,
  'serving_size': {'quantity': servingGrams, 'unit': unit},
  'per_serving': {
    'energy_kcal': kcal,
    'protein_g': protein,
    'carbs_g': carbs,
    'fat_g': fat,
    'fiber_g': null,
    'sugar_g': null,
    'sodium_mg': null,
  },
  'per_100': null,
  'unreadable_fields': <String>[],
};

/// Cuenta las llamadas a la IA: `parseMeal` nunca debe llamarse (R6).
class _AiCalls {
  int parseMeal = 0;
  int extractLabel = 0;
}

Future<({AppDatabase db, _AiCalls calls})> _pump(
  WidgetTester tester, {
  required List<ParsedMealItemDto> items,
  Map<String, Object?>? labelResponse,
  Future<void>? labelDelay,

  /// SPEC-034: nombres alternativos del primer producto.
  List<String> firstProductAliases = const [],
  List<
        ({
          String name,
          double servingGrams,
          double kcal100,
          double protein100,
          double carbs100,
          double fat100,
        })
      >
      products =
      const [],
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = StorageRepository(db);
  for (final (i, p) in products.indexed) {
    final id = await tester.runAsync(
      () => repo.savePersonalProduct(
        nameEs: p.name,
        energyKcal100: p.kcal100,
        proteinG100: p.protein100,
        carbsG100: p.carbs100,
        fatG100: p.fat100,
        servingGrams: p.servingGrams,
        sourceRef: 'test',
      ),
    );
    if (i == 0 && firstProductAliases.isNotEmpty) {
      await tester.runAsync(
        () => repo.updatePersonalProduct(
          id: id!,
          nameEs: p.name,
          servingUnit: 'g',
          aliases: firstProductAliases,
        ),
      );
    }
  }
  final calls = _AiCalls();
  final aiClient = AiClient(
    (data) async {
      calls.parseMeal++;
      fail('SPEC-033 R6: no se vuelve a llamar a parseMeal');
    },
    (data) async {
      calls.extractLabel++;
      if (labelDelay != null) await labelDelay;
      if (labelResponse == null) fail('No se esperaba leer una etiqueta');
      return labelResponse;
    },
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
        aiClientProvider.overrideWithValue(aiClient),
        cameraPermissionProvider.overrideWithValue(
          FakeCameraPermission(granted: true),
        ),
        imagePickerServiceProvider.overrideWithValue(
          FakeImagePickerService(cameraResult: fakeImageBytes),
        ),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) => switch (settings.name) {
          AppRoutes.ingredientLabel => MaterialPageRoute<IngredientLabelResult>(
            settings: settings,
            builder: (_) => IngredientLabelScreen(
              ingredientName: settings.arguments as String,
            ),
          ),
          _ => null,
        },
        home: ReviewScreen(
          parsedMeal: ParsedMealDto(mealType: null, items: items),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (db: db, calls: calls);
}

Future<void> _openMenu(
  WidgetTester tester,
  String mention,
  String action,
) async {
  final menu = find.byKey(Key('ingredient-menu-$mention'));
  await tester.ensureVisible(menu);
  await tester.pumpAndSettle();
  await tester.tap(menu);
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

/// "Usar etiqueta" → "Tomar foto" → "Usar en este ingrediente".
Future<void> _useLabel(
  WidgetTester tester,
  String mention, {
  String? portions,
}) async {
  await _openMenu(tester, mention, useLabelAction);
  expect(find.byType(IngredientLabelScreen), findsOneWidget);
  await tester.tap(find.text('Tomar foto'));
  await tester.pumpAndSettle();
  expect(find.text('Confirmar etiqueta'), findsOneWidget);
  if (portions != null) {
    final field = find.widgetWithText(
      TextField,
      '¿Cuánto comiste? (porciones)',
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, portions);
    await tester.pump();
  }
  final button = find.widgetWithText(FilledButton, useInIngredientButtonLabel);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

String _quantityText(WidgetTester tester, String mention) =>
    tester.widget<Text>(find.byKey(Key('ingredient-quantity-$mention'))).data!;

const _huevos = ParsedMealItemDto(
  mention: 'dos huevos',
  foodQuery: 'huevo',
  quantity: 2,
  unit: 'unidad',
  isVague: false,
);

void main() {
  testWidgets(
    'AC1: "Usar etiqueta" cambia ese ingrediente al producto nuevo y vuelve al Detalle',
    (tester) async {
      final pumped = await _pump(
        tester,
        items: const [
          _huevos,
          ParsedMealItemDto(
            mention: 'una arepa',
            foodQuery: 'arepa',
            quantity: 1,
            unit: 'unidad',
            isVague: false,
          ),
        ],
        labelResponse: _label(
          name: 'Pan de prueba',
          servingGrams: 27,
          kcal: 70,
          protein: 2.8,
          carbs: 15,
          fat: 0.2,
        ),
      );
      expect(find.text('Arepa'), findsOneWidget);

      await _useLabel(tester, 'una arepa');

      expect(find.text('Detalle de comida'), findsOneWidget);
      expect(find.text('Pan de prueba'), findsWidgets);
      expect(find.text('Arepa'), findsNothing);
      // Los demás ingredientes no cambian.
      expect(find.text('Huevo'), findsWidgets);
      expect(_quantityText(tester, 'dos huevos'), '100 g');
      final products = await tester.runAsync(
        () => pumped.db.select(pumped.db.personalProducts).get(),
      );
      expect(products!.single.nameEs, 'Pan de prueba');
      // Invariante 8: el modo normal sigue diciendo que lo transcribió la IA.
      expect(
        products.single.sourceRef,
        startsWith(
          'Etiqueta transcrita por IA y confirmada por el usuario el ',
        ),
      );
      expect(pumped.calls.extractLabel, 1);
      expect(pumped.calls.parseMeal, 0);
    },
  );

  testWidgets(
    'AC2: "Elegir de mis productos" usa la leche guardada con 250 ml y sin IA',
    (tester) async {
      final pumped = await _pump(
        tester,
        items: const [
          ParsedMealItemDto(
            mention: '250 ml de leche',
            foodQuery: 'leche',
            quantity: 250,
            unit: 'ml',
            isVague: false,
          ),
        ],
        products: const [
          (
            name: 'Leche deslactosada',
            servingGrams: 200,
            kcal100: 45,
            protein100: 3.1,
            carbs100: 4.8,
            fat100: 1.5,
          ),
        ],
      );

      await _openMenu(tester, '250 ml de leche', pickProductAction);
      expect(find.byType(PersonalProductPickerScreen), findsOneWidget);
      await tester.tap(find.text('Leche deslactosada'));
      await tester.pumpAndSettle();

      expect(find.text('Leche deslactosada'), findsWidgets);
      // 250 ml con densidad desconocida = 250 g (como hoy) → 45 × 2,5.
      expect(_quantityText(tester, '250 ml de leche'), contains('250 g'));
      expect(find.text('113 kcal'), findsWidgets);
      expect(pumped.calls.extractLabel, 0);
      expect(pumped.calls.parseMeal, 0);
    },
  );

  testWidgets(
    'AC3: "1 scoop" sin porción "scoop" usa lo elegido en Confirmar (2 porciones = 60 g) y queda destacado',
    (tester) async {
      await _pump(
        tester,
        items: const [
          ParsedMealItemDto(
            mention: '1 scoop de proteína',
            foodQuery: 'proteína en polvo',
            quantity: 1,
            unit: 'unidad',
            isVague: false,
          ),
        ],
        labelResponse: _label(
          name: 'Proteína de prueba',
          servingGrams: 30,
          kcal: 120,
          protein: 24,
          carbs: 3,
          fat: 1.5,
        ),
      );

      await _useLabel(tester, '1 scoop de proteína', portions: '2');

      // La cantidad de "Confirmar etiqueta" (2 porciones), no la porción
      // por defecto.
      expect(
        _quantityText(tester, '1 scoop de proteína'),
        '2 porciones · 60 g',
      );
      // Destacado para revisar, como hoy: el texto de la cantidad en el color
      // de acento.
      final source = tester.widget<Text>(find.text('Cantidad dicha por ti'));
      expect(source.style?.color, KColors.accent);
    },
  );

  testWidgets(
    'AC4: 3 porciones de un producto de 27 g → 81 g y el total se recalcula',
    (tester) async {
      await _pump(
        tester,
        items: const [
          ParsedMealItemDto(mention: 'pan', foodQuery: 'pan', isVague: false),
        ],
        products: const [
          (
            name: 'Pan tajado',
            servingGrams: 27,
            kcal100: 70 * 100 / 27,
            protein100: 2.8 * 100 / 27,
            carbs100: 15 * 100 / 27,
            fat100: 0.2 * 100 / 27,
          ),
        ],
      );
      await _openMenu(tester, 'pan', pickProductAction);
      await tester.tap(find.text('Pan tajado'));
      await tester.pumpAndSettle();
      expect(_quantityText(tester, 'pan'), '1 porción · 27 g');

      final plus = find.byTooltip('Más');
      for (var i = 0; i < 4; i++) {
        await tester.ensureVisible(plus.first);
        await tester.pumpAndSettle();
        await tester.tap(plus.first);
        await tester.pumpAndSettle();
      }
      expect(_quantityText(tester, 'pan'), '3 porciones · 81 g');
      // 70 kcal por porción × 3; ítem y total.
      expect(find.text('210 kcal'), findsWidgets);

      await tester.tap(find.byKey(const Key('ingredient-toggle-unit-pan')));
      await tester.pumpAndSettle();
      expect(_quantityText(tester, 'pan'), '81 g');
    },
  );

  testWidgets('AC5: sin productos guardados, el mensaje de R4', (tester) async {
    await _pump(tester, items: const [_huevos]);
    await _openMenu(tester, 'dos huevos', pickProductAction);
    expect(find.text(noPersonalProductsMessage), findsOneWidget);
  });

  testWidgets(
    'AC6: un ingrediente no encontrado tiene las acciones y con etiqueta pasa a encontrado',
    (tester) async {
      await _pump(
        tester,
        items: const [
          ParsedMealItemDto(
            mention: 'un caldo de costilla',
            foodQuery: 'caldo de costilla',
            quantity: 1,
            unit: 'porcion',
            isVague: false,
          ),
        ],
        labelResponse: _label(
          name: null,
          servingGrams: 300,
          kcal: 180,
          protein: 14,
          carbs: 10,
          fat: 9,
        ),
      );
      expect(find.text('No encontrado en la base'), findsOneWidget);

      await _useLabel(tester, 'un caldo de costilla');

      expect(find.text('No encontrado en la base'), findsNothing);
      // Sin nombre leído, el producto se llama como el ingrediente (R2).
      expect(find.text('caldo de costilla'), findsWidgets);
      expect(
        _quantityText(tester, 'un caldo de costilla'),
        '1 porción · 300 g',
      );
    },
  );

  testWidgets(
    'R3: sin cantidad dicha, usa la cantidad de "Confirmar etiqueta"',
    (tester) async {
      await _pump(
        tester,
        items: const [
          ParsedMealItemDto(mention: 'pan', foodQuery: 'pan', isVague: false),
        ],
        labelResponse: _label(
          name: 'Pan de prueba',
          servingGrams: 27,
          kcal: 70,
          protein: 2.8,
          carbs: 15,
          fat: 0.2,
        ),
      );
      await _useLabel(tester, 'pan', portions: '3');
      expect(_quantityText(tester, 'pan'), '3 porciones · 81 g');
    },
  );

  testWidgets('R5: "+" y "−" pasan a la media porción siguiente', (
    tester,
  ) async {
    await _pump(
      tester,
      items: const [
        ParsedMealItemDto(
          mention: '100 g de proteína',
          foodQuery: 'proteína',
          quantity: 100,
          unit: 'g',
          isVague: false,
        ),
      ],
      products: const [
        (
          name: 'Proteína guardada',
          servingGrams: 30,
          kcal100: 400,
          protein100: 80,
          carbs100: 10,
          fat100: 5,
        ),
      ],
    );
    await _openMenu(tester, '100 g de proteína', pickProductAction);
    await tester.tap(find.text('Proteína guardada'));
    await tester.pumpAndSettle();
    // 100 g / 30 g = 3,33 porciones.
    expect(_quantityText(tester, '100 g de proteína'), '3,3 porciones · 100 g');

    await tester.ensureVisible(find.byTooltip('Más'));
    await tester.tap(find.byTooltip('Más'));
    await tester.pumpAndSettle();
    expect(_quantityText(tester, '100 g de proteína'), '3,5 porciones · 105 g');

    await tester.tap(find.byTooltip('Menos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menos'));
    await tester.pumpAndSettle();
    expect(_quantityText(tester, '100 g de proteína'), '2,5 porciones · 75 g');
  });

  testWidgets(
    'caso borde: salir mientras se lee la etiqueta no deja errores y el Detalle no cambia',
    (tester) async {
      final release = Completer<void>();
      final pumped = await _pump(
        tester,
        items: const [_huevos],
        labelDelay: release.future,
        labelResponse: _label(
          name: 'No debería guardarse',
          servingGrams: 30,
          kcal: 100,
          protein: 5,
          carbs: 10,
          fat: 4,
        ),
      );
      await _openMenu(tester, 'dos huevos', useLabelAction);
      await tester.tap(find.text('Tomar foto'));
      await tester.pump();
      expect(find.text('Analizando foto…'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Detalle de comida'), findsOneWidget);

      release.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Confirmar etiqueta'), findsNothing);
      expect(_quantityText(tester, 'dos huevos'), '100 g');
      final products = await tester.runAsync(
        () => pumped.db.select(pumped.db.personalProducts).get(),
      );
      expect(products, isEmpty);
    },
  );

  testWidgets(
    'AC8: "Escribir los valores" guarda el producto sin llamar a la IA',
    (tester) async {
      final pumped = await _pump(
        tester,
        items: const [
          ParsedMealItemDto(
            mention: '1 scoop de proteína',
            foodQuery: 'proteína',
            quantity: 1,
            unit: 'unidad',
            isVague: false,
          ),
        ],
      );
      await _openMenu(tester, '1 scoop de proteína', useLabelAction);
      await tester.tap(find.byKey(const Key('ingredient-label-manual')));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar etiqueta'), findsOneWidget);

      Future<void> type(String label, String value) async {
        final field = find.widgetWithText(TextField, label);
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pump();
      }

      await type('Porción', '30');
      await type('Calorías por porción (kcal)', '120');
      await type('Proteína por porción (g)', '24');
      await type('Carbohidratos por porción (g)', '3');
      await type('Grasa por porción (g)', '1,5');

      final button = find.widgetWithText(
        FilledButton,
        useInIngredientButtonLabel,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Detalle de comida'), findsOneWidget);
      // Sin nombre escrito, el producto se llama como el ingrediente.
      expect(find.text('proteína'), findsWidgets);
      expect(_quantityText(tester, '1 scoop de proteína'), '1 porción · 30 g');
      expect(find.text('120 kcal'), findsWidgets);
      expect(pumped.calls.extractLabel, 0);
      expect(pumped.calls.parseMeal, 0);
      final products = await tester.runAsync(
        () => pumped.db.select(pumped.db.personalProducts).get(),
      );
      expect(
        products!.single.sourceRef,
        startsWith('Valores de la etiqueta escritos por el usuario el '),
      );
    },
  );

  testWidgets(
    'SPEC-034 AC7: una etiqueta de 200 ml se guarda en ml y se muestra en ml',
    (tester) async {
      final pumped = await _pump(
        tester,
        items: const [
          ParsedMealItemDto(
            mention: 'leche',
            foodQuery: 'leche',
            isVague: false,
          ),
        ],
        labelResponse: _label(
          name: 'Leche deslactosada',
          servingGrams: 200,
          kcal: 90,
          protein: 6,
          carbs: 10,
          fat: 3,
          unit: 'ml',
        ),
      );
      await _useLabel(tester, 'leche');
      expect(_quantityText(tester, 'leche'), '1 porción · 200 ml');
      expect(find.text('Ver en ml'), findsOneWidget);
      final products = await tester.runAsync(
        () => pumped.db.select(pumped.db.personalProducts).get(),
      );
      expect(products!.single.servingUnit, 'ml');

      await _openMenu(tester, 'leche', pickProductAction);
      expect(find.text('1 porción = 200,0 ml · 90 kcal'), findsOneWidget);
    },
  );

  testWidgets(
    'SPEC-034 AC2: "mi pan" queda con el producto en el Detalle, sin "¿Cuál de estos?"',
    (tester) async {
      await _pump(
        tester,
        items: const [
          ParsedMealItemDto(
            mention: 'mi pan',
            foodQuery: 'mi pan',
            isVague: false,
          ),
        ],
        products: const [
          (
            name: 'Pan tajado integral',
            servingGrams: 27,
            kcal100: 70 * 100 / 27,
            protein100: 2.8 * 100 / 27,
            carbs100: 15 * 100 / 27,
            fat100: 0.2 * 100 / 27,
          ),
        ],
        firstProductAliases: const ['mi pan'],
      );
      expect(find.text('Pan tajado integral'), findsWidgets);
      expect(find.text('¿Cuál de estos?'), findsNothing);
      expect(find.text('No encontrado en la base'), findsNothing);
      expect(_quantityText(tester, 'mi pan'), '1 porción · 27 g');
    },
  );
}
