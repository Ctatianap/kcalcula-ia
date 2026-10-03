import 'package:flutter/material.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../theme.dart';
import 'k_card.dart';

/// SPEC-011 R6: tarjeta de una comida registrada (tipo, hora, alimentos,
/// kcal y P/C/G). La comparten Hoy y el Historial (SPEC-013).
class MealCard extends StatelessWidget {
  final String label;
  final String time;
  final String itemsText;
  final NutrientTotals totals;

  const MealCard({
    super.key,
    required this.label,
    required this.time,
    required this.itemsText,
    required this.totals,
  });

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(fontSize: 13, color: KColors.textSecondary);
    return KCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(time, style: secondary),
            ],
          ),
          const SizedBox(height: 2),
          Text(itemsText, style: secondary),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              Text(
                '${presentKcal(totals.energyKcal)} kcal',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text('P ${formatMacroEs(totals.proteinG)} g', style: secondary),
              Text('C ${formatMacroEs(totals.carbsG)} g', style: secondary),
              Text('G ${formatMacroEs(totals.fatG)} g', style: secondary),
            ],
          ),
        ],
      ),
    );
  }
}
