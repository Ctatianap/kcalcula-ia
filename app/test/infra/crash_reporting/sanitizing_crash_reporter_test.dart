import 'package:calorias_ia/infra/crash_reporting/crash_reporter.dart';
import 'package:calorias_ia/infra/crash_reporting/storage_failure.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart' show SqliteException;

class _RecordingReporter implements CrashReporter {
  final errors = <Object>[];
  final details = <FlutterErrorDetails>[];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  void recordFlutterFatalError(FlutterErrorDetails d) => details.add(d);

  @override
  Future<void> recordError(Object exception, StackTrace? stack) async =>
      errors.add(exception);
}

SqliteException _sqliteWithParams() => SqliteException(
  extendedResultCode: 19,
  message: 'constraint failed',
  causingStatement:
      'INSERT INTO meal_items (name_snapshot, grams) VALUES (?, ?)',
  parametersToStatement: ['pollo', 150],
);

void main() {
  test('el error de SQLite sí trae los datos (motivo de SPEC-009)', () {
    final text = _sqliteWithParams().toString();
    expect(text, contains('pollo'));
    expect(text, contains('150'));
  });

  test(
    'AC1: SqliteException → StorageFailure sin datos, con tipo y código',
    () async {
      final inner = _RecordingReporter();
      await SanitizingCrashReporter(inner)
          .recordError(_sqliteWithParams(), StackTrace.current);

      final sent = inner.errors.single.toString();
      expect(sent, isNot(contains('pollo')));
      expect(sent, isNot(contains('150')));
      expect(sent, isNot(contains('INSERT')));
      expect(sent, 'StorageFailure(SqliteException, sqlite=19)');
    },
  );

  test('AC1: otros errores se envían igual que antes', () async {
    final inner = _RecordingReporter();
    final error = StateError('algo técnico');
    await SanitizingCrashReporter(inner).recordError(error, null);
    expect(inner.errors.single, same(error));
  });

  test('AC2: error de Drift con causa SQLite (encadenada) se sanea', () async {
    final inner = _RecordingReporter();
    await SanitizingCrashReporter(inner).recordError(
      DriftWrappedException(message: 'falló', cause: _sqliteWithParams()),
      null,
    );
    expect(
      inner.errors.single.toString(),
      'StorageFailure(DriftWrappedException, sqlite=19)',
    );
  });

  test('AC2: un envoltorio desconocido que menciona SQLite se sanea', () async {
    final inner = _RecordingReporter();
    await SanitizingCrashReporter(inner)
        .recordError(Exception('wrapped: ${_sqliteWithParams()}'), null);
    final sent = inner.errors.single.toString();
    expect(sent, isNot(contains('pollo')));
    expect(sent, startsWith('StorageFailure('));
  });

  test('AC2: recordFlutterFatalError también sanea', () {
    final inner = _RecordingReporter();
    final stack = StackTrace.current;
    SanitizingCrashReporter(inner).recordFlutterFatalError(
      FlutterErrorDetails(exception: _sqliteWithParams(), stack: stack),
    );
    final d = inner.details.single;
    expect(d.exception, isA<StorageFailure>());
    expect(d.exception.toString(), isNot(contains('pollo')));
    expect(d.stack, same(stack));
  });

  test('AC2: recordFlutterFatalError con un error normal no cambia', () {
    final inner = _RecordingReporter();
    final details = FlutterErrorDetails(exception: StateError('x'));
    SanitizingCrashReporter(inner).recordFlutterFatalError(details);
    expect(inner.details.single, same(details));
  });
}
