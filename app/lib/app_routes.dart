/// Nombres de ruta compartidos. Vive fuera de `features/` a propósito: las
/// features nunca se importan entre sí, así que navegan por nombre y quien
/// las conecta es `app.dart` (la raíz de composición), no cada feature.
abstract class AppRoutes {
  static const diary = '/';
  static const capture = '/capture';
  static const review = '/review';
  static const labelConfirmation = '/label-confirmation';
}
