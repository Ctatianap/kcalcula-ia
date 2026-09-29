import 'package:flutter/foundation.dart';

import '../../infra/legal/privacy_policy.dart';
import '../../infra/storage/storage_repository.dart';

/// R2: dos casillas independientes, ninguna premarcada. `canContinue` exige
/// ambas — no hay forma de usar la app sin declarar mayoría de edad y sin
/// dar el consentimiento explícito (Out of Scope: no hay consentimiento
/// parcial por tipo de dato).
class OnboardingController extends ChangeNotifier {
  final StorageRepository _storage;

  bool ageConfirmed = false;
  bool consentGiven = false;

  OnboardingController({required StorageRepository storage})
    // ignore: prefer_initializing_formals
    : _storage = storage;

  bool get canContinue => ageConfirmed && consentGiven;

  void setAgeConfirmed(bool value) {
    ageConfirmed = value;
    notifyListeners();
  }

  void setConsentGiven(bool value) {
    consentGiven = value;
    notifyListeners();
  }

  /// R3: persiste el consentimiento con la versión vigente del texto de
  /// política y la marca de tiempo actual (`saveConsent`).
  Future<void> accept() async {
    if (!canContinue) {
      throw StateError('canContinue es false: faltan casillas por marcar.');
    }
    await _storage.saveConsent(policyVersion: privacyPolicyVersion);
  }
}
