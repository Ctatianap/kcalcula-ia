import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../theme.dart';
import 'confidence_indicator.dart';
import 'k_card.dart';
import 'meal_actions.dart';

/// SPEC-011 R6: tarjeta de una comida registrada (tipo, hora, alimentos,
/// kcal y P/C/G). La comparten Hoy y el Historial (SPEC-013).
class MealCard extends StatelessWidget {
  final String label;
  final String time;

  /// Nombre y gramos de cada ítem: "Huevo 100 g · Arepa 115 g".
  final List<({String name, double grams})> items;
  final NutrientTotals totals;

  /// SPEC-023 R4: el nivel guardado de la comida (`null` si no se reconoce).
  final ConfidenceLevel? confidence;

  /// SPEC-026 R1: abre la comida para editarla.
  final VoidCallback? onTap;

  /// SPEC-037 R1: mantener presionada; recibe dónde está la tarjeta para
  /// abrir el menú junto a ella.
  final void Function(RelativeRect position)? onLongPress;

  const MealCard({
    super.key,
    required this.label,
    required this.time,
    required this.items,
    required this.totals,
    this.confidence,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(fontSize: 13, color: KColors.textSecondary);
    final card = KCard(
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
          Text(
            items.map((i) => '${i.name} ${i.grams.round()} g').join(' · '),
            style: secondary,
          ),
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
          if (confidence case final level?) ...[
            const SizedBox(height: 6),
            ConfidenceIndicator(level: level, compact: true),
          ],
        ],
      ),
    );
    if (onTap == null && onLongPress == null) return card;
    final longPress = onLongPress;
    void openMenu() => longPress?.call(_positionOf(context));
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      onLongPress: longPress == null ? null : openMenu,
      child: Semantics(
        button: true,
        hint: switch ((onTap != null, longPress != null)) {
          (true, true) => mealCardHint,
          (true, false) => 'Toca para editar o borrar',
          (false, _) => longPressOnlyHint,
        },
        // SPEC-037 R4: el menú también para el lector de pantalla.
        customSemanticsActions: longPress == null
            ? null
            : {const CustomSemanticsAction(label: moreOptionsAction): openMenu},
        child: card,
      ),
    );
  }

  /// La tarjeta, relativa a la capa donde se abre el menú.
  static RelativeRect _positionOf(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final rect = Rect.fromPoints(
      box.localToGlobal(box.size.topRight(Offset.zero), ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    return RelativeRect.fromRect(rect, Offset.zero & overlay.size);
  }
}
