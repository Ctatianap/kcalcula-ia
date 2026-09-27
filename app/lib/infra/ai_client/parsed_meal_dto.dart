/// Representación en la app de `parsed_meal.v1` (ver
/// `functions/src/ai/schemas.ts`). Sin campos de nutrientes: la IA solo
/// estructura (invariante 1).
class ParsedMealItemDto {
  final String mention;
  final String foodQuery;
  final double? quantity;
  final String? unit;
  final String? size;
  final String? preparation;
  final bool isVague;
  final int? parentIndex;

  const ParsedMealItemDto({
    required this.mention,
    required this.foodQuery,
    required this.isVague,
    this.quantity,
    this.unit,
    this.size,
    this.preparation,
    this.parentIndex,
  });

  factory ParsedMealItemDto.fromJson(Map<String, dynamic> json) =>
      ParsedMealItemDto(
        mention: json['mention'] as String,
        foodQuery: json['food_query'] as String,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        size: json['size'] as String?,
        preparation: json['preparation'] as String?,
        isVague: json['is_vague'] as bool,
        parentIndex: json['parent_index'] as int?,
      );
}

class ParsedMealDto {
  final String? mealType;
  final List<ParsedMealItemDto> items;

  const ParsedMealDto({required this.mealType, required this.items});

  factory ParsedMealDto.fromJson(Map<String, dynamic> json) => ParsedMealDto(
    mealType: json['meal_type'] as String?,
    items: (json['items'] as List<dynamic>)
        .map((item) => ParsedMealItemDto.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
