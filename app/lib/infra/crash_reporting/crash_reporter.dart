import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'storage_failure.dart';

/// SPEC-007 R4: detrás de una interfaz propia por la misma razón que
/// `SharingService`/`ImagePickerService`: envuelve un SDK real, no se puede
/// simular directamente en un test. La recolección arranca **desactivada**
/// (`main()`) y solo se activa cuando `_RootGate` confirma consentimiento
/// vigente — nunca antes de que el usuario acepte (invariante 6 de
/// CLAUDE.md).
abstract class CrashReporter {
  /// R4/R5: activa o desactiva el envío de reportes. `false` en `main()`;
  /// `true` solo tras confirmar `ConsentRecord` vigente; `false` de nuevo
  /// al revocar el consentimiento (SPEC-006 R8).
  Future<void> setCollectionEnabled(bool enabled);

  /// Captura errores de Flutter no controlados (`FlutterError.onError`).
  /// Nunca recibe contenido de usuario — solo lo que el framework reporta
  /// por defecto (stack trace, mensaje técnico del framework).
  void recordFlutterFatalError(FlutterErrorDetails details);

  /// Captura errores async no controlados
  /// (`PlatformDispatcher.instance.onError`). Mismo criterio: nunca
  /// contenido de usuario.
  Future<void> recordError(Object exception, StackTrace? stack);
}

class FirebaseCrashReporter implements CrashReporter {
  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) =>
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);

  @override
  Future<void> recordError(Object exception, StackTrace? stack) =>
      FirebaseCrashlytics.instance.recordError(exception, stack, fatal: true);
}

/// SPEC-009 R1: envuelve al reporte real y reemplaza los errores de
/// almacenamiento por un [StorageFailure] sin datos del usuario, en los dos
/// caminos (`recordError` y `recordFlutterFatalError`). El stack trace se
/// conserva: solo trae nombres de funciones y archivos.
class SanitizingCrashReporter implements CrashReporter {
  final CrashReporter _inner;

  SanitizingCrashReporter(this._inner);

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _inner.setCollectionEnabled(enabled);

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {
    final failure = storageFailureFor(details.exception);
    _inner.recordFlutterFatalError(
      failure == null
          ? details
          : FlutterErrorDetails(
              exception: failure,
              stack: details.stack,
              library: details.library,
            ),
    );
  }

  @override
  Future<void> recordError(Object exception, StackTrace? stack) =>
      _inner.recordError(storageFailureFor(exception) ?? exception, stack);
}
