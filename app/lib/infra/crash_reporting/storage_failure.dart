import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// SPEC-009 R1: lo único que se reporta de un error de `user.db`. El
/// mensaje de `SqliteException` incluye la sentencia y sus parámetros
/// (alimentos, cantidades, perfil), así que nunca se envía: solo el tipo
/// original y el código numérico de resultado de SQLite.
class StorageFailure implements Exception {
  final String originalType;
  final int? sqliteResultCode;

  const StorageFailure(this.originalType, [this.sqliteResultCode]);

  @override
  String toString() => sqliteResultCode == null
      ? 'StorageFailure($originalType)'
      : 'StorageFailure($originalType, sqlite=$sqliteResultCode)';
}

/// Devuelve un [StorageFailure] si [error] (o su causa encadenada) es un
/// error de almacenamiento; si no, `null`.
StorageFailure? storageFailureFor(Object error, [int depth = 0]) {
  if (depth > 5) return const StorageFailure('nested');
  return switch (error) {
    StorageFailure() => error,
    SqliteException() => StorageFailure(
      'SqliteException',
      error.extendedResultCode,
    ),
    // `DriftRemoteException` (errores que vienen del isolate de la base) se
    // identifica por nombre: su librería (`drift/remote.dart`) es
    // experimental. Su `toString()` es el de la causa (el texto de SQLite).
    _ when error.runtimeType.toString() == 'DriftRemoteException' =>
      const StorageFailure('DriftRemoteException'),
    DriftWrappedException(:final cause) => StorageFailure(
      'DriftWrappedException',
      cause == null ? null : _codeOf(cause),
    ),
    CouldNotRollBackException(:final cause) => StorageFailure(
      'CouldNotRollBackException',
      _codeOf(cause),
    ),
    InvalidDataException() => const StorageFailure('InvalidDataException'),
    // Red de seguridad: cualquier otro envoltorio cuyo texto incluya un
    // error de SQLite.
    _ when error.toString().contains('SqliteException') => StorageFailure(
      error.runtimeType.toString(),
    ),
    _ => null,
  };
}

int? _codeOf(Object cause) =>
    cause is SqliteException ? cause.extendedResultCode : null;
