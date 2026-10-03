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

Future<void> _saveSampleProfile(
  StorageRepository repo, {
  NutritionGoalValues? recalculatedGoal,
}) => repo.saveUserProfile(
  sex: 'female',
  birthDate: DateTime(1996, 10, 15),
  heightCm: 165,
  weightKg: 63,
  activityLevel: 'lightlyActive',
  recalculatedGoal: recalculatedGoal,
);

NutritionGoalValues _goal(
  double kcal, {
  String objective = 'maintain',
  bool isManual = false,
}) => (
  objective: objective,
  isManual: isManual,
  energyKcal: kcal,
  proteinG: kcal * 0.2 / 4,
  carbsG: kcal * 0.55 / 4,
  fatG: kcal * 0.25 / 9,
);

void main() {
  group('SPEC-008: perfil y meta en user.db', () {
    test('sin perfil ni meta devuelve null', () async {
      final s = _open();
      addTearDown(s.db.close);
      expect(await s.repo.getUserProfile(), isNull);
      expect(await s.repo.getNutritionGoal(), isNull);
    });

    test('perfil y meta: fila única que se reemplaza', () async {
      final s = _open();
      addTearDown(s.db.close);
      await _saveSampleProfile(s.repo);
      await s.repo.saveNutritionGoal(_goal(2000));
      await s.repo.saveNutritionGoal(_goal(1500, objective: 'loseFat'));

      final profile = await s.repo.getUserProfile();
      expect(profile!.weightKg, 63);
      expect(profile.activityLevel, 'lightlyActive');
      final goal = await s.repo.getNutritionGoal();
      expect(goal!.energyKcal, 1500);
      expect(goal.objective, 'loseFat');
      expect(goal.isManual, isFalse);
      expect(await s.db.select(s.db.nutritionGoals).get(), hasLength(1));
    });

    test(
      'R9: guardar el perfil con meta recalculada actualiza las dos',
      () async {
        final s = _open();
        addTearDown(s.db.close);
        await s.repo.saveNutritionGoal(_goal(2000));
        await _saveSampleProfile(s.repo, recalculatedGoal: _goal(2100));
        expect((await s.repo.getNutritionGoal())!.energyKcal, 2100);
      },
    );

    test('AC13: borrar todo deja vacíos el perfil y la meta', () async {
      final s = _open();
      addTearDown(s.db.close);
      await _saveSampleProfile(s.repo);
      await s.repo.saveNutritionGoal(_goal(2000));

      await s.repo.deleteAllUserData();

      expect(await s.db.select(s.db.userProfile).get(), isEmpty);
      expect(await s.db.select(s.db.nutritionGoals).get(), isEmpty);
    });

    test('AC13: exportar incluye el perfil y la meta', () async {
      final s = _open();
      addTearDown(s.db.close);

      final empty = await s.repo.exportUserData();
      expect(empty['userProfile'], isNull);
      expect(empty['nutritionGoal'], isNull);

      await _saveSampleProfile(s.repo);
      await s.repo.saveNutritionGoal(_goal(2000, isManual: true));
      final export = await s.repo.exportUserData();

      final goal = export['nutritionGoal']! as Map<String, Object?>;
      expect(goal['energyKcal'], 2000);
      expect(goal['objective'], 'maintain');
      expect(goal['isManual'], isTrue);
      final profile = export['userProfile']! as Map<String, Object?>;
      expect(profile['weightKg'], 63);
      expect(profile['heightCm'], 165);
      expect(profile['sex'], 'female');
      expect(profile['activityLevel'], 'lightlyActive');
      expect(profile['birthDate'], startsWith('1996-10-15'));
    });

    test('AC13: migrar desde la versión 3 conserva los datos y crea las tablas nuevas vacías', () async {
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
      await s.db.customStatement('DROP TABLE user_profile');
      await s.db.customStatement('PRAGMA user_version = 3');
      await s.db.close();

      final db = AppDatabase(AppDatabase.openFile(s.path));
      addTearDown(db.close);
      final repo = StorageRepository(db);

      expect(await repo.mealsForDay(DateTime(2026, 10, 2)), hasLength(1));
      expect(await repo.getAllPersonalProducts(), hasLength(1));
      expect((await repo.getConsentState())!.policyVersion, 'v2');
      expect(await repo.getNutritionGoal(), isNull);
      expect(await repo.getUserProfile(), isNull);
      final version = await db
          .customSelect('PRAGMA user_version')
          .map((row) => row.read<int>('user_version'))
          .getSingle();
      expect(version, 5);
    });

    test('migrar desde la v4 de desarrollo (SPEC-008 v1) reemplaza las tablas de meta y conserva las comidas', () async {
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
      // Esquema de la v4 de SPEC-008 v1.
      await s.db.customStatement('DROP TABLE nutrition_goals');
      await s.db.customStatement('DROP TABLE user_profile');
      await s.db.customStatement(
        'CREATE TABLE nutrition_goals (id INTEGER PRIMARY KEY, '
        'energy_kcal REAL NOT NULL, protein_g REAL, carbs_g REAL, '
        'fat_g REAL, updated_at INTEGER NOT NULL)',
      );
      await s.db.customStatement(
        'CREATE TABLE goal_estimation_inputs (id INTEGER PRIMARY KEY, '
        'weight_kg REAL NOT NULL)',
      );
      await s.db.customStatement(
        'INSERT INTO nutrition_goals VALUES (0, 2000, NULL, NULL, NULL, 0)',
      );
      await s.db.customStatement('PRAGMA user_version = 4');
      await s.db.close();

      final db = AppDatabase(AppDatabase.openFile(s.path));
      addTearDown(db.close);
      final repo = StorageRepository(db);

      expect(await repo.mealsForDay(DateTime(2026, 10, 2)), hasLength(1));
      expect(await repo.getNutritionGoal(), isNull);
      expect(await repo.getUserProfile(), isNull);
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name = 'goal_estimation_inputs'",
          )
          .get();
      expect(tables, isEmpty);
    });
  });
}
