/// Kcal enteras, redondeo half-up. `double.round()` de Dart ya redondea
/// los .5 positivos hacia arriba, que es lo que pide `docs/architecture.md`.
int presentKcal(double kcal) => kcal.round();

/// Macros con 1 decimal, mismo redondeo half-up.
double presentMacro(double grams) => (grams * 10).round() / 10;
