import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/ui/components/meal_card.dart';
import 'package:calorias_ia/infra/clock.dart';
import 'package:calorias_ia/infra/crash_reporting/crash_reporting_providers.dart';
import 'package:calorias_ia/infra/legal/privacy_policy.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_crash_reporter.dart';
import '../support/fixture_catalog.dart';

void main() {
  testWidgets(
    'SPEC-026 R1/R6: tocar una comida en Hoy la abre para editar; al guardar, Hoy muestra el cambio',
    (tester) async {
      final now = DateTime(2026, 10, 8, 12);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = StorageRepository(db);
      await tester.runAsync(() async {
        await repo.saveConsent(policyVersion: privacyPolicyVersion);
        await repo.registerMeal(
          eatenAt: DateTime(2026, 10, 8, 8),
          mealType: 'desayuno',
          confidence: 'buenaEstimacion',
          catalogVersion: 'test-1',
          items: const [
            MealItemRecord(
              mention: 'dos huevos',
              foodId: 'huevo',
              nameSnapshot: 'Huevo',
              grams: 100,
              quantityInput: 2,
              unitInput: 'unidad',
              quantityBasis: 'unitPortion',
              energyKcal: 143,
              proteinG: 12.56,
              carbsG: 0.72,
              fatG: 9.51,
              confidence: 'buenaEstimacion',
              sourceRef: 'fixture',
            ),
          ],
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
            crashReporterProvider.overrideWithValue(FakeCrashReporter()),
            clockProvider.overrideWithValue(() => now),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('143 kcal'), findsOneWidget);

      await tester.ensureVisible(find.text('Desayuno'));
      await tester.tap(find.text('Desayuno'));
      await tester.pumpAndSettle();
      expect(find.text('Editar comida'), findsOneWidget);

      final plus = find.byTooltip('Más').first;
      await tester.ensureVisible(plus);
      await tester.pumpAndSettle();
      await tester.tap(plus);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      // De vuelta en Hoy, con la comida editada (105 g → 150 kcal).
      expect(find.text('Editar comida'), findsNothing);
      expect(find.text('150 kcal'), findsOneWidget);
    },
  );

  testWidgets(
    'SPEC-026 AC1/AC7/R6: editar una comida de ayer desde Historial y repetirla hoy; Historial, Hoy, la racha y Progreso muestran los cambios',
    (tester) async {
      final now = DateTime(2026, 10, 8, 12);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = StorageRepository(db);
      await tester.runAsync(() async {
        await repo.saveConsent(policyVersion: privacyPolicyVersion);
        await repo.registerMeal(
          eatenAt: DateTime(2026, 10, 7, 13),
          mealType: 'almuerzo',
          confidence: 'buenaEstimacion',
          catalogVersion: 'test-1',
          items: const [
            MealItemRecord(
              mention: 'dos huevos',
              foodId: 'huevo',
              nameSnapshot: 'Huevo',
              grams: 100,
              quantityInput: 2,
              unitInput: 'unidad',
              quantityBasis: 'unitPortion',
              energyKcal: 143,
              proteinG: 12.56,
              carbsG: 0.72,
              fatG: 9.51,
              confidence: 'buenaEstimacion',
              sourceRef: 'fixture',
            ),
          ],
        );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
            crashReporterProvider.overrideWithValue(FakeCrashReporter()),
            clockProvider.overrideWithValue(() => now),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder.first);
        await tester.pumpAndSettle();
        await tester.tap(finder.first);
        await tester.pumpAndSettle();
      }

      Future<void> openYesterdayInHistory() async {
        await tap(find.bySemanticsLabel('Historial'));
        await tap(find.byKey(const Key('history-day-7')));
      }

      String historyKcal() =>
          tester.widget<Text>(find.byKey(const Key('history-kcal'))).data!;

      // AC1: Historial de ayer antes y después de editar (100 g → 105 g).
      await openYesterdayInHistory();
      expect(historyKcal(), contains('143'));
      await tap(find.byType(MealCard));
      expect(find.text('Editar comida'), findsOneWidget);
      await tap(find.byTooltip('Más'));
      await tap(find.text('Guardar cambios'));
      await openYesterdayInHistory();
      expect(historyKcal(), contains('150'));

      // AC7: "Repetir hoy" desde la comida de ayer.
      await tap(find.byType(MealCard));
      await tap(find.text('Repetir hoy'));
      await tap(find.widgetWithText(FilledButton, 'Guardar'));

      // Hoy: la comida nueva y la racha de 2 días (ayer y hoy).
      expect(find.text('Almuerzo'), findsOneWidget);
      expect(
        find.bySemanticsLabel('2 días seguidos registrando'),
        findsOneWidget,
      );

      // Historial de hoy.
      await tap(find.bySemanticsLabel('Historial'));
      expect(historyKcal(), contains('150'));

      // Progreso: ayer y hoy con 150 kcal.
      await tap(find.bySemanticsLabel('Progreso'));
      expect(
        find.bySemanticsLabel(RegExp(r'^miércoles 7 de octubre: 150 kcal')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^jueves 8 de octubre: 150 kcal')),
        findsOneWidget,
      );
    },
  );
}
