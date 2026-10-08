import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/features/capture/label_confirmation_screen.dart';
import 'package:calorias_ia/features/diary/diary_screen.dart';
import 'package:calorias_ia/features/onboarding/onboarding_screen.dart';
import 'package:calorias_ia/features/review/review_screen.dart';
import 'package:calorias_ia/infra/ai_client/label_extraction_dto.dart';
import 'package:calorias_ia/infra/ai_client/parsed_meal_dto.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/crash_reporting/crash_reporting_providers.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_crash_reporter.dart';
import '../support/fixture_catalog.dart';

/// SPEC-009: el error que tiraría SQLite, con los datos en el mensaje.
SqliteException _sqliteError() => SqliteException(
  extendedResultCode: 10,
  message: 'disk I/O error',
  causingStatement: 'INSERT ...',
  parametersToStatement: ['Huevo', 100],
);

/// Repositorio que falla en las operaciones marcadas hasta que `healed`.
class _FlakyRepository extends StorageRepository {
  _FlakyRepository(
    super.db, {
    this.failRegister = false,
    this.failSaveProduct = false,
    this.failReads = false,
    this.failConsent = false,
  });

  final bool failRegister;
  final bool failSaveProduct;
  final bool failReads;
  final bool failConsent;
  bool healed = false;

  @override
  Future<void> saveConsent({required String policyVersion}) =>
      _fails(failConsent)
      ? Future.error(_sqliteError())
      : super.saveConsent(policyVersion: policyVersion);

  bool _fails(bool flag) => flag && !healed;

  @override
  Future<int> registerMeal({
    required DateTime eatenAt,
    required String? mealType,
    required String confidence,
    required String catalogVersion,
    required List<MealItemRecord> items,
  }) => _fails(failRegister)
      ? Future.error(_sqliteError())
      : super.registerMeal(
          eatenAt: eatenAt,
          mealType: mealType,
          confidence: confidence,
          catalogVersion: catalogVersion,
          items: items,
        );

  @override
  Future<int> savePersonalProduct({
    required String nameEs,
    required double energyKcal100,
    required double proteinG100,
    required double carbsG100,
    required double fatG100,
    double? fiberG100,
    double? sugarG100,
    double? sodiumMg100,
    required double servingGrams,
    double? densityGPerMl,
    required String sourceRef,
    String servingUnit = 'g',
  }) => _fails(failSaveProduct)
      ? Future.error(_sqliteError())
      : super.savePersonalProduct(
          nameEs: nameEs,
          energyKcal100: energyKcal100,
          proteinG100: proteinG100,
          carbsG100: carbsG100,
          fatG100: fatG100,
          fiberG100: fiberG100,
          sugarG100: sugarG100,
          sodiumMg100: sodiumMg100,
          servingGrams: servingGrams,
          densityGPerMl: densityGPerMl,
          servingUnit: servingUnit,
          sourceRef: sourceRef,
        );

  @override
  Future<List<PersonalProduct>> getAllPersonalProducts() => _fails(failReads)
      ? Future.error(_sqliteError())
      : super.getAllPersonalProducts();

  @override
  Future<List<MealWithItems>> mealsForDay(DateTime day) =>
      _fails(failReads) ? Future.error(_sqliteError()) : super.mealsForDay(day);

  @override
  Future<List<MealWithItems>> mealsBetween(DateTime start, DateTime end) =>
      _fails(failReads)
      ? Future.error(_sqliteError())
      : super.mealsBetween(start, end);

  @override
  Future<ConsentRecordData?> getConsentState() => _fails(failReads)
      ? Future.error(_sqliteError())
      : super.getConsentState();
}

Future<_FlakyRepository> _pump(
  WidgetTester tester,
  Widget home, {
  bool failRegister = false,
  bool failSaveProduct = false,
  bool failReads = false,
  bool failConsent = false,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = _FlakyRepository(
    db,
    failRegister: failRegister,
    failSaveProduct: failSaveProduct,
    failReads: failReads,
    failConsent: failConsent,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        storageRepositoryProvider.overrideWithValue(repo),
        catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
        crashReporterProvider.overrideWithValue(FakeCrashReporter()),
      ],
      child: home is MyApp ? home : MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

const _eggs = ParsedMealDto(
  mealType: null,
  items: [
    ParsedMealItemDto(
      mention: 'dos huevos',
      foodQuery: 'huevo',
      quantity: 2,
      unit: 'unidad',
      isVague: false,
    ),
  ],
);

const _label = LabelExtractionDto(
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

void main() {
  testWidgets(
    'AC3: si registrar falla, mensaje y la revisión sigue con sus ítems',
    (tester) async {
      await _pump(
        tester,
        const ReviewScreen(parsedMeal: _eggs),
        failRegister: true,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(registerErrorMessage), findsOneWidget);
      expect(find.text('“dos huevos”'), findsOneWidget);
      expect(find.textContaining('disk I/O'), findsNothing);
    },
  );

  testWidgets('AC4: si guardar el producto falla, mensaje y no navega', (
    tester,
  ) async {
    await _pump(
      tester,
      const LabelConfirmationScreen(extraction: _label),
      failSaveProduct: true,
    );

    final save = find.widgetWithText(FilledButton, reviewMealButtonLabel);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(saveProductErrorMessage), findsOneWidget);
    expect(find.text('Producto de prueba'), findsOneWidget);
  });

  testWidgets('AC5: diario con lectura fallida → mensaje y Reintentar', (
    tester,
  ) async {
    final repo = await _pump(tester, const DiaryScreen(), failReads: true);

    expect(
      find.text('No pude leer tus datos. Intenta de nuevo.'),
      findsOneWidget,
    );
    repo.healed = true;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no registras nada hoy'), findsOneWidget);
  });

  testWidgets('AC5: revisión con lectura fallida → mensaje y Reintentar', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      const ReviewScreen(parsedMeal: _eggs),
      failReads: true,
    );

    expect(find.text(readErrorMessage), findsOneWidget);
    repo.healed = true;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('“dos huevos”'), findsOneWidget);
  });

  testWidgets('AC5: arranque con lectura fallida → mensaje y Reintentar', (
    tester,
  ) async {
    final repo = await _pump(tester, const MyApp(), failReads: true);

    expect(tester.takeException(), isNull);
    expect(
      find.text('No pude leer tus datos. Intenta de nuevo.'),
      findsOneWidget,
    );
    repo.healed = true;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Antes de empezar'), findsOneWidget);
  });

  testWidgets('si guardar el consentimiento falla, mensaje y sin relanzar', (
    tester,
  ) async {
    await _pump(tester, const MyApp(), failConsent: true);

    for (final box in find.byType(CheckboxListTile).evaluate().toList()) {
      await tester.ensureVisible(find.byWidget(box.widget));
      await tester.tap(find.byWidget(box.widget));
      await tester.pump();
    }
    final accept = find.byType(FilledButton).first;
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(acceptErrorMessage), findsOneWidget);
    expect(find.text('Antes de empezar'), findsOneWidget);
  });
}
