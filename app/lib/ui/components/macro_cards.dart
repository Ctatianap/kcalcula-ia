import 'package:flutter/material.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../theme.dart';
import 'k_card.dart';
import 'progress_ring.dart';

/// Un macro para [MacroCards]: gramos y, si hay meta, la meta del día.
typedef MacroCardData = ({
  String label,
  double grams,
  double? goal,
  Color color,
});

/// Tres tarjetas con un anillo por macro (SPEC-011 R5). Compartidas por
/// "Hoy" y la vista previa de "Confirmar etiqueta" (SPEC-032 R4). Sin
/// meta, el anillo queda vacío y no se muestra "de N g".
class MacroCards extends StatelessWidget {
  final List<MacroCardData> macros;

  const MacroCards({super.key, required this.macros});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, macro) in macros.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _MacroCard(macro: macro)),
        ],
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final MacroCardData macro;

  const _MacroCard({required this.macro});

  @override
  Widget build(BuildContext context) {
    final goal = macro.goal;
    return KCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
      child: Column(
        children: [
          Text(
            macro.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: KColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ProgressRing(
            fraction: goal == null
                ? 0
                : GoalProgress(consumed: macro.grams, goal: goal).fraction,
            color: macro.color,
            semanticsLabel: goal == null
                ? '${macro.label}: ${formatMacroEs(macro.grams)} g'
                : '${macro.label}: ${formatMacroEs(macro.grams)} de '
                      '${formatMacroEs(goal)} g',
            // Con texto grande el número se reduce para no salirse del
            // anillo.
            center: Padding(
              padding: const EdgeInsets.all(8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMacroEs(macro.grams),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (goal != null) ...[
            const SizedBox(height: 8),
            Text(
              'de ${formatMacroEs(goal)} g',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: KColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
