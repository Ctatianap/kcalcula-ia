import 'package:calorias_ia/app_routes.dart';
import 'package:calorias_ia/features/diary/diary_screen.dart';
import 'package:calorias_ia/features/goals/goal_calculation.dart';
import 'package:calorias_ia/features/goals/objective_controller.dart';
import 'package:calorias_ia/features/goals/objective_screen.dart';
import 'package:calorias_ia/features/goals/profile_controller.dart';
import 'package:calorias_ia/features/goals/profile_screen.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

/// Perfil de referencia: mujer, 30 años, 165 cm, 63 kg, actividad ligera.
/// Harris-Benedict 1918: basal 1.422,5 → "~1.423"; × 1,6 → "~2.276".
final _birth30 = DateTime(DateTime.now().year - 30, 1, 1);

Future<void> _saveProfile(StorageRepository repo, {double weightKg = 63}) =>
    repo.saveUserProfile(
      sex: 'female',
      birthDate: _birth30,
      heightCm: 165,
      weightKg: weightKg,
      activityLevel: 'lightlyActive',
    );

/// Falla como fallaría SQLite (con parámetros en el mensaje), para
/// comprobar que no se relanza hacia Crashlytics (AC14).
class _FailingRepository extends StorageRepository {
  _FailingRepository(super.db);

  @override
  Future<void> saveUserProfile({
    required String sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    NutritionGoalValues? recalculatedGoal,
  }) => Future.error(StateError('SqliteException: parameters: 63, 165'));

  @override
  Future<void> saveNutritionGoal(NutritionGoalValues goal) =>
      Future.error(StateError('SqliteException: parameters: 2276'));
}

Future<AppDatabase> _pump(
  WidgetTester tester,
  String initialRoute, {
  AppDatabase? db,
  bool failing = false,
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final database = db ?? AppDatabase(NativeDatabase.memory());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        if (failing)
          storageRepositoryProvider.overrideWithValue(
            _FailingRepository(database),
          ),
      ],
      child: MaterialApp(
        initialRoute: initialRoute,
        routes: {
          AppRoutes.diary: (_) => const DiaryScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.objective: (_) => const ObjectiveScreen(),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return database;
}

Future<void> _fillProfile(WidgetTester tester) async {
  await tester.tap(find.text('Femenino'));
  await tester.enterText(
    find.byKey(const Key('profile-birth-date')),
    formatBirthDate(_birth30),
  );
  await tester.enterText(find.byKey(const Key('profile-height')), '165');
  await tester.enterText(find.byKey(const Key('profile-weight')), '63');
  await tester.tap(find.text('Actividad ligera'));
  await tester.pump();
}

void main() {
  group('Mi perfil (AC6, AC7)', () {
    testWidgets('AC6/AC7: punto de partida en vivo y guardado', (tester) async {
      final db = await _pump(tester, AppRoutes.profile);
      addTearDown(db.close);
      final save = find.widgetWithText(FilledButton, 'Guardar perfil');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await _fillProfile(tester);

      expect(find.text('30 años'), findsOneWidget);
      expect(find.text('Metabolismo basal: ~1.423 kcal'), findsOneWidget);
      expect(find.text('Mantenimiento: ~2.276 kcal'), findsOneWidget);
      expect(find.text(disclaimerText), findsOneWidget);

      // AC7: cambiar peso y actividad recalcula sin reiniciar la pantalla.
      await tester.enterText(find.byKey(const Key('profile-weight')), '70');
      await tester.pump();
      expect(find.text('Mantenimiento: ~2.383 kcal'), findsOneWidget);
      await tester.tap(find.text('Actividad alta'));
      await tester.pump();
      expect(find.text('Mantenimiento: ~2.979 kcal'), findsOneWidget);

      await tester.tap(save);
      await tester.pumpAndSettle();
      final profile = await StorageRepository(db).getUserProfile();
      expect(profile!.weightKg, 70);
      expect(profile.activityLevel, 'veryActive');
      expect(find.text('Elegir mi objetivo'), findsOneWidget);
    });

    testWidgets('AC6: fuera de rango → mensaje y no se puede guardar', (
      tester,
    ) async {
      final db = await _pump(tester, AppRoutes.profile);
      addTearDown(db.close);
      await _fillProfile(tester);

      await tester.enterText(find.byKey(const Key('profile-weight')), '25');
      await tester.enterText(
        find.byKey(const Key('profile-birth-date')),
        '31/02/1990',
      );
      await tester.pump();

      expect(find.text(weightRangeMessage), findsOneWidget);
      expect(find.text(birthDateFormatMessage), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'Guardar perfil');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      final teen = DateTime(DateTime.now().year - 17, 1, 1);
      await tester.enterText(
        find.byKey(const Key('profile-birth-date')),
        formatBirthDate(teen),
      );
      await tester.pump();
      expect(find.text(ageRangeMessage), findsOneWidget);
    });

    testWidgets('carga el perfil guardado para editarlo', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _saveProfile(StorageRepository(db), weightKg: 63.5);

      await _pump(tester, AppRoutes.profile, db: db);

      expect(find.text('63,5'), findsOneWidget);
      expect(find.text(formatBirthDate(_birth30)), findsOneWidget);
    });

    testWidgets('AC14: si guardar el perfil falla, mensaje y sin relanzar', (
      tester,
    ) async {
      final db = await _pump(tester, AppRoutes.profile, failing: true);
      addTearDown(db.close);
      await _fillProfile(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(profileSaveErrorMessage), findsOneWidget);
      expect(find.textContaining('Sqlite'), findsNothing);
    });
  });

  group('Mi objetivo (AC8–AC11, AC14)', () {
    testWidgets('perfil que ya no es válido: pide revisarlo', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await StorageRepository(db).saveUserProfile(
        sex: 'female',
        birthDate: DateTime(DateTime.now().year - 101, 1, 1),
        heightCm: 165,
        weightKg: 63,
        activityLevel: 'lightlyActive',
      );
      await _pump(tester, AppRoutes.objective, db: db);

      expect(find.text('Revisar mi perfil'), findsOneWidget);
      expect(find.text('Completar mi perfil'), findsNothing);
    });

    testWidgets('R1: desde Mi objetivo se abre Mi perfil', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _saveProfile(StorageRepository(db));
      await _pump(tester, AppRoutes.objective, db: db);

      await tester.tap(find.byTooltip('Mi perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Guardar perfil'), findsOneWidget);
    });

    testWidgets('AC11: sin perfil lleva a completarlo', (tester) async {
      final db = await _pump(tester, AppRoutes.objective);
      addTearDown(db.close);

      await tester.tap(find.text('Completar mi perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Mi perfil'), findsOneWidget);
    });

    testWidgets(
      'AC8: elegir un objetivo lo guarda como meta y el diario la muestra',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await _saveProfile(StorageRepository(db));
        await _pump(tester, AppRoutes.diary, db: db);

        await tester.tap(find.text('Calcular mi meta'));
        await tester.pumpAndSettle();
        expect(find.text('Tu mantenimiento: ~2.276 kcal'), findsOneWidget);
        expect(find.text('Bajar grasa · ~1.776 kcal'), findsOneWidget);
        expect(
          find.textContaining(
            'Proteína 114 g · Grasa 63 g · Carbohidratos 313 g',
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('objective-loseFat')));
        await tester.pump();
        await tester.tap(find.text('Usar como mi meta diaria'));
        await tester.pumpAndSettle();

        final goal = await StorageRepository(db).getNutritionGoal();
        expect(goal!.objective, 'loseFat');
        expect(goal.isManual, isFalse);
        expect(goal.energyKcal, closeTo(1776.01, 0.01));
        expect(find.text('0 / 1.776 kcal · quedan 1.776'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
      },
    );

    testWidgets('AC10: meta manual de 1.199 advierte; 1.200 no', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _saveProfile(StorageRepository(db));
      await _pump(tester, AppRoutes.objective, db: db);

      await tester.enterText(find.byKey(const Key('manual-kcal')), '1199');
      await tester.pump();
      expect(find.text(lowGoalWarningMessage), findsOneWidget);
      final save = find.widgetWithText(OutlinedButton, 'Guardar meta manual');
      expect(tester.widget<OutlinedButton>(save).onPressed, isNotNull);

      await tester.enterText(find.byKey(const Key('manual-kcal')), '1.200');
      await tester.pump();
      expect(find.text(lowGoalWarningMessage), findsNothing);

      await tester.enterText(find.byKey(const Key('manual-kcal')), '7000');
      await tester.pump();
      expect(find.text(kcalRangeMessage), findsOneWidget);
    });

    testWidgets('AC14: si guardar la meta falla, mensaje y sin relanzar', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _saveProfile(StorageRepository(db));
      await _pump(tester, AppRoutes.objective, db: db, failing: true);

      await tester.tap(find.text('Usar como mi meta diaria'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(goalSaveErrorMessage), findsOneWidget);
    });
  });

  group('AC9: la meta sigue al perfil', () {
    testWidgets('meta de un objetivo: cambiar el peso la recalcula', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = StorageRepository(db);
      await _saveProfile(repo);
      await _pump(tester, AppRoutes.objective, db: db);
      await tester.tap(find.byKey(const Key('objective-loseFat')));
      await tester.pump();
      await tester.tap(find.text('Usar como mi meta diaria'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await _pump(tester, AppRoutes.profile, db: db);
      await tester.enterText(find.byKey(const Key('profile-weight')), '70');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
      await tester.pumpAndSettle();

      final goal = await repo.getNutritionGoal();
      expect(goal!.energyKcal, closeTo(1883.12, 0.01));
      expect(goal.objective, 'loseFat');

      // El diario muestra la meta recalculada.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, AppRoutes.diary, db: db);
      expect(find.text('0 / 1.883 kcal · quedan 1.883'), findsOneWidget);
    });

    testWidgets(
      'si la meta recalculada queda fuera de rango, se conserva y se avisa',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = StorageRepository(db);
        await _saveProfile(repo);
        await _pump(tester, AppRoutes.profile, db: db);
        // Con 300 kg, 230 cm y actividad alta, "Subir masa muscular" (+20 %)
        // queda por encima de 6.000 kcal: la meta no se recalcula.
        await repo.saveNutritionGoal(
          goalValuesFor(
            kcal: 3000,
            objective: GoalObjective.gainMuscle,
            isManual: false,
          ),
        );
        await tester.enterText(find.byKey(const Key('profile-weight')), '300');
        await tester.enterText(find.byKey(const Key('profile-height')), '230');
        await tester.tap(find.text('Actividad alta'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
        await tester.pumpAndSettle();

        expect(find.text(goalNotRecalculatedMessage), findsOneWidget);
        expect((await repo.getNutritionGoal())!.energyKcal, 3000);
      },
    );

    testWidgets('meta manual: no cambia y aparece la sugerencia', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = StorageRepository(db);
      await _saveProfile(repo);
      await repo.saveNutritionGoal(
        goalValuesFor(
          kcal: 1800,
          objective: GoalObjective.loseFat,
          isManual: true,
        ),
      );

      await _pump(tester, AppRoutes.profile, db: db);
      await tester.enterText(find.byKey(const Key('profile-weight')), '70');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
      await tester.pumpAndSettle();
      expect((await repo.getNutritionGoal())!.energyKcal, 1800);

      await tester.pumpWidget(const SizedBox());
      await _pump(tester, AppRoutes.objective, db: db);
      expect(
        find.text(
          'Tu meta es manual (1.800 kcal). Con tu perfil actual, '
          '"Bajar grasa" sería ~1.883 kcal.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Usar este valor'));
      await tester.pumpAndSettle();
      final goal = await repo.getNutritionGoal();
      expect(goal!.isManual, isFalse);
      expect(goal.energyKcal, closeTo(1883.12, 0.01));
    });
  });
}
