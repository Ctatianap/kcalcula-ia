import 'package:flutter/foundation.dart';

import '../../infra/crash_reporting/crash_reporter.dart';
import '../../infra/storage/storage_repository.dart';

/// R5, R8: acciones de Ajustes que tocan datos del usuario (exportar vive
/// en `ExportScreen` desde SPEC-016). La confirmación ("¿seguro?") es responsabilidad de la pantalla (diálogo),
/// no de este controller — aquí solo vive lo que pasa una vez confirmado.
class SettingsController extends ChangeNotifier {
  final StorageRepository _storage;
  final CrashReporter _crashReporter;

  bool busy = false;

  SettingsController({
    required StorageRepository storage,
    required CrashReporter crashReporter,
  })
    // ignore: prefer_initializing_formals
    : _storage = storage,
       // ignore: prefer_initializing_formals
       _crashReporter = crashReporter;

  Future<void> deleteAllData() => _run(_storage.deleteAllUserData);

  /// SPEC-007 R5: revocar también detiene el reporte de fallos — invariante
  /// 6 de CLAUDE.md no distingue entre tipos de dato, "nada sale del
  /// dispositivo sin consentimiento vigente" aplica a Crashlytics igual que
  /// a la IA. AC12: si desactivar el crash reporter falla (p. ej. sin red),
  /// no debe hacer parecer que la revocación misma falló — el consentimiento
  /// ya se borró, que es lo que le importa al usuario.
  Future<void> revokeConsent() => _run(() async {
    await _storage.revokeConsent();
    try {
      await _crashReporter.setCollectionEnabled(false);
    } catch (_) {
      // Ver comentario arriba: no hace fallar la revocación.
    }
  });

  Future<void> _run(Future<void> Function() action) async {
    busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
