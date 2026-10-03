import 'package:flutter/material.dart';

import '../theme.dart';

/// SPEC-010 R3: tarjeta del diseño (fondo blanco, radio grande, sombra suave).
class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = KRadii.card,
    this.color = KColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: kCardShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
