import 'dart:async';

import 'package:calorias_ia/features/capture/capture_screen.dart';
import 'package:calorias_ia/features/review/meal_analysis_controller.dart';
import 'package:calorias_ia/features/review/meal_analysis_screen.dart';
import 'package:calorias_ia/infra/ai_client/ai_client_errors.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';
import '../../support/meal_flow_harness.dart';

/// `user.db` cuya lectura de productos personales espera a que el test la
/// libere: así se ve el paso 2 terminado antes de los pasos 3 y 4.
class _SlowStorage extends StorageRepository {
  final release = Completer<void>();

  _SlowStorage(super.db);

  @override
  Future<List<PersonalProduct>> getAllPersonalProducts() async {
    await release.future;
    return super.getAllPersonalProducts();
  }
}

int _doneSteps(WidgetTester tester) =>
    [for (var i = 0; i < 4; i++) find.byKey(Key('analysis-step-done-$i'))]
        .where((f) => f.evaluate().isNotEmpty)
        .length;

const _timeout = AiClientException(
  AiClientErrorType.network,
  'Sin conexión. Revisa tu internet e intenta de nuevo.',
  code: 'deadline-exceeded',
);

void main() {
  group('MealAnalysisController', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('AC2: los pasos se marcan en orden 0 → 2 → 3 → 4 y luego el '
        'detalle', () async {
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      final controller = MealAnalysisController(
        text: 'dos huevos y una arepa',
        aiClient: FakeParseMeal((_) => eggsAndArepa).client,
        storage: StorageRepository(db),
        catalog: catalog,
        stepHold: Duration.zero,
      );
      final seen = <Object>[];
      controller.addListener(() {
        final s = controller.state;
        seen.add(switch (s) {
          AnalysisInProgress(:final completedSteps) => completedSteps,
          AnalysisReady() => 'ready',
          AnalysisFailed() => 'failed',
        });
      });
      await controller.run();
      expect(seen, [0, 2, 3, 4, 'ready']);
      final ready = controller.state as AnalysisReady;
      expect(ready.review.items.map((i) => i.grams), [100, 115]);
      controller.dispose();
    });

    test('AC3: tras cancelar, una respuesta tardía se ignora', () async {
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      final response = Completer<Map<String, dynamic>>();
      final controller = MealAnalysisController(
        text: 'dos huevos',
        aiClient: FakeParseMeal((_) => response.future).client,
        storage: StorageRepository(db),
        catalog: catalog,
        stepHold: Duration.zero,
      );
      final running = controller.run();
      controller.cancel();
      response.complete(eggsAndArepa);
      await running;
      expect(controller.state, isA<AnalysisInProgress>());
      expect((controller.state as AnalysisInProgress).completedSteps, 0);
      controller.dispose();
    });

    test('edge case: la IA responde sin alimentos', () async {
      final catalog = buildFixtureCatalog();
      addTearDown(catalog.close);
      final controller = MealAnalysisController(
        text: 'hola',
        aiClient: FakeParseMeal((_) => parsedMeal([])).client,
        storage: StorageRepository(db),
        catalog: catalog,
      );
      await controller.run();
      final failed = controller.state as AnalysisFailed;
      expect(failed.message, 'No encontré alimentos en lo que escribiste');
      expect(failed.isAiError, isTrue);
      controller.dispose();
    });
  });

  testWidgets('AC1: tres pestañas, Texto por defecto, contador 0/500, '
      'Analizar deshabilitado y nota de privacidad', (tester) async {
    await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => eggsAndArepa).client,
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Texto'), findsOneWidget);
    expect(find.text('Voz'), findsOneWidget);
    expect(find.text('Foto'), findsOneWidget);
    final tabs = tester.widget<SegmentedButton<CaptureTab>>(
      find.byType(SegmentedButton<CaptureTab>),
    );
    expect(tabs.selected, {CaptureTab.text});
    expect(find.text('0/500'), findsOneWidget);
    final analyze = find.widgetWithText(FilledButton, 'Analizar');
    expect(tester.widget<FilledButton>(analyze).onPressed, isNull);
    expect(
      find.text(
        'Tu texto o foto se envía a la IA solo para estructurarlo. Las '
        'calorías las calcula tu teléfono.',
      ),
      findsOneWidget,
    );

    // Foto: tabla nutricional (la foto del plato es F2).
    await tester.tap(find.text('Foto'));
    await tester.pumpAndSettle();
    expect(find.text('Foto de la tabla nutricional'), findsOneWidget);
  });

  testWidgets('AC2: pasos 1-2 con la respuesta de la IA; 3-4 con la '
      'resolución y el cálculo locales', (tester) async {
    final response = Completer<Map<String, dynamic>>();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final slow = _SlowStorage(db);
    final catalog = buildFixtureCatalog();
    addTearDown(catalog.close);
    await tester.pumpWidget(
      MealFlowScope(
        db: db,
        catalog: catalog,
        aiClient: FakeParseMeal((_) => response.future).client,
        storage: slow,
        child: const MaterialApp(
          home: MealAnalysisScreen(text: 'dos huevos y una arepa'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('“dos huevos y una arepa”'), findsOneWidget);
    for (final step in analysisSteps) {
      expect(find.text(step), findsOneWidget);
    }
    expect(find.text('Cancelar'), findsOneWidget);
    expect(_doneSteps(tester), 0);

    response.complete(eggsAndArepa);
    await tester.pump();
    await tester.pump();
    expect(_doneSteps(tester), 2);
    expect(find.byKey(const Key('analysis-step-done-2')), findsNothing);

    slow.release.complete();
    await tester.pump();
    await tester.pump();
    expect(_doneSteps(tester), 4);
    expect(find.text('Detalle de comida'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Detalle de comida'), findsOneWidget);
  });

  testWidgets('AC3: Cancelar vuelve con el texto intacto y la respuesta '
      'tardía no navega ni guarda', (tester) async {
    final response = Completer<Map<String, dynamic>>();
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => response.future).client,
    );
    await h.openCaptureAndType(tester, 'dos huevos y una arepa');
    await tester.tap(find.text('Analizar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Analizando'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.text('dos huevos y una arepa'), findsOneWidget);

    response.complete(eggsAndArepa);
    await tester.pumpAndSettle();
    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.text('Detalle de comida'), findsNothing);
    expect(
      await h.storage.mealsBetween(DateTime(2000), DateTime(2100)),
      isEmpty,
    );
  });

  testWidgets('edge case: un doble toque en Analizar abre un solo análisis', (
    tester,
  ) async {
    final fake = FakeParseMeal((_) => eggsAndArepa);
    final h = await MealFlowHarness.pump(tester, aiClient: fake.client);
    await h.openCaptureAndType(tester, 'dos huevos y una arepa');
    await tester.tap(find.text('Analizar'));
    await tester.tap(find.text('Analizar'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(fake.texts, ['dos huevos y una arepa']);
    expect(find.text('Detalle de comida'), findsOneWidget);
  });

  testWidgets('AC4: el tipo de comida se cambia con botones y se guarda; '
      '−/+ ajusta gramos y kcal', (tester) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => eggsAndArepa).client,
      // 8:00 → desayuno por la hora.
      clock: () => DateTime(2026, 10, 3, 8),
    );
    await h.openCaptureAndType(tester, 'dos huevos y una arepa');
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();

    expect(find.text('Huevo y Arepa'), findsOneWidget);
    expect(find.text('8:00 · sábado 3 de octubre'), findsOneWidget);
    expect(find.text('Cantidad dicha por ti'), findsNWidgets(2));
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('meal-type-desayuno')))
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('meal-type-cena')));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('meal-type-cena')))
          .selected,
      isTrue,
    );

    // Huevo 100 g → 143 kcal; +5 g → 105 g → 150 kcal.
    expect(find.text('143 kcal'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Más').first);
    await tester.tap(find.byTooltip('Más').first);
    await tester.pump();
    expect(find.text('105 g'), findsOneWidget);
    expect(find.text('150 kcal'), findsOneWidget);
    await tester.tap(find.byTooltip('Menos').first);
    await tester.pump();
    expect(find.text('143 kcal'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final meals = await h.storage.mealsBetween(DateTime(2000), DateTime(2100));
    expect(meals, hasLength(1));
    expect(meals.single.meal.mealType, 'cena');
  });

  testWidgets('AC4: "Corregir" vuelve a "¿Qué comiste?" con el texto', (
    tester,
  ) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => eggsAndArepa).client,
    );
    await h.openCaptureAndType(tester, 'dos huevos y una arepa');
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corregir'));
    await tester.pumpAndSettle();
    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.text('dos huevos y una arepa'), findsOneWidget);
    expect(
      await h.storage.mealsBetween(DateTime(2000), DateTime(2100)),
      isEmpty,
    );
  });

  testWidgets('AC5: el sello "Base verificada" aparece con todos los ítems '
      'resueltos', (tester) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => eggsAndArepa).client,
    );
    await h.openCaptureAndType(tester, 'dos huevos y una arepa');
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    expect(find.text('Base verificada'), findsOneWidget);
  });

  testWidgets('AC5: sin sello si un ítem queda sin resolver; Guardar sigue '
      'deshabilitado', (tester) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal(
        (_) => parsedMeal([
          parsedItem('dos huevos', 'huevo', quantity: 2, unit: 'unidad'),
          parsedItem('un chontaduro', 'chontaduro', quantity: 1),
        ]),
      ).client,
    );
    await h.openCaptureAndType(tester, 'dos huevos y un chontaduro');
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    expect(find.text('Base verificada'), findsNothing);
    expect(find.text('No encontrado en la base'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Guardar');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    // Al quitarlo, todo lo que queda tiene fuente.
    await tester.ensureVisible(find.text('Quitar'));
    await tester.tap(find.text('Quitar'));
    await tester.pump();
    expect(find.text('Base verificada'), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  testWidgets('AC6: con la IA en timeout se ve el error con 3 consejos; '
      '"Reintentar" envía el mismo texto', (tester) async {
    var calls = 0;
    final fake = FakeParseMeal((_) {
      calls++;
      if (calls == 1) throw _timeout;
      return eggsAndArepa;
    });
    final h = await MealFlowHarness.pump(tester, aiClient: fake.client);
    await h.openCaptureAndType(tester, 'dos huevos y una arepa');
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();

    expect(find.text('Algo salió mal'), findsOneWidget);
    expect(find.text('No pude entender tu comida'), findsOneWidget);
    expect(find.text('No se guardó nada en tu diario.'), findsOneWidget);
    // R7: el mensaje de red de siempre, dentro de esta pantalla.
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    for (final tip in analysisErrorTips) {
      expect(find.text(tip), findsOneWidget);
    }

    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(fake.texts, ['dos huevos y una arepa', 'dos huevos y una arepa']);
    expect(find.text('Detalle de comida'), findsOneWidget);
  });

  testWidgets('AC6: "Volver" desde el error regresa con el texto', (
    tester,
  ) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => throw _timeout).client,
    );
    await h.openCaptureAndType(tester, 'dos huevos');
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Volver'));
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.text('dos huevos'), findsOneWidget);
  });

  testWidgets('edge case: la IA sin alimentos muestra el error con su '
      'mensaje', (tester) async {
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => parsedMeal([])).client,
    );
    await h.openCaptureAndType(tester, 'hola');
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    expect(
      find.text('No encontré alimentos en lo que escribiste'),
      findsOneWidget,
    );
  });

  testWidgets('texto grande (×2) en 360 px: captura y detalle sin '
      'desbordes', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = await MealFlowHarness.pump(
      tester,
      aiClient: FakeParseMeal((_) => eggsAndArepa).client,
    );
    await h.openCaptureAndType(tester, 'dos huevos y una arepa');
    expect(tester.takeException(), isNull);
    for (final tab in ['Voz', 'Foto', 'Texto']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
    await tester.ensureVisible(find.text('Analizar'));
    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de comida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
