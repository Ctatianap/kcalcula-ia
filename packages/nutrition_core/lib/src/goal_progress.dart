import 'dart:math' as math;

/// SPEC-008 R6: progreso de un nutriente del día frente a su meta, sin
/// redondear. Solo se redondea al presentar (`presentKcal`/`presentMacro`).
class GoalProgress {
  final double consumed;
  final double goal;

  const GoalProgress({required this.consumed, required this.goal});

  /// Lo que falta para la meta; 0 si ya se alcanzó o se superó.
  double get remaining => math.max(goal - consumed, 0);

  /// Lo que supera la meta; 0 si no se ha superado.
  double get excess => math.max(consumed - goal, 0);

  /// Igual a la meta cuenta como "quedan 0", no como "por encima".
  bool get isOverGoal => consumed > goal;

  /// Fracción para la barra, entre 0 y 1 (llena si se supera la meta).
  double get fraction => goal <= 0 ? 0 : math.min(consumed / goal, 1);

  /// SPEC-013 R3: consumido / meta sin tope (1,16 = 116 %), sin redondear.
  /// 0 si no hay meta positiva. Se presenta con [presentPercent].
  double get ratio => goal <= 0 ? 0 : consumed / goal;
}

/// Porcentaje entero (half-up) de una razón: 0,9378 → 94.
int presentPercent(double ratio) => (ratio * 100).round();
