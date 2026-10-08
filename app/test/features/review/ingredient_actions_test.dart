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
}) => {
  'schema_version': 'label_extraction.v1',
  'product_name': name,
  'serving_size': {'quantity': servingGrams, 'unit': 'g'},
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
  for (final p in products) {
    await tester.runAsync(
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
  }
  final calls = _AiCalls();
  final aiClient = AiClient(
    (data) async {
      calls.parseMeal++;
      fail('SPEC-033 R6: no se vuelve a llamar a parseMeal');
    },
    (data) async {
      calls.extractLabel++;
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
Future<void> _useLabel(WidgetTester tester, String mention) async {
  await _openMenu(tester, mention, useLabelAction);
  expect(find.byType(IngredientLabelScreen), findsOneWidget);
  await tester.tap(find.text('Tomar foto'));
  await tester.pumpAndSettle();
  expect(find.text('Confirmar etiqueta'), findsOneWidget);
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
      expect(find.text('113 kcal'), findsWidgets);
      expect(pumped.calls.extractLabel, 0);
      expect(pumped.calls.parseMeal, 0);
    },
  );

  testWidgets(
    'AC3: "1 scoop" sin porción "scoop" usa 1 porción de la etiqueta (30 g) y queda destacado',
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

      await _useLabel(tester, '1 scoop de proteína');

      expect(_quantityText(tester, '1 scoop de proteína'), '1 porción · 30 g');
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
}
