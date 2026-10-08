/// SPEC-042: conversiones entre g/ml, porciones y valores "por 100 g/ml".
/// Sin redondeo (invariante 3: se redondea solo al presentar).
library;

/// Cuántas porciones son [amount] g/ml con porciones de [portionAmount];
/// `null` si la porción no es positiva.
double? portionsForAmount(double amount, double portionAmount) =>
    portionAmount > 0 ? amount / portionAmount : null;

/// g/ml de [portions] porciones de [portionAmount]; `null` si la porción no
/// es positiva.
double? amountForPortions(double portions, double portionAmount) =>
    portionAmount > 0 ? portions * portionAmount : null;

/// Valor por 100 g/ml a partir de [value] medido en [amount] g/ml; `null`
/// si la cantidad no es positiva.
double? per100FromAmount(double value, double amount) =>
    amount > 0 ? value * (100 / amount) : null;

/// Valor para [amount] g/ml a partir de [valuePer100] (por 100 g/ml);
/// `null` si la cantidad no es positiva.
double? amountFromPer100(double valuePer100, double amount) =>
    amount > 0 ? valuePer100 * (amount / 100) : null;
