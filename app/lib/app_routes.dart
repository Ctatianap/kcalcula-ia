/// Nombres de ruta compartidos. Vive fuera de `features/` a propósito: las
/// features nunca se importan entre sí, así que navegan por nombre y quien
/// las conecta es `app.dart` (la raíz de composición), no cada feature.
abstract class AppRoutes {
  static const diary = '/';
  static const capture = '/capture';
  static const review = '/review';

  /// SPEC-012: "Analizando" → detalle o error, para un texto (argumento).
  static const analysis = '/analysis';
  static const labelConfirmation = '/label-confirmation';

  /// SPEC-033: etiqueta de un ingrediente del Detalle. Argumento: el nombre
  /// del ingrediente (`String`). Devuelve un `IngredientLabelResult?`.
  static const ingredientLabel = '/ingredient-label';

  /// SPEC-026: editar una comida guardada. Argumento: su id (`int`).
  static const editMeal = '/edit-meal';

  /// SPEC-034: "Mis productos" (ver, renombrar, alias, borrar).
  static const myProducts = '/my-products';
  static const onboarding = '/onboarding';
  static const settings = '/settings';
  static const privacyPolicy = '/privacy-policy';
  static const profile = '/profile';
  static const objective = '/objective';

  /// SPEC-016: "Exportar mis datos" (CSV, PDF o JSON).
  static const export = '/export';

  /// SPEC-010: "Hoy" ya pasado el control de consentimiento (`/` lo hace
  /// al arrancar). Las pestañas y el regreso tras registrar usan esta ruta.
  static const today = '/today';
  static const history = '/history';
  static const progress = '/progress';
}
