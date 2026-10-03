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

/// SPEC-008 (v2) R1: perfil de la persona, fila única (id 0). Datos
/// personales de salud: solo en el dispositivo (R12).
class UserProfile extends Table {
  IntColumn get id => integer()();
  TextColumn get sex => text()();
  DateTimeColumn get birthDate => dateTime()();
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  TextColumn get activityLevel => text()();

  /// SPEC-008 R4: mantenimiento medido (p. ej. promedio de un reloj); si
  /// existe, manda sobre la fórmula.
  RealColumn get measuredMaintenanceKcal => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SPEC-008 (v2) R8–R10: meta diaria vigente, fila única (id 0), sin
/// historial. `objective` es el `GoalObjective` del que salió (o cuyo
/// reparto usa la meta manual); `isManual` = la persona escribió las kcal,
/// así que no se recalcula sola al cambiar el perfil (R9).
class NutritionGoals extends Table {
  IntColumn get id => integer()();
  TextColumn get objective => text()();
  BoolColumn get isManual => boolean()();
  RealColumn get energyKcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();
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
    UserProfile,
    NutritionGoals,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 6;

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
      if (from == 4) {
        // La v4 solo existió en builds de desarrollo de SPEC-008 v1, con
        // otras tablas de meta (nunca se publicó). Se reemplazan.
        await m.database.customStatement(
          'DROP TABLE IF EXISTS goal_estimation_inputs',
        );
        await m.database.customStatement(
          'DROP TABLE IF EXISTS nutrition_goals',
        );
      }
      if (from < 5) {
        await m.createTable(userProfile);
        await m.createTable(nutritionGoals);
      }
      if (from == 5) {
        // v5 solo existió en builds de desarrollo de SPEC-008.
        await m.addColumn(userProfile, userProfile.measuredMaintenanceKcal);
      }
    },
  );

  /// Base de datos real en disco (`user.db`), en la ruta que decida
  /// `infra` (normalmente el directorio de documentos de la app).
  static QueryExecutor openFile(String path) =>
      NativeDatabase.createInBackground(File(path));
}
