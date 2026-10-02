import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

/// R11/R12: una comida registrada, con la confianza y la versión del
/// catálogo vigentes en el momento del registro.
class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get mealType => text().nullable()();
  TextColumn get confidence => text()();
  TextColumn get catalogVersion => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// R11: instantánea de los valores por ítem al momento de registrar — el
/// historial no cambia si el catálogo se actualiza después.
class MealItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId => integer().references(Meals, #id)();
  IntColumn get position => integer()();
  TextColumn get mention => text()();
  TextColumn get foodId => text().nullable()();
  TextColumn get personalProductId => text().nullable()();
  TextColumn get nameSnapshot => text()();
  RealColumn get grams => real()();
  RealColumn get quantityInput => real().nullable()();
  TextColumn get unitInput => text().nullable()();
  TextColumn get sizeInput => text().nullable()();
  TextColumn get quantityBasis => text()();
  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();
  TextColumn get confidence => text()();
  TextColumn get sourceRef => text()();
}

/// SPEC-004 R7: producto personal confirmado a partir de una foto de
/// etiqueta. Valores por 100 g/ml, igual convención que `catalog.db`, para
/// poder tratarlo como un `FoodCatalogEntry` en `nutrition_core` sin
/// duplicar lógica de cálculo. `sourceRef` es la auditoría de invariante 8
/// ("etiqueta confirmada" es una fuente válida): cuándo y qué se confirmó.
class PersonalProducts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nameEs => text()();
  RealColumn get energyKcal100 => real()();
  RealColumn get proteinG100 => real()();
  RealColumn get carbsG100 => real()();
  RealColumn get fatG100 => real()();
  RealColumn get fiberG100 => real().nullable()();
  RealColumn get sugarG100 => real().nullable()();
  RealColumn get sodiumMg100 => real().nullable()();

  /// Porción declarada en la etiqueta (R3: siempre > 0), usada como la
  /// única `PortionOption` ("porcion") del producto.
  RealColumn get servingGrams => real()();
  RealColumn get densityGPerMl => real().nullable()();
  TextColumn get sourceRef => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// SPEC-006 R3/R8: fila única (id fijo en 0) con el consentimiento y la
/// declaración de edad dados por el usuario. Su ausencia (tabla vacía) es la
/// misma señal para "primer lanzamiento" (AC1) y "consentimiento revocado"
/// (AC14) — no son estados distintos, así que `revokeConsent()` simplemente
/// borra la fila en vez de marcar un campo `false`.
class ConsentRecord extends Table {
  IntColumn get id => integer()();
  BoolColumn get ageConfirmed => boolean()();
  BoolColumn get consentGiven => boolean()();
  TextColumn get policyVersion => text()();
  DateTimeColumn get consentedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SPEC-008 R1/R8: fila única (id fijo en 0) con la meta diaria vigente.
/// kcal obligatoria; macros opcionales (`null` = sin meta para ese macro).
/// Sin historial: cambiar la meta cambia la referencia de todos los días.
class NutritionGoals extends Table {
  IntColumn get id => integer()();
  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbsG => real().nullable()();
  RealColumn get fatG => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SPEC-008 R2/R9: datos con los que se calculó la sugerencia. Fila única
/// (id 0), solo existe si el usuario pidió una sugerencia; se puede borrar
/// sin tocar la meta. Datos personales de salud: nunca salen del
/// dispositivo (R11).
class GoalEstimationInputs extends Table {
  IntColumn get id => integer()();
  RealColumn get weightKg => real()();
  RealColumn get heightCm => real()();
  IntColumn get ageYears => integer()();
  TextColumn get sex => text()();
  TextColumn get activityLevel => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Meals,
    MealItems,
    PersonalProducts,
    ConsentRecord,
    NutritionGoals,
    GoalEstimationInputs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(personalProducts);
      }
      if (from < 3) {
        await m.createTable(consentRecord);
      }
      if (from < 4) {
        await m.createTable(nutritionGoals);
        await m.createTable(goalEstimationInputs);
      }
    },
  );

  /// Base de datos real en disco (`user.db`), en la ruta que decida
  /// `infra` (normalmente el directorio de documentos de la app).
  static QueryExecutor openFile(String path) =>
      NativeDatabase.createInBackground(File(path));
}
