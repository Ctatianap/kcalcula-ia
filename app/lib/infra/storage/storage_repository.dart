import 'package:drift/drift.dart';

import 'app_database.dart';

/// Ítem ya calculado y confirmado por el usuario, listo para registrar
/// (R11). `foodId` es `null` para ítems sin catálogo (no debería llegar
/// aquí: la revisión bloquea Registrar mientras haya `ambiguous`/`not_found`).
class MealItemRecord {
  final String mention;
  final String? foodId;
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
                quantityInput: Value(item.quantityInput),
                unitInput: Value(item.unitInput),
                sizeInput: Value(item.sizeInput),
              ),
            );
      }

      return mealId;
    });
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
