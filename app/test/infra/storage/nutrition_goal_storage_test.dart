import 'dart:io';

import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

({AppDatabase db, StorageRepository repo, String path}) _open() {
  final dir = Directory.systemTemp.createTempSync('calorias_ia_goal_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  final path = '${dir.path}/user_test.db';
  final db = AppDatabase(AppDatabase.openFile(path));
  return (db: db, repo: StorageRepository(db), path: path);
}

Future<void> _saveSampleInputs(StorageRepository repo) =>
    repo.saveGoalEstimationInputs(
      weightKg: 63,
      heightCm: 165,
      ageYears: 22,
      sex: 'female',
      activityLevel: 'lowActive',
    );

void main() {
  group('SPEC-008: meta diaria en user.db', () {
    test('sin meta guardada devuelve null', () async {
      final s = _open();
      addTearDown(s.db.close);
      expect(await s.repo.getNutritionGoal(), isNull);
      expect(await s.repo.getGoalEstimationInputs(), isNull);
    });

    test(
      'guardar dos veces reemplaza la fila única; macros opcionales',
      () async {
        final s = _open();
        addTearDown(s.db.close);

        await s.repo.saveNutritionGoal(energyKcal: 2000, proteinG: 100);
        await s.repo.saveNutritionGoal(energyKcal: 1800, proteinG: 90);

        final goal = await s.repo.getNutritionGoal();
        expect(goal!.energyKcal, 1800);
        expect(goal.proteinG, 90);
        expect(goal.carbsG, isNull);
        expect(goal.fatG, isNull);
        expect(await s.db.select(s.db.nutritionGoals).get(), hasLength(1));
      },
    );

    test('AC8: borrar los datos de la sugerencia conserva la meta', () async {
      final s = _open();
      addTearDown(s.db.close);
      await s.repo.saveNutritionGoal(energyKcal: 2000);
      await _saveSampleInputs(s.repo);

      await s.repo.deleteGoalEstimationInputs();

      expect(await s.repo.getGoalEstimationInputs(), isNull);
      expect((await s.repo.getNutritionGoal())!.energyKcal, 2000);
    });

    test(
      'AC8: borrar todo deja vacías la meta y los datos de la sugerencia',
      () async {
        final s = _open();
        addTearDown(s.db.close);
        await s.repo.saveNutritionGoal(energyKcal: 2000, fatG: 60);
        await _saveSampleInputs(s.repo);

        await s.repo.deleteAllUserData();

        expect(await s.db.select(s.db.nutritionGoals).get(), isEmpty);
        expect(await s.db.select(s.db.goalEstimationInputs).get(), isEmpty);
      },
    );

    test(
      'AC9: exportar incluye la meta y los datos de la sugerencia',
      () async {
        final s = _open();
        addTearDown(s.db.close);

        final empty = await s.repo.exportUserData();
        expect(empty['nutritionGoal'], isNull);
        expect(empty['goalEstimationInputs'], isNull);

        await s.repo.saveNutritionGoal(energyKcal: 2000, proteinG: 100);
        await _saveSampleInputs(s.repo);
        final export = await s.repo.exportUserData();

        final goal = export['nutritionGoal']! as Map<String, Object?>;
        expect(goal['energyKcal'], 2000);
        expect(goal['proteinG'], 100);
        expect(goal['carbsG'], isNull);
        final inputs = export['goalEstimationInputs']! as Map<String, Object?>;
        expect(inputs['weightKg'], 63);
        expect(inputs['heightCm'], 165);
        expect(inputs['ageYears'], 22);
        expect(inputs['sex'], 'female');
        expect(inputs['activityLevel'], 'lowActive');
      },
    );

    test('AC10: migrar desde la versión 3 conserva los datos y crea las tablas nuevas vacías', () async {
      final s = _open();
      await s.repo.registerMeal(
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
      await s.repo.savePersonalProduct(
        nameEs: 'Producto de prueba',
        energyKcal100: 466.7,
        proteinG100: 6.7,
        carbsG100: 66.7,
        fatG100: 20,
        servingGrams: 30,
        sourceRef: 'fixture de prueba',
      );
      await s.repo.saveConsent(policyVersion: 'v2');
      // Simula un user.db de la versión 3: sin las tablas de SPEC-008.
      await s.db.customStatement('DROP TABLE nutrition_goals');
      await s.db.customStatement('DROP TABLE goal_estimation_inputs');
      await s.db.customStatement('PRAGMA user_version = 3');
      await s.db.close();

      final db = AppDatabase(AppDatabase.openFile(s.path));
      addTearDown(db.close);
      final repo = StorageRepository(db);

      expect(await repo.mealsForDay(DateTime(2026, 10, 2)), hasLength(1));
      expect(await repo.getAllPersonalProducts(), hasLength(1));
      expect((await repo.getConsentState())!.policyVersion, 'v2');
      expect(await repo.getNutritionGoal(), isNull);
      expect(await repo.getGoalEstimationInputs(), isNull);
      final version = await db
          .customSelect('PRAGMA user_version')
          .map((row) => row.read<int>('user_version'))
          .getSingle();
      expect(version, 4);
    });
  });
}
