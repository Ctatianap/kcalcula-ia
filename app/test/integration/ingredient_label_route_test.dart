import 'package:calorias_ia/app.dart';
import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/capture/ingredient_label_screen.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
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
    'SPEC-033 AC1/R7: la app conecta la ruta de la etiqueta de un ingrediente',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await StorageRepository(db)
          .saveConsent(policyVersion: privacyPolicyVersion);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
            crashReporterProvider.overrideWithValue(FakeCrashReporter()),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pushNamed(AppRoutes.ingredientLabel, arguments: 'pan');
      await tester.pumpAndSettle();

      expect(find.byType(IngredientLabelScreen), findsOneWidget);
      expect(find.byKey(const Key('ingredient-label-name')), findsOneWidget);
      expect(find.text('pan'), findsOneWidget);
    },
  );
}
