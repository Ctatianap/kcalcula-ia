import 'dart:io';

import 'package:calorias_ia/features/goals/profile_controller.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/goal_sync.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_core/nutrition_core.dart';

final _today = DateTime(2026, 10, 3, 9);

Future<void> _saveProfile(StorageRepository repo, {double weightKg = 63}) =>
    repo.saveUserProfile(
      sex: 'female',
      birthDate: DateTime(1996, 10, 15),
      heightCm: 165,
      weightKg: weightKg,
      activityLevel: 'lightlyActive',
    );

/// Meta de objetivo (no manual) coherente con el perfil guardado.
Future<NutritionGoalValues> _saveObjectiveGoal(StorageRepository repo) async {
  final profile = (await repo.getUserProfile())!;
  final goal = goalValuesFor(
    kcal: objectiveKcal(
      maintenanceForProfile(profile, _today)!,
      GoalObjective.loseFat,
    ),
    objective: GoalObjective.loseFat,
    isManual: false,
  );
  await repo.saveNutritionGoal(goal);
  return goal;
}

/// La meta falla al guardarse (como fallaría SQLite).
class _GoalFailsRepository extends StorageRepository {
  _GoalFailsRepository(super.db);

  @override
  Future<void> saveNutritionGoal(NutritionGoalValues goal) =>
      Future.error(StateError('SqliteException'));
}

void main() {
  late AppDatabase db;
  late StorageRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StorageRepository(db);
  });
  tearDown(() => db.close());

  test('AC2: anotar dos veces el mismo día deja un registro con el último '
      'valor', () async {
    await repo.logWeight(day: DateTime(2026, 10, 3, 7), kg: 62.4);
    await repo.logWeight(day: DateTime(2026, 10, 3, 21), kg: 62.0);
    final entries = await repo.weightEntries();
    expect(entries, hasLength(1));
    expect(entries.single.day, DateTime(2026, 10, 3));
    expect(entries.single.weightKg, 62.0);
  });

  test('AC3: anotar peso actualiza el perfil y recalcula la meta de '
      'objetivo', () async {
    await _saveProfile(repo);
    final before = await _saveObjectiveGoal(repo);
    final notRecalculated = await repo.logWeight(day: _today, kg: 60);
    expect(notRecalculated, isFalse);
    final profile = (await repo.getUserProfile())!;
    expect(profile.weightKg, 60);
    final goal = (await repo.getNutritionGoal())!;
    final expected = objectiveKcal(
      maintenanceForProfile(profile, _today)!,
      GoalObjective.loseFat,
    );
    expect(goal.energyKcal, closeTo(expected, 1e-9));
    expect(goal.energyKcal, lessThan(before.energyKcal));
  });

  test('AC3: la meta manual no se recalcula', () async {
    await _saveProfile(repo);
    await repo.saveNutritionGoal(
      goalValuesFor(
        kcal: 1800,
        objective: GoalObjective.maintain,
        isManual: true,
      ),
    );
    await repo.logWeight(day: _today, kg: 60);
    expect((await repo.getNutritionGoal())!.energyKcal, 1800);
    expect((await repo.getUserProfile())!.weightKg, 60);
  });

  test('AC3: todo en una transacción: si la meta falla, ni el peso ni el '
      'perfil cambian', () async {
    await _saveProfile(repo);
    await _saveObjectiveGoal(repo);
    final failing = _GoalFailsRepository(db);
    await expectLater(failing.logWeight(day: _today, kg: 60), throwsStateError);
    expect(await repo.weightEntries(), isEmpty);
    expect((await repo.getUserProfile())!.weightKg, 63);
  });

  test(
    'AC4: guardar el perfil con otro peso crea el registro de hoy',
    () async {
      await _saveProfile(repo);
      await repo.logWeight(day: DateTime(2026, 9, 26), kg: 63);
      final controller = ProfileController(storage: repo, now: () => _today);
      await controller.load();
      controller.setWeight('62,5');
      expect(await controller.save(), isTrue);
      final entries = await repo.weightEntries();
      expect(entries.map((e) => (e.day, e.weightKg)), [
        (DateTime(2026, 9, 26), 63.0),
        (DateTime(2026, 10, 3), 62.5),
      ]);

      // Guardar otra vez sin cambiar el peso no crea otro registro.
      controller.setHeight('166');
      expect(await controller.save(), isTrue);
      expect(await repo.weightEntries(), hasLength(2));
      controller.dispose();
    },
  );

  test('borrar el más reciente: el perfil pasa al anterior; sin registros, '
      'conserva su peso', () async {
    await _saveProfile(repo);
    await repo.logWeight(day: DateTime(2026, 9, 26), kg: 62.4);
    await repo.logWeight(day: _today, kg: 62.0);
    expect((await repo.getUserProfile())!.weightKg, 62.0);

    await repo.deleteWeight(day: _today, today: _today);
    expect((await repo.getUserProfile())!.weightKg, 62.4);

    await repo.deleteWeight(day: DateTime(2026, 9, 26), today: _today);
    expect(await repo.weightEntries(), isEmpty);
    expect((await repo.getUserProfile())!.weightKg, 62.4);
  });

  test('sin perfil, anotar peso solo guarda el registro', () async {
    await repo.logWeight(day: _today, kg: 62);
    expect(await repo.getUserProfile(), isNull);
    expect(await repo.weightEntries(), hasLength(1));
  });

  test('AC5: borrar todo vacía weight_log y exportar lo incluye', () async {
    await repo.logWeight(day: DateTime(2026, 9, 26), kg: 62.4);
    await repo.logWeight(day: _today, kg: 62.0);
    final export = await repo.exportUserData();
    expect(export['weightLog'], [
      {'day': DateTime(2026, 9, 26).toIso8601String(), 'weightKg': 62.4},
      {'day': DateTime(2026, 10, 3).toIso8601String(), 'weightKg': 62.0},
    ]);
    await repo.deleteAllUserData();
    expect(await repo.weightEntries(), isEmpty);
  });

  test(
    'AC5: migrar desde la v6 conserva todo y crea weight_log vacía',
    () async {
      final dir = Directory.systemTemp.createTempSync('calorias_ia_weight');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/user.db';
      final v6 = AppDatabase(AppDatabase.openFile(path));
      final repo6 = StorageRepository(v6);
      await repo6.saveConsent(policyVersion: 'v3');
      await _saveProfile(repo6);
      await repo6.saveNutritionGoal(
        goalValuesFor(
          kcal: 1800,
          objective: GoalObjective.maintain,
          isManual: true,
        ),
      );
      await repo6.registerMeal(
        eatenAt: DateTime(2026, 10, 2, 8),
        mealType: 'desayuno',
        confidence: 'buenaEstimacion',
        catalogVersion: 'test-1',
        items: const [
          MealItemRecord(
            mention: 'una manzana',
            foodId: 'manzana',
            nameSnapshot: 'Manzana',
            grams: 150,
            quantityBasis: 'unitPortion',
            energyKcal: 78,
            proteinG: 0.4,
            carbsG: 20.7,
            fatG: 0.3,
            confidence: 'buenaEstimacion',
            sourceRef: 'fixture de prueba',
          ),
        ],
      );
      // Simula un user.db de la v6: sin weight_log.
      await v6.customStatement('DROP TABLE weight_log');
      await v6.customStatement('PRAGMA user_version = 6');
      await v6.close();

      final v7 = AppDatabase(AppDatabase.openFile(path));
      addTearDown(v7.close);
      final repo7 = StorageRepository(v7);
      expect(await repo7.mealsForDay(DateTime(2026, 10, 2)), hasLength(1));
      expect((await repo7.getUserProfile())!.weightKg, 63);
      expect((await repo7.getNutritionGoal())!.energyKcal, 1800);
      expect((await repo7.getConsentState())!.policyVersion, 'v3');
      expect(await repo7.weightEntries(), isEmpty);
      await repo7.logWeight(day: _today, kg: 62);
      expect(await repo7.weightEntries(), hasLength(1));
      final version = await v7
          .customSelect('PRAGMA user_version')
          .map((row) => row.read<int>('user_version'))
          .getSingle();
      expect(version, 9); // SPEC-022 la subió a 9.
    },
  );
}
