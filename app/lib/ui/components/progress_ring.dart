import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// SPEC-010 R3: anillo de progreso. Solo dibuja la fracción que recibe (ya
/// calculada en `nutrition_core`, p. ej. `GoalProgress.fraction`), limitada
/// entre 0 y 1; no calcula nada.
class ProgressRing extends StatelessWidget {
  final double fraction;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? center;
  final String? semanticsLabel;

  const ProgressRing({
    super.key,
    required this.fraction,
    this.size = 64,
    this.strokeWidth = 4,
    this.color = KColors.accent,
    this.trackColor = KColors.track,
    this.center,
    this.semanticsLabel,
  });

  /// Fracción que efectivamente se dibuja (AC4).
  double get clampedFraction =>
      fraction.isNaN ? 0 : fraction.clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    // Con etiqueta, el lector de pantalla lee solo la etiqueta (que ya dice
    // el valor), no el contenido central repetido.
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            fraction: clampedFraction,
            strokeWidth: strokeWidth,
            color: color,
            trackColor: trackColor,
          ),
          child: center == null ? null : Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.fraction,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(inset, 0, 2 * math.pi, false, track);
    if (fraction <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(inset, -math.pi / 2, 2 * math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
