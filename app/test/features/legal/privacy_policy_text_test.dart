import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SPEC-008 AC13: la política v3 menciona la meta y los datos de la '
      'sugerencia, y que no salen del teléfono', () {
    final text = File('assets/legal/privacy_policy_draft_es.md')
        .readAsStringSync();

    expect(text, contains('Versión: v3'));
    expect(text, contains('## Tu meta diaria (opcional)'));
    for (final dato in ['peso', 'estatura', 'edad', 'sexo', 'actividad']) {
      expect(text, contains(dato));
    }
    expect(text, contains('Nunca salen de tu\ndispositivo'));
    expect(text, contains('Borrar mis datos para la sugerencia'));
  });
}
