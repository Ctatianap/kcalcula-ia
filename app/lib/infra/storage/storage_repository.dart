import 'package:drift/drift.dart';

import 'app_database.dart';

// SPEC-008: las features leen la meta sin depender de Drift directamente.
export 'app_database.dart' show NutritionGoal, UserProfileData;

/// Ítem ya calculado y confirmado por el usuario, listo para registrar
/// (R11). Exactamente uno de `foodId`/`personalProductId` no es `null`
/// (SPEC-004 R7) — nunca ambos, nunca ninguno (no debería llegar aquí: la
/// revisión bloquea Registrar mientras haya `ambiguous`/`not_found`).
class MealItemRecord {
  final String mention;
  final String? foodId;
  final int? personalProductId;
  final String nameSnapshot;
  final double grams;
  final double? quantityInput;
  final String? unitInput;
  final String? sizeInput;
  final String quantityBasis;
  final double energyKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String confidence;
  final String sourceRef;

  const MealItemRecord({
    required this.mention,
    required this.nameSnapshot,
    required this.grams,
    required this.quantityBasis,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidence,
    required this.sourceRef,
    this.foodId,
    this.personalProductId,
    this.quantityInput,
    this.unitInput,
    this.sizeInput,
  });
}

/// SPEC-008: valores de la meta a guardar (kcal y gramos sin redondear,
/// calculados en `nutrition_core`).
typedef NutritionGoalValues = ({
  String objective,
  bool isManual,
  double energyKcal,
  double proteinG,
  double carbsG,
  double fatG,
});

class StorageRepository {
  final AppDatabase _db;

  StorageRepository(this._db);

  /// R11: registra la comida y sus ítems en una sola transacción, con una
  /// instantánea de los valores (no referencias vivas al catálogo).
  Future<int> registerMeal({
    required DateTime eatenAt,
    required String? mealType,
    required String confidence,
    required String catalogVersion,
    required List<MealItemRecord> items,
  }) {
    return _db.transaction(() async {
      final mealId = await _db
          .into(_db.meals)
          .insert(
            MealsCompanion.insert(
              eatenAt: eatenAt,
              mealType: Value(mealType),
              confidence: confidence,
              catalogVersion: catalogVersion,
            ),
          );

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await _db
            .into(_db.mealItems)
            .insert(
              MealItemsCompanion.insert(
                mealId: mealId,
                position: i,
                mention: item.mention,
                nameSnapshot: item.nameSnapshot,
                grams: item.grams,
                quantityBasis: item.quantityBasis,
                energyKcal: item.energyKcal,
                proteinG: item.proteinG,
                carbsG: item.carbsG,
                fatG: item.fatG,
                confidence: item.confidence,
                sourceRef: item.sourceRef,
                foodId: Value(item.foodId),
                personalProductId: Value(item.personalProductId?.toString()),
                quantityInput: Value(item.quantityInput),
                unitInput: Value(item.unitInput),
                sizeInput: Value(item.sizeInput),
              ),
            );
      }

      return mealId;
    });
  }

  /// SPEC-004 R7: guarda un producto personal confirmado. Devuelve su `id`
  /// (autoincrement), que se guarda como texto en
  /// `meal_items.personal_product_id`.
  Future<int> savePersonalProduct({
    required String nameEs,
    required double energyKcal100,
    required double proteinG100,
    required double carbsG100,
    required double fatG100,
    required double servingGrams,
    required String sourceRef,
    double? fiberG100,
    double? sugarG100,
    double? sodiumMg100,
    double? densityGPerMl,
  }) {
    return _db
        .into(_db.personalProducts)
        .insert(
          PersonalProductsCompanion.insert(
            nameEs: nameEs,
            energyKcal100: energyKcal100,
            proteinG100: proteinG100,
            carbsG100: carbsG100,
            fatG100: fatG100,
            servingGrams: servingGrams,
            sourceRef: sourceRef,
            fiberG100: Value(fiberG100),
            sugarG100: Value(sugarG100),
            sodiumMg100: Value(sodiumMg100),
            densityGPerMl: Value(densityGPerMl),
          ),
        );
  }

  /// SPEC-004 R7: todos los productos personales, para que el
  /// `food_query_resolver` los filtre en Dart con el mismo normalizador
  /// (minúsculas + sin tildes) que usa para el catálogo — evita `LOWER()`
  /// de SQLite, que solo cubre ASCII y fallaría con nombres con tildes.
  /// Lista pequeña (productos propios del usuario): no hace falta FTS5.
  Future<List<PersonalProduct>> getAllPersonalProducts() =>
      _db.select(_db.personalProducts).get();

  Future<PersonalProduct?> getPersonalProductById(int id) => (_db.select(
    _db.personalProducts,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  /// SPEC-006: fila única (id 0). `null` significa "sin consentimiento
  /// registrado" — cubre tanto el primer lanzamiento (AC1) como después de
  /// revocar (AC14), a propósito no son estados distintos.
  Future<ConsentRecordData?> getConsentState() =>
      (_db.select(_db.consentRecord)).getSingleOrNull();

  /// R3: guarda (o reemplaza) la fila única de consentimiento con la marca
  /// de tiempo actual y la versión del texto de política aceptado.
  Future<void> saveConsent({required String policyVersion}) {
    return _db
        .into(_db.consentRecord)
        .insertOnConflictUpdate(
          ConsentRecordCompanion.insert(
            id: const Value(0),
            ageConfirmed: true,
            consentGiven: true,
            policyVersion: policyVersion,
            consentedAt: DateTime.now(),
          ),
        );
  }

  /// R8: revoca el consentimiento sin tocar `meals`/`meal_items`/
  /// `personal_products` — borrar la fila (no solo marcarla `false`) hace que
  /// `getConsentState()` vuelva a devolver `null`, el mismo estado que
  /// "primer lanzamiento".
  Future<void> revokeConsent() => (_db.delete(_db.consentRecord)).go();

  /// R5: borra todo el contenido nutricional del usuario. No toca
  /// `ConsentRecord` — borrar los datos no es lo mismo que revocar el
  /// consentimiento (R8/AC14 son la acción separada para eso).
  /// SPEC-008 R10: también la meta y los datos de la sugerencia.
  Future<void> deleteAllUserData() {
    return _db.transaction(() async {
      await _db.delete(_db.mealItems).go();
      await _db.delete(_db.meals).go();
      await _db.delete(_db.personalProducts).go();
      await _db.delete(_db.nutritionGoals).go();
      await _db.delete(_db.userProfile).go();
    });
  }

  /// SPEC-008 R1: perfil, o `null` si no se ha completado.
  Future<UserProfileData?> getUserProfile() =>
      _db.select(_db.userProfile).getSingleOrNull();

  /// SPEC-008 R1/R9: guarda el perfil y, si se pasa, la meta recalculada,
  /// en una sola transacción (o se guardan los dos, o ninguno).
  Future<void> saveUserProfile({
    required String sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    NutritionGoalValues? recalculatedGoal,
  }) {
    return _db.transaction(() async {
      await _db
          .into(_db.userProfile)
          .insertOnConflictUpdate(
            UserProfileCompanion.insert(
              id: const Value(0),
              sex: sex,
              birthDate: birthDate,
              heightCm: heightCm,
              weightKg: weightKg,
              activityLevel: activityLevel,
              updatedAt: DateTime.now(),
            ),
          );
      if (recalculatedGoal != null) await saveNutritionGoal(recalculatedGoal);
    });
  }

  /// SPEC-008 R8/R11: meta diaria vigente, o `null` si no hay.
  Future<NutritionGoal?> getNutritionGoal() =>
      _db.select(_db.nutritionGoals).getSingleOrNull();

  /// SPEC-008 R8/R10: guarda (o reemplaza) la meta única.
  Future<void> saveNutritionGoal(NutritionGoalValues goal) {
    return _db
        .into(_db.nutritionGoals)
        .insertOnConflictUpdate(
          NutritionGoalsCompanion.insert(
            id: const Value(0),
            objective: goal.objective,
            isManual: goal.isManual,
            energyKcal: goal.energyKcal,
            proteinG: goal.proteinG,
            carbsG: goal.carbsG,
            fatG: goal.fatG,
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// R7/AC7-AC9: instantánea completa en una forma directamente serializable
  /// a JSON (solo tipos primitivos y `DateTime`, que quien llame convierte
  /// con `toIso8601String()`) — ni tokens de red ni metadatos del backend,
  /// porque esos nunca se guardaron aquí (invariante 5 de CLAUDE.md).
  Future<Map<String, Object?>> exportUserData() async {
    final meals = await _db.select(_db.meals).get();
    final mealsJson = <Map<String, Object?>>[];
    for (final meal in meals) {
      final items =
          await (_db.select(_db.mealItems)
                ..where((i) => i.mealId.equals(meal.id))
                ..orderBy([(i) => OrderingTerm.asc(i.position)]))
              .get();
      mealsJson.add({
        'id': meal.id,
        'eatenAt': meal.eatenAt.toIso8601String(),
        'mealType': meal.mealType,
        'confidence': meal.confidence,
        'items': items
            .map(
              (i) => {
                'mention': i.mention,
                'nameSnapshot': i.nameSnapshot,
                'grams': i.grams,
                'energyKcal': i.energyKcal,
                'proteinG': i.proteinG,
                'carbsG': i.carbsG,
                'fatG': i.fatG,
                'confidence': i.confidence,
                'sourceRef': i.sourceRef,
              },
            )
            .toList(),
      });
    }

    final personalProducts = await getAllPersonalProducts();
    final goal = await getNutritionGoal();
    final profile = await getUserProfile();

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'meals': mealsJson,
      // SPEC-008 R10.
      'nutritionGoal': goal == null
          ? null
          : {
              'objective': goal.objective,
              'isManual': goal.isManual,
              'energyKcal': goal.energyKcal,
              'proteinG': goal.proteinG,
              'carbsG': goal.carbsG,
              'fatG': goal.fatG,
              'updatedAt': goal.updatedAt.toIso8601String(),
            },
      'userProfile': profile == null
          ? null
          : {
              'sex': profile.sex,
              'birthDate': profile.birthDate.toIso8601String(),
              'heightCm': profile.heightCm,
              'weightKg': profile.weightKg,
              'activityLevel': profile.activityLevel,
              'updatedAt': profile.updatedAt.toIso8601String(),
            },
      'personalProducts': personalProducts
          .map(
            (p) => {
              'id': p.id,
              'nameEs': p.nameEs,
              'energyKcal100': p.energyKcal100,
              'servingGrams': p.servingGrams,
              'sourceRef': p.sourceRef,
            },
          )
          .toList(),
    };
  }

  /// R12: comidas de un día local (por rango, no por igualdad de fecha, ya
  /// que `eatenAt` incluye hora).
  Future<List<MealWithItems>> mealsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final meals = await (_db.select(
      _db.meals,
    )..where((m) => m.eatenAt.isBetweenValues(start, end))).get();

    final result = <MealWithItems>[];
    for (final meal in meals) {
      final items =
          await (_db.select(_db.mealItems)
                ..where((i) => i.mealId.equals(meal.id))
                ..orderBy([(i) => OrderingTerm.asc(i.position)]))
              .get();
      result.add(MealWithItems(meal: meal, items: items));
    }
    return result;
  }
}

class MealWithItems {
  final Meal meal;
  final List<MealItem> items;

  const MealWithItems({required this.meal, required this.items});
}
