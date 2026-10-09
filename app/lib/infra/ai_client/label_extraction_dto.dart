/// Representación en la app de `label_extraction.v1` (ver
/// `functions/src/ai/schemas.ts`). Solo transcripción de lo impreso: sin
/// ningún campo de confianza ni de cantidad consumida (invariante 1/2, eso
/// lo decide el usuario y lo calcula `nutrition_core` después).
class LabelNutrientSetDto {
  final double? energyKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;

  const LabelNutrientSetDto({
    this.energyKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
  });

  factory LabelNutrientSetDto.fromJson(Map<String, dynamic> json) =>
      LabelNutrientSetDto(
        energyKcal: (json['energy_kcal'] as num?)?.toDouble(),
        proteinG: (json['protein_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble(),
        fiberG: (json['fiber_g'] as num?)?.toDouble(),
        sugarG: (json['sugar_g'] as num?)?.toDouble(),
        sodiumMg: (json['sodium_mg'] as num?)?.toDouble(),
      );

  LabelNutrientSetDto copyWith({
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    double? sugarG,
    double? sodiumMg,
  }) => LabelNutrientSetDto(
    energyKcal: energyKcal ?? this.energyKcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    fiberG: fiberG ?? this.fiberG,
    sugarG: sugarG ?? this.sugarG,
    sodiumMg: sodiumMg ?? this.sodiumMg,
  );
}

class LabelServingSizeDto {
  final double quantity;
  final String unit; // "g" | "ml"

  const LabelServingSizeDto({required this.quantity, required this.unit});

  factory LabelServingSizeDto.fromJson(Map<String, dynamic> json) =>
      LabelServingSizeDto(
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
      );
}

class LabelExtractionDto {
  final String? productName;
  final LabelServingSizeDto? servingSize;
  final LabelNutrientSetDto? perServing;
  final LabelNutrientSetDto? per100;
  final List<String> unreadableFields;

  const LabelExtractionDto({
    required this.unreadableFields,
    this.productName,
    this.servingSize,
    this.perServing,
    this.per100,
  });

  factory LabelExtractionDto.fromJson(Map<String, dynamic> json) =>
      LabelExtractionDto(
        productName: json['product_name'] as String?,
        servingSize: json['serving_size'] == null
            ? null
            : LabelServingSizeDto.fromJson(
                json['serving_size'] as Map<String, dynamic>,
              ),
        perServing: json['per_serving'] == null
            ? null
            : LabelNutrientSetDto.fromJson(
                json['per_serving'] as Map<String, dynamic>,
              ),
        per100: json['per_100'] == null
            ? null
            : LabelNutrientSetDto.fromJson(
                json['per_100'] as Map<String, dynamic>,
              ),
        unreadableFields: (json['unreadable_fields'] as List<dynamic>)
            .cast<String>(),
      );
}
