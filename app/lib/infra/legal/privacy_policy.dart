import 'package:flutter/services.dart' show rootBundle;

/// SPEC-006 R3: versión del texto de política que se guarda junto al
/// consentimiento (`ConsentRecord.policyVersion`). Cambiar el texto del
/// asset sin subir esta constante no re-pide consentimiento; solo súbela
/// cuando el cambio sea sustantivo (no una corrección de tipeo).
const privacyPolicyVersion = 'v1';

const _privacyPolicyAssetPath = 'assets/legal/privacy_policy_draft_es.md';

/// R6/AC10-AC11: el texto completo del borrador, como asset (no hardcodeado
/// en Dart) para poder actualizarlo sin recompilar lógica — mismo criterio
/// que `ensureCatalogDbFile` para `catalog.db`.
Future<String> loadPrivacyPolicyDraft() =>
    rootBundle.loadString(_privacyPolicyAssetPath);
