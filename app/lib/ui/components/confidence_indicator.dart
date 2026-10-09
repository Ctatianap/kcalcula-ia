import 'package:flutter/material.dart';
import 'package:nutrition_core/nutrition_core.dart';

import '../theme.dart';

/// SPEC-023 R1: nombre de cada nivel de confianza (lo calcula
/// `nutrition_core`; aquí solo se presenta).
const confidenceLevelLabels = {
  ConfidenceLevel.altaPrecision: 'Alta precisión',
  ConfidenceLevel.buenaEstimacion: 'Buena estimación',
  ConfidenceLevel.estimacion: 'Estimación',
};

/// SPEC-023 R1: círculo lleno, a medias y en contorno. El nivel nunca
/// depende solo del color: siempre va con su texto.
IconData confidenceIcon(ConfidenceLevel level) => switch (level) {
  ConfidenceLevel.altaPrecision => Icons.circle,
  ConfidenceLevel.buenaEstimacion => Icons.contrast,
  ConfidenceLevel.estimacion => Icons.circle_outlined,
};

/// SPEC-023 R1/AC5: un solo tono del sistema visual (sin rojo ni verde de
/// alarma), con contraste ≥ 3:1 contra el blanco.
const confidenceIndicatorColor = KColors.accent;

/// SPEC-023 R5: "Confianza: buena estimación".
String confidenceSemanticLabel(ConfidenceLevel level) =>
    'Confianza: ${confidenceLevelLabels[level]!.toLowerCase()}';

/// El nivel guardado en `user.db` (`ConfidenceLevel.name`), o `null` si no
/// se reconoce.
ConfidenceLevel? confidenceFromName(String? name) =>
    name == null ? null : ConfidenceLevel.values.asNameMap()[name];

/// SPEC-023 R1/R5: indicador de confianza con ícono y texto. Con [onTap]
/// es un botón ("¿Por qué?", R3).
class ConfidenceIndicator extends StatelessWidget {
  final ConfidenceLevel level;
  final VoidCallback? onTap;

  /// Más pequeño, para ingredientes y tarjetas de comida.
  final bool compact;

  const ConfidenceIndicator({
    super.key,
    required this.level,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 12.0 : 15.0;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          confidenceIcon(level),
          size: size,
          color: confidenceIndicatorColor,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            confidenceLevelLabels[level]!,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              color: KColors.textSecondary,
            ),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.info_outline, size: size, color: KColors.textSecondary),
        ],
      ],
    );
    final tap = onTap;
    return Semantics(
      label: confidenceSemanticLabel(level),
      hint: tap == null ? null : '¿Por qué?',
      button: tap != null,
      excludeSemantics: true,
      onTap: tap,
      child: tap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: tap,
              // Área táctil de 48 dp (es la entrada a "¿Por qué?").
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: content,
                ),
              ),
            ),
    );
  }
}
