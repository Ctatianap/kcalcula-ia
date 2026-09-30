import 'package:calorias_ia/infra/crash_reporting/crash_reporter.dart';
import 'package:flutter/foundation.dart';

class FakeCrashReporter implements CrashReporter {
  bool? collectionEnabled;

  /// Simula que activar/desactivar la recolección falla (sin red, SDK sin
  /// inicializar, etc. — Edge Case de SPEC-007 AC12).
  bool shouldThrow;

  FakeCrashReporter({this.shouldThrow = false});

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    if (shouldThrow) {
      throw Exception('crash reporter no disponible (simulado en el test)');
    }
    collectionEnabled = enabled;
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {}

  @override
  Future<void> recordError(Object exception, StackTrace? stack) async {}
}
