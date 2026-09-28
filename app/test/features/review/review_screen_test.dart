import 'package:calorias_ia/infra/ai_client/parsed_meal_dto.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/features/review/review_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';

ParsedMealDto _parsedMeal() => ParsedMealDto(
  mealType: null,
  items: [
    const ParsedMealItemDto(
      mention: 'dos huevos',
      foodQuery: 'huevo',
      quantity: 2,
      unit: 'unidad',
      isVague: false,
    ),
    const ParsedMealItemDto(
      mention: 'pollo',
      foodQuery: 'pollo',
      isVague: true,
    ),
  ],
);

Future<void> _pumpReviewScreen(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  final catalog = buildFixtureCatalog();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(catalog),
      ],
      child: MaterialApp(home: ReviewScreen(parsedMeal: _parsedMeal())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AC7: un ítem ambiguous muestra hasta 3 candidatos y deshabilita Registrar',
    (tester) async {
      await _pumpReviewScreen(tester);

      expect(find.text('Pechuga de pollo'), findsOneWidget);
      expect(find.text('Muslo de pollo'), findsOneWidget);

      final registrarButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Registrar'),
      );
      expect(registrarButton.onPressed, isNull);

      await tester.tap(find.text('Pechuga de pollo'));
      await tester.pumpAndSettle();

      final registrarButtonAfter = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Registrar'),
      );
      expect(registrarButtonAfter.onPressed, isNotNull);
    },
  );

  testWidgets(
    'AC8: editar la cantidad con +/- recalcula kcal sin llamadas de red',
    (tester) async {
      await _pumpReviewScreen(tester);

      // "dos huevos" -> 100 g -> 143 kcal.
      expect(find.text('143 kcal'), findsOneWidget);
      expect(find.text('100 g'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();

      // +5 g -> 105 g -> 143 * 1.05 = 150.15 -> 150 kcal. Sin AiClient
      // configurado (aiClientProvider no se sobrescribió): si esto llamara a
      // la red, lanzaría UnimplementedError y el test fallaría.
      expect(find.text('105 g'), findsOneWidget);
      expect(find.text('150 kcal'), findsOneWidget);
    },
  );
}
