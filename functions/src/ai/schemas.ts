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
export const LABEL_EXTRACTION_SCHEMA_VERSION = "label_extraction.v1" as const;

/**
 * Esquema de entrada del callable `extractLabel`. R10 (SPEC-004): el
 * cliente ya redimensiona/comprime la imagen (~1600 px, JPEG ~85 %) antes de
 * enviarla; este límite de `image_base64` es una defensa adicional en el
 * backend, no el mecanismo principal de control de tamaño.
 */
export const extractLabelRequestSchema = z.strictObject({
  image_base64: z.string().min(1).max(3_000_000),
  mime_type: z.enum(["image/jpeg", "image/png"]),
});

export type ExtractLabelRequest = z.infer<typeof extractLabelRequestSchema>;

/** Nombres de campo que la IA puede listar en `unreadable_fields`. */
const LABEL_FIELD_NAMES = [
  "product_name",
  "serving_size",
  "energy_kcal",
  "protein_g",
  "carbs_g",
  "fat_g",
  "fiber_g",
  "sugar_g",
  "sodium_mg",
] as const;

const labelNutrientSetSchema = z.strictObject({
  energy_kcal: z.number().nonnegative().nullable(),
  protein_g: z.number().nonnegative().nullable(),
  carbs_g: z.number().nonnegative().nullable(),
  fat_g: z.number().nonnegative().nullable(),
  fiber_g: z.number().nonnegative().nullable(),
  sugar_g: z.number().nonnegative().nullable(),
  sodium_mg: z.number().nonnegative().nullable(),
});

export type LabelNutrientSet = z.infer<typeof labelNutrientSetSchema>;

const labelServingSizeSchema = z.strictObject({
  quantity: z.number().positive(),
  unit: z.enum(["g", "ml"]),
});

/**
 * `label_extraction.v1`: la IA solo transcribe lo impreso en la etiqueta
 * (invariante 1 y 2 de CLAUDE.md) — nunca calcula, nunca completa un campo
 * que no pudo leer. Lo que no se pudo leer va en `unreadable_fields`, con
 * su valor en `null`; un campo que simplemente no está impreso (por
 * ejemplo, muchas etiquetas no traen `fiber_g`) también queda en `null`
 * pero NO se lista en `unreadable_fields` (distinción para la UI: uno
 * sugiere pedirle al usuario que lo complete porque probablemente exista,
 * el otro no).
 */
export const labelExtractionSchema = z.strictObject({
  schema_version: z.literal(LABEL_EXTRACTION_SCHEMA_VERSION),
  product_name: z.string().nullable(),
  serving_size: labelServingSizeSchema.nullable(),
  per_serving: labelNutrientSetSchema.nullable(),
  per_100: labelNutrientSetSchema.nullable(),
  unreadable_fields: z.array(z.enum(LABEL_FIELD_NAMES)),
});

export type LabelExtraction = z.infer<typeof labelExtractionSchema>;

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

const LABEL_NUTRIENT_SET_JSON_SCHEMA = {
  type: "object",
  properties: {
    energy_kcal: { anyOf: [{ type: "number" }, nullType] },
    protein_g: { anyOf: [{ type: "number" }, nullType] },
    carbs_g: { anyOf: [{ type: "number" }, nullType] },
    fat_g: { anyOf: [{ type: "number" }, nullType] },
    fiber_g: { anyOf: [{ type: "number" }, nullType] },
    sugar_g: { anyOf: [{ type: "number" }, nullType] },
    sodium_mg: { anyOf: [{ type: "number" }, nullType] },
  },
  additionalProperties: false,
  required: [
    "energy_kcal",
    "protein_g",
    "carbs_g",
    "fat_g",
    "fiber_g",
    "sugar_g",
    "sodium_mg",
  ],
} as const;

/** Espejo de `labelExtractionSchema` para `responseJsonSchema` (ver nota de `PARSED_MEAL_RESPONSE_SCHEMA`). */
export const LABEL_EXTRACTION_RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    schema_version: {
      type: "string",
      enum: [LABEL_EXTRACTION_SCHEMA_VERSION],
    },
    product_name: { anyOf: [{ type: "string" }, nullType] },
    serving_size: {
      anyOf: [
        {
          type: "object",
          properties: {
            quantity: { type: "number" },
            unit: { type: "string", enum: ["g", "ml"] },
          },
          additionalProperties: false,
          required: ["quantity", "unit"],
        },
        nullType,
      ],
    },
    per_serving: { anyOf: [LABEL_NUTRIENT_SET_JSON_SCHEMA, nullType] },
    per_100: { anyOf: [LABEL_NUTRIENT_SET_JSON_SCHEMA, nullType] },
    unreadable_fields: {
      type: "array",
      items: { type: "string", enum: [...LABEL_FIELD_NAMES] },
    },
  },
  additionalProperties: false,
  required: [
    "schema_version",
    "product_name",
    "serving_size",
    "per_serving",
    "per_100",
    "unreadable_fields",
  ],
} as const;
