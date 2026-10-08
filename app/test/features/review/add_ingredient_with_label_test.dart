import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/capture/ingredient_label_screen.dart';
import 'package:calorias_ia/features/capture/label_capture_controller.dart';
import 'package:calorias_ia/features/capture/label_confirmation_screen.dart';
import 'package:calorias_ia/features/review/food_search_screen.dart';
import 'package:calorias_ia/features/review/review_screen.dart';
import 'package:calorias_ia/infra/ai_client/ai_client.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_providers.dart';
import 'package:calorias_ia/infra/ai_client/parsed_meal_dto.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/food_resolution/ingredient_label_result.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';
import '../capture/fake_image_picker.dart';

const _huevos = ParsedMealItemDto(
  mention: 'dos huevos',
  foodQuery: 'huevo',
  quantity: 2,
  unit: 'unidad',
  isVague: false,
);

/// Detalle de una comida con "dos huevos", sin productos guardados.
Future<AppDatabase> _pump(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final aiClient = AiClient(
    (data) async => fail('SPEC-040: no se llama a parseMeal'),
    (data) async => fail('SPEC-040 R5: "Escribir los valores" no usa IA'),
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
        home: const ReviewScreen(
          parsedMeal: ParsedMealDto(mealType: null, items: [_huevos]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// "Añadir ingrediente" → buscar [query].
Future<void> _search(WidgetTester tester, String query) async {
  final add = find.text('Añadir ingrediente');
  await tester.ensureVisible(add);
  await tester.pumpAndSettle();
  await tester.tap(add);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('food-search-input')), query);
  await tester.pumpAndSettle();
}

/// "Añadir con etiqueta" → "Escribir los valores".
Future<void> _openManualLabel(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('food-search-add-with-label')));
  await tester.pumpAndSettle();
  expect(find.byType(IngredientLabelScreen), findsOneWidget);
  await tester.tap(find.byKey(const Key('ingredient-label-manual')));
  await tester.pumpAndSettle();
  expect(find.text('Confirmar etiqueta'), findsOneWidget);
}

Future<void> _type(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _save(WidgetTester tester) async {
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

void main() {
  testWidgets(
    'AC1: sin productos guardados, "galletas xyz" muestra el mensaje y el botón',
    (tester) async {
      await _pump(tester);
      await _search(tester, 'galletas xyz');
      expect(find.text(noSearchResultsWithLabelMessage), findsOneWidget);
      expect(find.text(addWithLabelAction), findsOneWidget);
    },
  );

  testWidgets(
    'AC2 + AC3: "Escribir los valores" añade un ingrediente nuevo y lo guarda en Mis productos',
    (tester) async {
      final db = await _pump(tester);
      final before = _quantityText(tester, 'dos huevos');
      await _search(tester, 'galletas xyz');
      await _openManualLabel(tester);

      await _type(tester, 'Porción', '30');
      await _type(tester, 'Calorías por porción (kcal)', '150');
      await _type(tester, 'Proteína por porción (g)', '2');
      await _type(tester, 'Carbohidratos por porción (g)', '20');
      await _type(tester, 'Grasa por porción (g)', '7');
      await _save(tester);

      expect(find.text('Detalle de comida'), findsOneWidget);
      // AC2: el primero no cambió y el nuevo tiene nombre y cantidad.
      expect(_quantityText(tester, 'dos huevos'), before);
      expect(_quantityText(tester, 'galletas xyz'), '1 porción · 30 g');
      expect(find.text('150 kcal'), findsWidgets);

      // AC3.
      final products = await tester.runAsync(
        () => db.select(db.personalProducts).get(),
      );
      expect(products!.single.nameEs, 'galletas xyz');
    },
  );

  testWidgets(
    'AC4: salir sin guardar vuelve a "Buscar alimento" sin cambiar la comida',
    (tester) async {
      final db = await _pump(tester);
      await _search(tester, 'galletas xyz');
      await tester.tap(find.byKey(const Key('food-search-add-with-label')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Buscar alimento'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Detalle de comida'), findsOneWidget);
      expect(
        find.byKey(const Key('ingredient-quantity-galletas xyz')),
        findsNothing,
      );
      final products = await tester.runAsync(
        () => db.select(db.personalProducts).get(),
      );
      expect(products, isEmpty);
    },
  );

  testWidgets(
    '"Buscar alimento" desde el error de análisis no muestra el botón',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
          ],
          child: const MaterialApp(home: FoodSearchScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('food-search-input')),
        'galletas xyz',
      );
      await tester.pumpAndSettle();
      expect(find.text(noSearchResultsMessage), findsOneWidget);
      expect(find.text(addWithLabelAction), findsNothing);
    },
  );
}
