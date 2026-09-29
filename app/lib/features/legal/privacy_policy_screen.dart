import 'package:flutter/material.dart';

import '../../infra/legal/privacy_policy.dart';

/// R6/AC10-AC11: pantalla compartida (no pertenece a onboarding ni a
/// settings, ambas navegan a ella por nombre de ruta — "las features no se
/// importan entre sí") que muestra el texto completo del borrador de
/// política, cargado desde el asset.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidad')),
      body: FutureBuilder<String>(
        future: loadPrivacyPolicyDraft(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Ocurrió un error. Intenta de nuevo.'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(snapshot.data!),
          );
        },
      ),
    );
  }
}
