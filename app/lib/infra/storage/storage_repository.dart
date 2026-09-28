import 'package:drift/drift.dart';

import 'app_database.dart';

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
