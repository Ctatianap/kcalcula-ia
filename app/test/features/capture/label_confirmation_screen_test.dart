import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/capture/label_confirmation_screen.dart';
import 'package:calorias_ia/infra/ai_client/label_extraction_dto.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
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

Future<AppDatabase> _pump(
  WidgetTester tester,
  LabelExtractionDto extraction,
) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => settings.name == AppRoutes.review
              ? const Scaffold(body: Text('Revisar (mock)'))
              : const SizedBox.shrink(),
        ),
        home: LabelConfirmationScreen(extraction: extraction),
      ),
    ),
  );
  return db;
}

Finder _saveButton() =>
    find.widgetWithText(FilledButton, 'Guardar y continuar');

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(_saveButton());
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
    // "30" aparece dos veces a propósito: porción Y "cuánto comiste"
    // (R5, por defecto igual a la porción).
    expect(find.text('30'), findsNWidgets(2));

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
        'Guardar y continuar',
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
        'Guardar y continuar',
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

    await tester.enterText(
      find.widgetWithText(TextField, '¿Cuánto comiste? (g)'),
      '45',
    );
    await tester.pump();

    final saveButton = find.widgetWithText(FilledButton, 'Guardar y continuar');
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
}
