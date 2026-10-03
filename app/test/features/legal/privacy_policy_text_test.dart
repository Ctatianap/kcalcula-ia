import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SPEC-008 AC13: la política v3 menciona el perfil y la meta, y que no salen del teléfono', () {
    final text = File('assets/legal/privacy_policy_draft_es.md')
        .readAsStringSync();

    expect(text, contains('Versión: v3'));
    expect(text, contains('## Tu perfil y tu meta diaria (opcional)'));
    for (final dato in [
      'peso',
      'estatura',
      'fecha de nacimiento',
      'sexo',
      'actividad',
    ]) {
      expect(text, contains(dato));
    }
    expect(text, contains('Estos datos nunca\nsalen de tu dispositivo'));
    expect(text, contains('Borrar todos mis datos'));
  });
}
