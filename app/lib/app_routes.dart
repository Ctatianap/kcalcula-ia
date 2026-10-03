/// Nombres de ruta compartidos. Vive fuera de `features/` a propósito: las
/// features nunca se importan entre sí, así que navegan por nombre y quien
/// las conecta es `app.dart` (la raíz de composición), no cada feature.
abstract class AppRoutes {
  static const diary = '/';
  static const capture = '/capture';
  static const review = '/review';
  static const labelConfirmation = '/label-confirmation';
  static const onboarding = '/onboarding';
  static const settings = '/settings';
  static const privacyPolicy = '/privacy-policy';
  static const profile = '/profile';
  static const objective = '/objective';
  static const history = '/history';
  static const progress = '/progress';
}
