import 'package:drift/drift.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
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

/// Textos que delatan un error de almacenamiento dentro de un envoltorio
/// desconocido (red de seguridad).
const _storageErrorMarkers = [
  'SqliteException',
  'InvalidDataException',
  'CouldNotRollBackException',
];

/// Devuelve un [StorageFailure] si [error] (o su causa encadenada, hasta 5
/// niveles) es un error de almacenamiento; si no, `null`.
StorageFailure? storageFailureFor(Object error, [int depth = 0]) {
  if (depth > 5) return const StorageFailure('nested');
  return switch (error) {
    StorageFailure() => error,
    SqliteException() => StorageFailure(
      'SqliteException',
      error.extendedResultCode,
    ),
    DriftRemoteException(:final remoteCause) => StorageFailure(
      'DriftRemoteException',
      _codeOf(remoteCause, depth),
    ),
    DriftWrappedException(:final cause) => StorageFailure(
      'DriftWrappedException',
      cause == null ? null : _codeOf(cause, depth),
    ),
    CouldNotRollBackException(:final cause) => StorageFailure(
      'CouldNotRollBackException',
      _codeOf(cause, depth),
    ),
    InvalidDataException() => const StorageFailure('InvalidDataException'),
    _ when _storageErrorMarkers.any(error.toString().contains) =>
      StorageFailure(error.runtimeType.toString()),
    _ => null,
  };
}

/// Código de SQLite de la causa, buscando en causas encadenadas.
int? _codeOf(Object cause, int depth) =>
    storageFailureFor(cause, depth + 1)?.sqliteResultCode;
