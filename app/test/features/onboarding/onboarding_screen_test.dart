import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/onboarding/onboarding_screen.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _pump(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        initialRoute: AppRoutes.onboarding,
        routes: {
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.diary: (_) =>
              const Scaffold(body: Text('Pantalla del diario')),
          AppRoutes.privacyPolicy: (_) =>
              const Scaffold(body: Text('Política completa')),
        },
      ),
    ),
  );
  return db;
}

void main() {
  testWidgets(
    'AC2: con solo una casilla marcada, Continuar sigue deshabilitado',
    (tester) async {
      final db = await _pump(tester);

      final continueButton = find.widgetWithText(FilledButton, 'Continuar');
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await tester.tap(find.text('Confirmo que soy mayor de 18 años'));
      await tester.pump();

      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await db.close();
    },
  );

  testWidgets(
    'AC2: desmarcar una casilla ya marcada vuelve a deshabilitar Continuar',
    (tester) async {
      final db = await _pump(tester);

      await tester.tap(find.text('Confirmo que soy mayor de 18 años'));
      await tester.pump();
      await tester.tap(find.textContaining('Autorizo el tratamiento'));
      await tester.pump();

      final continueButton = find.widgetWithText(FilledButton, 'Continuar');
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

      await tester.tap(find.text('Confirmo que soy mayor de 18 años'));
      await tester.pump();

      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await db.close();
    },
  );

  testWidgets(
    'AC3: marcar ambas y Continuar persiste el consentimiento y navega al diario',
    (tester) async {
      final db = await _pump(tester);

      await tester.tap(find.text('Confirmo que soy mayor de 18 años'));
      await tester.pump();
      await tester.tap(find.textContaining('Autorizo el tratamiento'));
      await tester.pump();

      final continueButton = find.widgetWithText(FilledButton, 'Continuar');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Pantalla del diario'), findsOneWidget);

      final state = await StorageRepository(db).getConsentState();
      expect(state, isNotNull);
      expect(state!.ageConfirmed, isTrue);
      expect(state.consentGiven, isTrue);

      await db.close();
    },
  );

  testWidgets(
    'AC12: la casilla de consentimiento nombra el dato de salud, el destino y el propósito',
    (tester) async {
      await _pump(tester);

      expect(find.textContaining('dato sensible de salud'), findsOneWidget);
      expect(find.textContaining('Vertex AI'), findsWidgets);
      expect(find.textContaining('fuera de Colombia'), findsWidgets);
      expect(
        find.textContaining('nunca para calcular valores nutricionales'),
        findsOneWidget,
      );
    },
  );

  testWidgets('el enlace a la política abre la pantalla completa', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Ver política de privacidad completa'));
    await tester.pumpAndSettle();

    expect(find.text('Política completa'), findsOneWidget);
  });
}
