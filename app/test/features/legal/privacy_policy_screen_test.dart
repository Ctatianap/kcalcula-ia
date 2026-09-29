import 'package:calorias_ia/features/legal/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'AC10/AC11: carga y muestra el texto real del asset de política',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

      // Primer frame: todavía cargando el asset con rootBundle.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Contenido real de app/assets/legal/privacy_policy_draft_es.md, no
      // un doble simulado — si la ruta del asset o `pubspec.yaml` se
      // desalinean, este test falla.
      expect(find.textContaining('BORRADOR'), findsWidgets);
      expect(find.textContaining('Vertex AI'), findsWidgets);
      expect(find.textContaining('Borrar todos tus datos'), findsOneWidget);
    },
  );
}
