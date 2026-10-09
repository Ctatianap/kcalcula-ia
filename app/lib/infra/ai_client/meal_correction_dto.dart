import 'parsed_meal_dto.dart';

/// SPEC-024: una operación de `meal_correction.v1` sobre el borrador. Sin
/// valores nutricionales (invariante 1): solo qué cambiar.
class CorrectionOperationDto {
  /// "replace" | "add" | "remove" | "set_quantity".
  final String op;
  final int? index;
  final ParsedMealItemDto? item;
  final double? quantity;
  final String? unit;
  final String? size;

  const CorrectionOperationDto({
    required this.op,
    this.index,
    this.item,
    this.quantity,
    this.unit,
    this.size,
  });

  factory CorrectionOperationDto.fromJson(Map<String, dynamic> json) =>
      CorrectionOperationDto(
        op: json['op'] as String,
        index: json['index'] as int?,
        item: json['item'] == null
            ? null
            : ParsedMealItemDto.fromJson(
                Map<String, dynamic>.from(json['item'] as Map),
              ),
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        size: json['size'] as String?,
      );
}

/// SPEC-024: respuesta de `correctMeal`.
class MealCorrectionDto {
  final List<CorrectionOperationDto> operations;

  const MealCorrectionDto(this.operations);

  factory MealCorrectionDto.fromJson(Map<String, dynamic> json) =>
      MealCorrectionDto([
        for (final op in json['operations'] as List)
          CorrectionOperationDto.fromJson(Map<String, dynamic>.from(op as Map)),
      ]);
}

/// SPEC-024 R2: lo que se envía de cada ítem del borrador. Solo lo dicho y
/// cómo se estructuró: **sin** nutrientes, gramos calculados ni confianza.
class CorrectionDraftItem {
  final String mention;
  final String foodQuery;
  final double? quantity;
  final String? unit;
  final String? size;

  const CorrectionDraftItem({
    required this.mention,
    required this.foodQuery,
    this.quantity,
    this.unit,
    this.size,
  });

  Map<String, dynamic> toJson() => {
    'mention': mention,
    'food_query': foodQuery,
    'quantity': quantity,
    'unit': unit,
    'size': size,
  };
}
