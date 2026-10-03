import 'package:flutter/services.dart' show rootBundle;

/// SPEC-006 R3: versión del texto de política que se guarda junto al
/// consentimiento (`ConsentRecord.policyVersion`). Cambiar el texto del
/// asset sin subir esta constante no re-pide consentimiento; solo súbela
/// cuando el cambio sea sustantivo (no una corrección de tipeo).
///
/// SPEC-007 R5: `_RootGate` compara este valor contra el guardado — si no
/// coincide, vuelve a mostrar el onboarding aunque ya exista un
/// `ConsentRecord`. `'v2'` (2026-09-30) añade el reporte de fallos
/// (Crashlytics). `'v3'` (2026-10-02, SPEC-008 R13) añade el perfil (datos personales
/// de salud) y la meta diaria, que se guardan solo en el teléfono.
const privacyPolicyVersion = 'v3';

const _privacyPolicyAssetPath = 'assets/legal/privacy_policy_draft_es.md';

/// R6/AC10-AC11: el texto completo del borrador, como asset (no hardcodeado
/// en Dart) para poder actualizarlo sin recompilar lógica — mismo criterio
/// que `ensureCatalogDbFile` para `catalog.db`.
Future<String> loadPrivacyPolicyDraft() =>
    rootBundle.loadString(_privacyPolicyAssetPath);
