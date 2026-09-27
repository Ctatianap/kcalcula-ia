/// Nivel de confianza calculado por reglas (nunca reportado por la IA).
///
/// El orden de declaración es ascendente: [estimacion] es el nivel más bajo.
/// `mealConfidence` depende de comparar [index] entre niveles.
enum ConfidenceLevel { estimacion, buenaEstimacion, altaPrecision }
