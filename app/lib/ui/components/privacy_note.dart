import 'package:flutter/material.dart';

import '../theme.dart';

/// SPEC-012 R1/R2: nota fija sobre qué hace la IA y qué hace el teléfono.
/// Repite lo que ya dice la política de privacidad; no promete nada nuevo.
const privacyNoteText =
    'Tu texto o foto se envía a la IA solo para estructurarlo. Las calorías '
    'las calcula tu teléfono.';

class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 16, color: KColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            privacyNoteText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
