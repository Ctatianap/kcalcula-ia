import 'package:calorias_ia/features/diary/diary_screen.dart';
import 'package:calorias_ia/features/history/history_screen.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:calorias_ia/ui/components/confidence_indicator.dart';
import 'package:calorias_ia/ui/components/meal_card.dart';
import 'package:calorias_ia/ui/confidence_texts.dart';
import 'package:calorias_ia/ui/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../../support/fixture_catalog.dart';
import '../../support/meal_flow_harness.dart';

/// "dos huevos (unidad) y una arepa pequeña": huevo 2 × 50 g = 143 kcal
/// (Buena estimación), arepa pequeña 70 g = 187 kcal (Estimación).
final _eggsAndSmallArepa = parsedMeal([
  parsedItem('dos huevos', 'huevo', quantity: 2, unit: 'unidad'),
  parsedItem('una arepa pequeña', 'arepa', quantity: 1, size: 'pequeno'),
]);

Future<void> _openDetail(WidgetTester tester) async {
  final h = await MealFlowHarness.pump(
    tester,
    aiClient: FakeParseMeal((_) => _eggsAndSmallArepa).client,
  );
  await h.openCaptureAndType(tester, 'dos huevos y una arepa pequeña');
  await tester.ensureVisible(find.text('Analizar'));
  await tester.tap(find.text('Analizar'));
  await tester.pumpAndSettle();
}

const _portionBases = {
  QuantityBasis.unitPortion,
  QuantityBasis.sizeDescriptor,
  QuantityBasis.defaultPortion,
};
const _mlBases = {
  QuantityBasis.explicitWeight,
  QuantityBasis.label,
  QuantityBasis.householdMeasure,
};

Finder _levelIn(String key, String label) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.text(label));

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('SPEC-023 unit', () {
    test('AC4: las 6 bases, densidad, porción curada y cantidad vaga tienen explicación', () {
      final reasons = <ConfidenceReason>{
        for (final basis in QuantityBasis.values)
          for (final level in ConfidenceLevel.values)
            confidenceReasonFor(basis: basis, isVague: false, level: level),
        confidenceReasonFor(
          basis: QuantityBasis.unitPortion,
          isVague: true,
          level: ConfidenceLevel.estimacion,
        ),
        confidenceReasonFor(
          basis: null,
          isVague: false,
          level: ConfidenceLevel.estimacion,
        ),
        // SPEC-043.
        confidenceReasonFor(
          basis: QuantityBasis.defaultPortion,
          isVague: false,
          level: ConfidenceLevel.estimacion,
          withoutEquivalence: true,
        ),
      };
      // Cubre todas las razones.
      expect(reasons, ConfidenceReason.values.toSet());
      for (final reason in ConfidenceReason.values) {
        final e = confidenceExplanation(reason);
        expect(e.title, isNotEmpty);
        expect(e.body, isNotEmpty);
        // Ninguna explicación inventa cifras de nutrientes.
        expect(e.body, isNot(contains('kcal')));
      }
      // Casos de la regla de `itemConfidence`.
      expect(
        confidenceReasonFor(
          basis: QuantityBasis.sizeDescriptor,
          isVague: false,
          level: ConfidenceLevel.estimacion,
        ),
        ConfidenceReason.sizeDescriptor,
      );
      expect(
        confidenceReasonFor(
          basis: QuantityBasis.unitPortion,
          isVague: false,
          level: ConfidenceLevel.estimacion,
        ),
        ConfidenceReason.curatedPortion,
      );
      expect(
        confidenceReasonFor(
          basis: QuantityBasis.explicitWeight,
          isVague: false,
          level: ConfidenceLevel.estimacion,
        ),
        ConfidenceReason.densityFallback,
      );
      expect(
        confidenceReasonFor(
          basis: QuantityBasis.label,
          isVague: false,
          level: ConfidenceLevel.altaPrecision,
        ),
        ConfidenceReason.label,
      );
      // La etiqueta con g/ml no ofrece cómo mejorarla; el resto sí.
      expect(confidenceExplanation(ConfidenceReason.label).actions, isEmpty);
      expect(
        confidenceExplanation(ConfidenceReason.sizeDescriptor).actions,
        contains(ConfidenceAction.writeGrams),
      );
    });

    test(
      'AC4: la razón deducida coincide con la causa real de itemConfidence',
      () {
        for (final basis in QuantityBasis.values) {
          for (final isVague in [false, true]) {
            // Solo lo que produce `resolveGrams`: la porción curada sale de
            // una porción del catálogo y la densidad, de ml.
            for (final curated in [
              false,
              if (_portionBases.contains(basis)) true,
            ]) {
              for (final density in [
                false,
                if (_mlBases.contains(basis)) true,
              ]) {
                final level = itemConfidence(
                  basis: basis,
                  isVague: isVague,
                  usedCuratedEstimatePortion: curated,
                  usedDensityFallback: density,
                  hasLabelGramsOrMl: basis == QuantityBasis.label,
                );
                final reason = confidenceReasonFor(
                  basis: basis,
                  isVague: isVague,
                  level: level,
                );
                final expected = isVague
                    ? ConfidenceReason.vague
                    : switch (basis) {
                        QuantityBasis.label || QuantityBasis.explicitWeight
                            when density =>
                          ConfidenceReason.densityFallback,
                        QuantityBasis.label => ConfidenceReason.label,
                        QuantityBasis.explicitWeight =>
                          ConfidenceReason.explicitWeight,
                        QuantityBasis.unitPortion when curated =>
                          ConfidenceReason.curatedPortion,
                        QuantityBasis.unitPortion =>
                          ConfidenceReason.unitPortion,
                        QuantityBasis.sizeDescriptor =>
                          ConfidenceReason.sizeDescriptor,
                        QuantityBasis.householdMeasure =>
                          ConfidenceReason.householdMeasure,
                        QuantityBasis.defaultPortion =>
                          ConfidenceReason.defaultPortion,
                      };
                expect(
                  reason,
                  expected,
                  reason:
                      '$basis vaga:$isVague curada:$curated densidad:$density',
                );
              }
            }
          }
        }
      },
    );

    test(
      'AC5: sin rojo ni verde de alarma; contraste ≥ 3:1 en fondo y tarjeta',
      () {
        expect(confidenceIndicatorColor, isNot(KColors.error));
        expect(confidenceIndicatorColor, isNot(KColors.confirmText));
        final hsl = HSLColor.fromColor(confidenceIndicatorColor);
        // Ni rojo (≈0°) ni verde (≈120°) saturados.
        expect(hsl.hue < 20 || hsl.hue > 340, isFalse);
        expect(hsl.hue > 90 && hsl.hue < 150, isFalse);
        expect(
          _contrast(confidenceIndicatorColor, KColors.background),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(confidenceIndicatorColor, KColors.surfaceSoft),
          greaterThanOrEqualTo(3),
        );
      },
    );
  });

  testWidgets(
    'AC1: cada nivel muestra su ícono, su texto y su etiqueta semántica',
    (tester) async {
      final semantics = tester.ensureSemantics();
      for (final level in ConfidenceLevel.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ConfidenceIndicator(level: level)),
          ),
        );
        expect(find.byIcon(confidenceIcon(level)), findsOneWidget);
        expect(find.text(confidenceLevelLabels[level]!), findsOneWidget);
        expect(
          find.bySemanticsLabel(confidenceSemanticLabel(level)),
          findsOneWidget,
        );
      }
      expect(
        confidenceSemanticLabel(ConfidenceLevel.buenaEstimacion),
        'Confianza: buena estimación',
      );
      // Íconos distintos: el nivel no depende solo del texto ni del color.
      expect(ConfidenceLevel.values.map(confidenceIcon).toSet(), hasLength(3));
      semantics.dispose();
    },
  );

  testWidgets(
    'AC2: arepa Estimación, huevo Buena estimación y la comida por la regla del 15 %',
    (tester) async {
      await _openDetail(tester);
      expect(
        _levelIn('ingredient-confidence-una arepa pequeña', 'Estimación'),
        findsOneWidget,
      );
      expect(
        _levelIn('ingredient-confidence-dos huevos', 'Buena estimación'),
        findsOneWidget,
      );
      // 187 kcal de 330 (57 %) es Estimación: la comida queda en Estimación.
      expect(_levelIn('meal-confidence', 'Estimación'), findsOneWidget);
    },
  );

  testWidgets(
    'AC3: "¿Por qué?" de la arepa explica el tamaño y "Escribe los gramos" la ajusta',
    (tester) async {
      await _openDetail(tester);
      final indicator = find.byKey(
        const Key('ingredient-confidence-una arepa pequeña'),
      );
      await tester.ensureVisible(indicator);
      await tester.pumpAndSettle();
      await tester.tap(indicator);
      await tester.pumpAndSettle();
      final sizeText = confidenceExplanation(ConfidenceReason.sizeDescriptor);
      expect(find.text(sizeText.title), findsOneWidget);
      expect(find.text(sizeText.body), findsOneWidget);
      expect(find.text(useLabelHelpAction), findsOneWidget);

      await tester.tap(find.text(writeGramsAction));
      await tester.pumpAndSettle();
      expect(find.text('¿Cuánto Arepa?'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('write-quantity')), '90');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Listo'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('ingredient-quantity-una arepa pequeña')),
            )
            .data,
        '90 g',
      );
      // Peso escrito: "Buena estimación" por la regla de `nutrition_core`.
      expect(
        _levelIn('ingredient-confidence-una arepa pequeña', 'Buena estimación'),
        findsOneWidget,
      );
      expect(_levelIn('meal-confidence', 'Buena estimación'), findsOneWidget);
      // La tarjeta dice cómo se obtuvo y "¿Por qué?" da la razón nueva.
      expect(find.text('Cantidad dicha por ti'), findsWidgets);
      await tester.tap(indicator);
      await tester.pumpAndSettle();
      expect(
        find.text(confidenceExplanation(ConfidenceReason.explicitWeight).title),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'MINOR: el indicador de un ingrediente tiene área táctil de 48 dp',
    (tester) async {
      await _openDetail(tester);
      expect(
        tester
            .getSize(
              find.byKey(const Key('ingredient-confidence-una arepa pequeña')),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
    },
  );

  testWidgets(
    'R3: la explicación de la comida da la regla y los ingredientes con su nivel',
    (tester) async {
      await _openDetail(tester);
      await tester.tap(find.byKey(const Key('meal-confidence')));
      await tester.pumpAndSettle();
      expect(find.text('Confianza de la comida'), findsOneWidget);
      expect(
        find.textContaining('Ingredientes con este nivel: Arepa.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Edge: texto grande ×2 en 360 px, sin desbordes', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openDetail(tester);
    expect(tester.takeException(), isNull);
  });

  group('AC6: Hoy e Historial', () {
    final now = DateTime(2026, 10, 8, 12);

    Future<void> pump(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.runAsync(
        () => StorageRepository(db).registerMeal(
          eatenAt: DateTime(2026, 10, 8, 8),
          mealType: 'desayuno',
          confidence: 'estimacion',
          catalogVersion: 'test-1',
          items: const [
            MealItemRecord(
              mention: 'una arepa pequeña',
              foodId: 'arepa',
              nameSnapshot: 'Arepa',
              grams: 70,
              quantityBasis: 'sizeDescriptor',
              energyKcal: 186.9,
              proteinG: 4,
              carbsG: 21,
              fatG: 10,
              confidence: 'estimacion',
              sourceRef: 'fixture',
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
            clockProvider.overrideWithValue(() => now),
          ],
          child: MaterialApp(home: home),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder levelInCard(String label) =>
        find.descendant(of: find.byType(MealCard), matching: find.text(label));

    testWidgets(
      'Hoy: la tarjeta muestra el nivel guardado y el total conserva "~"',
      (tester) async {
        await pump(tester, const DiaryScreen());
        expect(levelInCard('Estimación'), findsOneWidget);
        expect(find.textContaining('~187'), findsWidgets);
      },
    );

    testWidgets('Historial: la tarjeta muestra el nivel guardado', (
      tester,
    ) async {
      await pump(tester, const HistoryScreen());
      // El historial abre en hoy (fecha del reloj de prueba).
      expect(levelInCard('Estimación'), findsOneWidget);
      expect(find.textContaining('~'), findsWidgets);
    });
  });
}
