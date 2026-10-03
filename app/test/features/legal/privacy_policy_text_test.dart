import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SPEC-008 AC13: la política menciona el perfil y la meta, y que no salen del teléfono', () {
    final text = File('assets/legal/privacy_policy_draft_es.md')
        .readAsStringSync();

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

  test('SPEC-015 AC7: la política v4 menciona el historial de peso, que no '
      'sale del teléfono, se borra y se exporta', () {
    final text = File('assets/legal/privacy_policy_draft_es.md')
        .readAsStringSync();
    expect(text, contains('Versión: v4'));
    expect(text, contains('## Tu historial de peso (opcional)'));
    expect(text, contains('**Este historial nunca sale de tu dispositivo**'));
    expect(text, contains('"Exportar mis datos" lo incluye'));
  });
}
