import { z } from "zod";

export const PARSED_MEAL_SCHEMA_VERSION = "parsed_meal.v1" as const;

/**
 * Esquema de entrada del callable `parseMeal`. R1: 1-500 caracteres.
 */
export const parseMealRequestSchema = z.strictObject({
  text: z.string().min(1).max(500),
  locale: z.literal("es-CO"),
});

export type ParseMealRequest = z.infer<typeof parseMealRequestSchema>;

const parsedMealItemSchema = z.strictObject({
  mention: z.string().min(1),
  food_query: z.string().min(1),
  quantity: z.number().positive().nullable(),
  unit: z
    .enum([
      "g",
      "ml",
      "unidad",
      "cucharada",
      "cucharadita",
      "taza",
      "vaso",
      "porcion",
    ])
    .nullable(),
  size: z.enum(["pequeno", "mediano", "grande"]).nullable(),
  preparation: z.string().nullable(),
  is_vague: z.boolean(),
  parent_index: z.number().int().nonnegative().nullable(),
});

/**
 * `parsed_meal.v1`: la IA solo estructura, nunca calcula (invariante 1).
 * Sin campos de calorías ni nutrientes; `additionalProperties: false` en
 * todos los niveles vía `z.strictObject`.
 */
export const parsedMealSchema = z.strictObject({
  schema_version: z.literal(PARSED_MEAL_SCHEMA_VERSION),
  meal_type: z.enum(["desayuno", "almuerzo", "cena", "snack"]).nullable(),
  items: z.array(parsedMealItemSchema),
});

export type ParsedMealItem = z.infer<typeof parsedMealItemSchema>;
export type ParsedMeal = z.infer<typeof parsedMealSchema>;

const nullType = { type: "null" } as const;

/**
 * JSON Schema estándar para `responseJsonSchema` de `@google/genai`.
 * Es solo una guía estructural para el modelo: la única puerta autoritativa
 * es `parsedMealSchema.safeParse` (regla 5 de `ai-pipeline`). `responseJsonSchema`
 * no soporta la palabra clave OpenAPI `nullable`: los campos opcionales se
 * expresan con `anyOf` + `{type: "null"}`.
 */
export const PARSED_MEAL_RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    schema_version: { type: "string", enum: [PARSED_MEAL_SCHEMA_VERSION] },
    meal_type: {
      anyOf: [
        { type: "string", enum: ["desayuno", "almuerzo", "cena", "snack"] },
        nullType,
      ],
    },
    items: {
      type: "array",
      items: {
        type: "object",
        properties: {
          mention: { type: "string" },
          food_query: { type: "string" },
          quantity: { anyOf: [{ type: "number" }, nullType] },
          unit: {
            anyOf: [
              {
                type: "string",
                enum: [
                  "g",
                  "ml",
                  "unidad",
                  "cucharada",
                  "cucharadita",
                  "taza",
                  "vaso",
                  "porcion",
                ],
              },
              nullType,
            ],
          },
          size: {
            anyOf: [
              { type: "string", enum: ["pequeno", "mediano", "grande"] },
              nullType,
            ],
          },
          preparation: { anyOf: [{ type: "string" }, nullType] },
          is_vague: { type: "boolean" },
          parent_index: { anyOf: [{ type: "integer" }, nullType] },
        },
        additionalProperties: false,
        required: [
          "mention",
          "food_query",
          "quantity",
          "unit",
          "size",
          "preparation",
          "is_vague",
          "parent_index",
        ],
      },
    },
  },
  additionalProperties: false,
  required: ["schema_version", "meal_type", "items"],
} as const;
