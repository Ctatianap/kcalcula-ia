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

@DriftDatabase(tables: [Meals, MealItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  /// Base de datos real en disco (`user.db`), en la ruta que decida
  /// `infra` (normalmente el directorio de documentos de la app).
  static QueryExecutor openFile(String path) =>
      NativeDatabase.createInBackground(File(path));
}
