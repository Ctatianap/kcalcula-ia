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
import 'package:calorias_ia/ui/components/progress_ring.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

/// Perfil de referencia: mujer, 30 años, 165 cm, 63 kg, actividad ligera.
/// Harris-Benedict 1918: basal 1.422,5 → "~1.423"; × 1,375 → "~1.956".
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
    double? measuredMaintenanceKcal,
    NutritionGoalValues? recalculatedGoal,
    DateTime? weightLogDay,
  }) => Future.error(StateError('SqliteException: parameters: 63, 165'));

  @override
  Future<void> saveNutritionGoal(NutritionGoalValues goal) =>
      Future.error(StateError('SqliteException: parameters: 2276'));
}

/// La lectura falla (p. ej. base bloqueada).
class _UnreadableRepository extends StorageRepository {
  _UnreadableRepository(super.db);

  @override
  Future<UserProfileData?> getUserProfile() =>
      Future.error(StateError('SqliteException: database is locked'));
}

Future<AppDatabase> _pump(
  WidgetTester tester,
  String initialRoute, {
  AppDatabase? db,
  bool failing = false,
  bool unreadable = false,
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
        if (unreadable)
          storageRepositoryProvider.overrideWithValue(
            _UnreadableRepository(database),
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

/// SPEC-041: elige [text] en el selector [key].
Future<void> _select(WidgetTester tester, String key, String text) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  // El menú construye solo las opciones visibles.
  final menu = find.byType(Scrollable).last;
  final option = find.descendant(of: menu, matching: find.text(text));
  // Abre en la opción elegida: la buscada puede estar arriba o abajo.
  try {
    await tester.scrollUntilVisible(option, 100, scrollable: menu);
  } on StateError {
    await tester.scrollUntilVisible(option, -100, scrollable: menu);
  }
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

/// SPEC-041: día, mes y año en los selectores.
Future<void> _selectBirthDate(WidgetTester tester, DateTime d) async {
  await _select(tester, 'profile-birth-year', '${d.year}');
  await _select(tester, 'profile-birth-month', monthNamesEs[d.month - 1]);
  await _select(tester, 'profile-birth-day', '${d.day}');
}

Future<void> _fillProfile(WidgetTester tester) async {
  await tester.tap(find.text('Femenino'));
  await _selectBirthDate(tester, _birth30);
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
      expect(find.text('Mantenimiento: ~1.956 kcal'), findsOneWidget);
      expect(find.text(disclaimerText), findsOneWidget);

      // AC7: cambiar peso y actividad recalcula sin reiniciar la pantalla.
      await tester.enterText(find.byKey(const Key('profile-weight')), '70');
      await tester.pump();
      expect(find.text('Mantenimiento: ~2.048 kcal'), findsOneWidget);
      await tester.tap(find.text('Actividad intensa'));
      await tester.pump();
      expect(find.text('Mantenimiento: ~2.569 kcal'), findsOneWidget);

      await tester.tap(save);
      await tester.pumpAndSettle();
      final profile = await StorageRepository(db).getUserProfile();
      expect(profile!.weightKg, 70);
      expect(profile.activityLevel, 'veryActive');
      // R1: al guardar vuelve a la pantalla anterior, con el aviso.
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(DiaryScreen), findsOneWidget);
      expect(find.text('Perfil guardado.'), findsOneWidget);
    });

    testWidgets('AC6: fuera de rango → mensaje y no se puede guardar', (
      tester,
    ) async {
      final db = await _pump(tester, AppRoutes.profile);
      addTearDown(db.close);
      await _fillProfile(tester);

      await tester.enterText(find.byKey(const Key('profile-weight')), '25');
      await tester.pump();
      expect(find.text(weightRangeMessage), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'Guardar perfil');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      // Nació el 31 de diciembre del año más reciente de la lista: aún
      // tiene 17 años (salvo el propio 31 de diciembre).
      final now = DateTime.now();
      if (!(now.month == 12 && now.day == 31)) {
        await _select(tester, 'profile-birth-year', '${now.year - 18}');
        await _select(tester, 'profile-birth-month', 'diciembre');
        await _select(tester, 'profile-birth-day', '31');
        expect(find.text(ageRangeMessage), findsOneWidget);
      }
    });

    testWidgets('carga el perfil guardado para editarlo', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _saveProfile(StorageRepository(db), weightKg: 63.5);

      await _pump(tester, AppRoutes.profile, db: db);

      expect(find.text('63,5'), findsOneWidget);
      // SPEC-041 AC2: los selectores muestran la fecha guardada.
      expect(find.text('${_birth30.year}'), findsOneWidget);
      expect(find.text('enero'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
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

    testWidgets('R1: al guardar el perfil abierto desde Mi objetivo, vuelve '
        'a Mi objetivo con las opciones cargadas', (tester) async {
      final db = await _pump(tester, AppRoutes.objective);
      addTearDown(db.close);
      await tester.tap(find.text('Completar mi perfil'));
      await tester.pumpAndSettle();

      await _fillProfile(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(ObjectiveScreen), findsOneWidget);
      expect(find.byKey(const Key('objective-loseFat')), findsOneWidget);
      expect(find.text('Perfil guardado.'), findsOneWidget);
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
        expect(find.text('Tu mantenimiento: ~1.956 kcal'), findsOneWidget);
        expect(find.text('Bajar grasa · ~1.456 kcal'), findsOneWidget);
        expect(
          find.textContaining(
            'Proteína 98 g · Grasa 54 g · Carbohidratos 269 g',
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
        expect(goal.energyKcal, closeTo(1455.95, 0.01));
        expect(find.text('/1.456'), findsOneWidget);
        expect(find.text('kcal consumidas · quedan 1.456'), findsOneWidget);
        expect(find.byType(ProgressRing), findsNWidgets(4));
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
      expect(goal!.energyKcal, closeTo(1547.99, 0.01));
      expect(goal.objective, 'loseFat');

      // El diario muestra la meta recalculada.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, AppRoutes.diary, db: db);
      expect(find.text('/1.548'), findsOneWidget);
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
        await tester.tap(find.text('Actividad intensa'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
        await tester.pumpAndSettle();

        expect(find.text(goalNotRecalculatedMessage), findsOneWidget);
        // R1: con un aviso que leer, se queda en el perfil.
        expect(find.byType(ProfileScreen), findsOneWidget);
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
          '"Bajar grasa" sería ~1.548 kcal.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Usar este valor'));
      await tester.pumpAndSettle();
      final goal = await repo.getNutritionGoal();
      expect(goal!.isManual, isFalse);
      expect(goal.energyKcal, closeTo(1547.99, 0.01));
    });
  });

  group('errores de lectura', () {
    testWidgets('Mi perfil: mensaje, Reintentar y no deja guardar', (
      tester,
    ) async {
      final db = await _pump(tester, AppRoutes.profile, unreadable: true);
      addTearDown(db.close);

      expect(tester.takeException(), isNull);
      expect(find.text(profileLoadErrorMessage), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      await _fillProfile(tester);
      final save = find.widgetWithText(FilledButton, 'Guardar perfil');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
    });

    testWidgets('Mi objetivo: mensaje y Reintentar', (tester) async {
      final db = await _pump(tester, AppRoutes.objective, unreadable: true);
      addTearDown(db.close);

      expect(tester.takeException(), isNull);
      expect(find.text(goalLoadErrorMessage), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('R4: mantenimiento medido', () {
    testWidgets('si se llena, manda sobre la fórmula y se guarda', (
      tester,
    ) async {
      final db = await _pump(tester, AppRoutes.profile);
      addTearDown(db.close);
      await _fillProfile(tester);

      await tester.enterText(
        find.byKey(const Key('profile-measured')),
        '1.890',
      );
      await tester.pump();

      expect(find.text('Mantenimiento (medido): 1.890 kcal'), findsOneWidget);
      expect(
        find.text(
          'Según la fórmula serían ~1.956 kcal; se usa tu valor medido.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
      await tester.pumpAndSettle();
      final profile = await StorageRepository(db).getUserProfile();
      expect(profile!.measuredMaintenanceKcal, 1890);
    });

    testWidgets('Mi objetivo usa el mantenimiento medido', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await StorageRepository(db).saveUserProfile(
        sex: 'female',
        birthDate: _birth30,
        heightCm: 165,
        weightKg: 63,
        activityLevel: 'active',
        measuredMaintenanceKcal: 1890,
      );
      await _pump(tester, AppRoutes.objective, db: db);

      expect(find.text('Tu mantenimiento: ~1.890 kcal'), findsOneWidget);
      expect(find.text('Bajar grasa · ~1.390 kcal'), findsOneWidget);
    });

    testWidgets('fuera de rango: mensaje y no se puede guardar', (
      tester,
    ) async {
      final db = await _pump(tester, AppRoutes.profile);
      addTearDown(db.close);
      await _fillProfile(tester);

      await tester.enterText(find.byKey(const Key('profile-measured')), '500');
      await tester.pump();

      expect(find.text(measuredRangeMessage), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'Guardar perfil');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
    });

    testWidgets('R9: la meta de un objetivo se recalcula con el medido', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = StorageRepository(db);
      await _saveProfile(repo);
      await repo.saveNutritionGoal(
        goalValuesFor(
          kcal: 1456,
          objective: GoalObjective.loseFat,
          isManual: false,
        ),
      );
      await _pump(tester, AppRoutes.profile, db: db);

      await tester.enterText(find.byKey(const Key('profile-measured')), '1890');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
      await tester.pumpAndSettle();

      expect((await repo.getNutritionGoal())!.energyKcal, 1390);
    });
  });

  group('maintenanceForProfile', () {
    UserProfileData profile({double? measured, int yearsOld = 30}) =>
        UserProfileData(
          id: 0,
          sex: 'female',
          birthDate: DateTime(DateTime.now().year - yearsOld, 1, 1),
          heightCm: 165,
          weightKg: 63,
          activityLevel: 'lightlyActive',
          measuredMaintenanceKcal: measured,
          updatedAt: DateTime(2026, 10, 3),
        );

    test('con medido válido usa el medido', () {
      expect(
        maintenanceForProfile(profile(measured: 1890), DateTime.now()),
        1890,
      );
    });

    test('con medido fuera de rango usa la fórmula', () {
      expect(
        maintenanceForProfile(profile(measured: 500), DateTime.now()),
        closeTo(1955.95, 0.01),
      );
    });

    test(
      'perfil que ya no sirve para la fórmula: el medido sigue valiendo',
      () {
        expect(
          maintenanceForProfile(
            profile(measured: 1890, yearsOld: 101),
            DateTime.now(),
          ),
          1890,
        );
        expect(
          maintenanceForProfile(profile(yearsOld: 101), DateTime.now()),
          isNull,
        );
      },
    );
  });
}
