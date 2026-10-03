import 'package:drift/drift.dart';
import 'package:nutrition_core/nutrition_core.dart';

import 'app_database.dart';
import 'goal_sync.dart';

// SPEC-008: las features leen la meta sin depender de Drift directamente.
export 'app_database.dart'
    show
        ConsentRecordData,
        NutritionGoal,
        PersonalProduct,
        UserProfileData,
        WeightLogData;

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
  /// SPEC-008 R12: también el perfil y la meta.
  Future<void> deleteAllUserData() {
    return _db.transaction(() async {
      await _db.delete(_db.mealItems).go();
      await _db.delete(_db.meals).go();
      await _db.delete(_db.personalProducts).go();
      await _db.delete(_db.nutritionGoals).go();
      await _db.delete(_db.userProfile).go();
      // SPEC-015 R6.
      await _db.delete(_db.weightLog).go();
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
    double? measuredMaintenanceKcal,
    NutritionGoalValues? recalculatedGoal,
    DateTime? weightLogDay,
  }) {
    return _db.transaction(() async {
      // SPEC-015 R2: guardar el perfil con otro peso crea el registro del
      // día, en la misma transacción.
      if (weightLogDay != null) await _upsertWeight(weightLogDay, weightKg);
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
              measuredMaintenanceKcal: Value(measuredMaintenanceKcal),
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
    final weights = await weightEntries();

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'meals': mealsJson,
      // SPEC-008 R12.
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
              'measuredMaintenanceKcal': profile.measuredMaintenanceKcal,
              'updatedAt': profile.updatedAt.toIso8601String(),
            },
      // SPEC-015 R6.
      'weightLog': weights
          .map((w) => {'day': w.day.toIso8601String(), 'weightKg': w.weightKg})
          .toList(),
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

  /// SPEC-015: registros de peso desde [from] (incluido), del más antiguo al
  /// más reciente.
  Future<List<WeightLogData>> weightEntries({DateTime? from}) {
    final query = _db.select(_db.weightLog)
      ..orderBy([(w) => OrderingTerm.asc(w.day)]);
    if (from != null) {
      final start = DateTime(from.year, from.month, from.day);
      query.where((w) => w.day.isBiggerOrEqualValue(start));
    }
    return query.get();
  }

  Future<void> _upsertWeight(DateTime day, double kg) => _db
      .into(_db.weightLog)
      .insertOnConflictUpdate(
        WeightLogCompanion.insert(
          day: DateTime(day.year, day.month, day.day),
          weightKg: kg,
          updatedAt: DateTime.now(),
        ),
      );

  /// SPEC-015 R1/R3: anota el peso del día (reemplaza el de ese día si ya
  /// había) y deja el perfil con el último peso, recalculando una meta de
  /// objetivo (SPEC-008 R9), todo en una transacción. Devuelve `true` si una
  /// meta de objetivo no se pudo recalcular (queda fuera de 800–6.000).
  Future<bool> logWeight({required DateTime day, required double kg}) =>
      _db.transaction(() async {
        await _upsertWeight(day, kg);
        return _syncProfileWithLatestWeight(day);
      });

  /// SPEC-015 R5: borra el registro de ese día. Si era el más reciente, el
  /// perfil pasa al anterior (y la meta se recalcula); si no queda ninguno,
  /// el perfil conserva su peso.
  Future<bool> deleteWeight({required DateTime day, required DateTime today}) =>
      _db.transaction(() async {
        await (_db.delete(_db.weightLog)..where(
              (w) => w.day.equals(DateTime(day.year, day.month, day.day)),
            ))
            .go();
        return _syncProfileWithLatestWeight(today);
      });

  Future<bool> _syncProfileWithLatestWeight(DateTime today) async {
    final latest =
        await (_db.select(_db.weightLog)
              ..orderBy([(w) => OrderingTerm.desc(w.day)])
              ..limit(1))
            .getSingleOrNull();
    final profile = await getUserProfile();
    if (latest == null || profile == null) return false;
    if (profile.weightKg == latest.weightKg) return false;
    final updated = profile.copyWith(
      weightKg: latest.weightKg,
      updatedAt: DateTime.now(),
    );
    await _db.into(_db.userProfile).insertOnConflictUpdate(updated);
    final goal = await getNutritionGoal();
    final recalculated = recalculatedGoal(
      goal,
      maintenanceForProfile(updated, today),
    );
    if (recalculated != null) await saveNutritionGoal(recalculated);
    return goal != null && !goal.isManual && recalculated == null;
  }

  /// R12: comidas de un día local.
  Future<List<MealWithItems>> mealsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return mealsBetween(start, start.add(const Duration(days: 1)));
  }

  /// SPEC-011: comidas con `eatenAt` en [start, end) (fin excluido), en
  /// orden por hora.
  Future<List<MealWithItems>> mealsBetween(DateTime start, DateTime end) async {
    final meals =
        await (_db.select(_db.meals)
              ..where(
                (m) =>
                    m.eatenAt.isBiggerOrEqualValue(start) &
                    m.eatenAt.isSmallerThanValue(end),
              )
              ..orderBy([(m) => OrderingTerm.asc(m.eatenAt)]))
            .get();

    // Ítems en lote (no una consulta por comida), en tandas para no pasar
    // el límite de parámetros de SQLite.
    final itemsByMeal = <int, List<MealItem>>{};
    final ids = meals.map((m) => m.id).toList();
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      final items =
          await (_db.select(_db.mealItems)
                ..where((item) => item.mealId.isIn(chunk))
                ..orderBy([
                  (item) => OrderingTerm.asc(item.mealId),
                  (item) => OrderingTerm.asc(item.position),
                ]))
              .get();
      for (final item in items) {
        itemsByMeal.putIfAbsent(item.mealId, () => []).add(item);
      }
    }
    return [
      for (final meal in meals)
        MealWithItems(meal: meal, items: itemsByMeal[meal.id] ?? const []),
    ];
  }
}

class MealWithItems {
  final Meal meal;
  final List<MealItem> items;

  const MealWithItems({required this.meal, required this.items});

  /// Suma de las instantáneas de sus ítems, sin redondear (la comparten Hoy,
  /// Historial y Progreso).
  NutrientTotals get totals => sumNutrients(
    items.map(
      (item) => (
        energyKcal: item.energyKcal,
        proteinG: item.proteinG,
        carbsG: item.carbsG,
        fatG: item.fatG,
      ),
    ),
  );
}
