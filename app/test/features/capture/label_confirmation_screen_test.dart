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

Future<void> _pump(WidgetTester tester, LabelExtractionDto extraction) async {
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
}

void main() {
  testWidgets('AC2/AC4: muestra los valores transcritos, editables', (
    tester,
  ) async {
    await _pump(tester, _extraction);

    expect(find.text('Producto de prueba'), findsOneWidget);
    expect(find.text('140.0'), findsOneWidget); // energy_kcal
    // "30.0" aparece dos veces a propósito: porción Y "cuánto comiste"
    // (R5, por defecto igual a la porción).
    expect(find.text('30.0'), findsNWidgets(2));

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
}
