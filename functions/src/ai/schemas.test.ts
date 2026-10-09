import assert from "node:assert/strict";
import { test } from "node:test";
import {
  extractLabelRequestSchema,
  labelExtractionSchema,
  parsedMealSchema,
  parseMealRequestSchema,
} from "./schemas.js";

test("parsedMealSchema acepta un ítem válido", () => {
  const result = parsedMealSchema.safeParse({
    schema_version: "parsed_meal.v1",
    meal_type: null,
    items: [
      {
        mention: "dos huevos",
        food_query: "huevo",
        quantity: 2,
        unit: "unidad",
        size: null,
        preparation: null,
        is_vague: false,
        parent_index: null,
      },
    ],
  });
  assert.equal(result.success, true);
});

test("rechaza un campo extra de nutrientes (invariante 1)", () => {
  const result = parsedMealSchema.safeParse({
    schema_version: "parsed_meal.v1",
    meal_type: null,
    items: [
      {
        mention: "arroz",
        food_query: "arroz",
        quantity: null,
        unit: null,
        size: null,
        preparation: null,
        is_vague: true,
        parent_index: null,
        kcal: 150,
      },
    ],
  });
  assert.equal(result.success, false);
});

test("rechaza un valor de unit fuera del enum", () => {
  const result = parsedMealSchema.safeParse({
    schema_version: "parsed_meal.v1",
    meal_type: null,
    items: [
      {
        mention: "arroz",
        food_query: "arroz",
        quantity: 1,
        unit: "bolsa",
        size: null,
        preparation: null,
        is_vague: false,
        parent_index: null,
      },
    ],
  });
  assert.equal(result.success, false);
});

test("rechaza schema_version distinto de parsed_meal.v1", () => {
  const result = parsedMealSchema.safeParse({
    schema_version: "parsed_meal.v2",
    meal_type: null,
    items: [],
  });
  assert.equal(result.success, false);
});

const validLabelExtraction = {
  schema_version: "label_extraction.v1",
  product_name: "Producto de prueba",
  serving_size: { quantity: 30, unit: "g" },
  per_serving: {
    energy_kcal: 140,
    protein_g: 2,
    carbs_g: 20,
    fat_g: 6,
    fiber_g: 1,
    sugar_g: 15,
    sodium_mg: 50,
  },
  per_100: null,
  unreadable_fields: [],
};

test("labelExtractionSchema acepta una etiqueta válida (AC9)", () => {
  const result = labelExtractionSchema.safeParse(validLabelExtraction);
  assert.equal(result.success, true);
});

test("labelExtractionSchema acepta unreadable_fields con nombres válidos", () => {
  const result = labelExtractionSchema.safeParse({
    ...validLabelExtraction,
    per_serving: { ...validLabelExtraction.per_serving, fat_g: null },
    unreadable_fields: ["fat_g"],
  });
  assert.equal(result.success, true);
});

test("labelExtractionSchema rechaza un campo de confianza extra (invariante 4)", () => {
  const result = labelExtractionSchema.safeParse({
    ...validLabelExtraction,
    confidence: "alta",
  });
  assert.equal(result.success, false);
});

test("labelExtractionSchema rechaza un nombre fuera del enum en unreadable_fields", () => {
  const result = labelExtractionSchema.safeParse({
    ...validLabelExtraction,
    unreadable_fields: ["marca"],
  });
  assert.equal(result.success, false);
});

test("labelExtractionSchema rechaza schema_version distinto de label_extraction.v1", () => {
  const result = labelExtractionSchema.safeParse({
    ...validLabelExtraction,
    schema_version: "label_extraction.v2",
  });
  assert.equal(result.success, false);
});

test("labelExtractionSchema rechaza serving_size con unit fuera de g/ml", () => {
  const result = labelExtractionSchema.safeParse({
    ...validLabelExtraction,
    serving_size: { quantity: 30, unit: "oz" },
  });
  assert.equal(result.success, false);
});

test("extractLabelRequestSchema exige image_base64 no vacío y mime_type válido", () => {
  assert.equal(
    extractLabelRequestSchema.safeParse({ image_base64: "", mime_type: "image/jpeg" })
      .success,
    false,
  );
  assert.equal(
    extractLabelRequestSchema.safeParse({ image_base64: "abc", mime_type: "image/bmp" })
      .success,
    false,
  );
  assert.equal(
    extractLabelRequestSchema.safeParse({ image_base64: "abc", mime_type: "image/jpeg" })
      .success,
    true,
  );
});

test("parseMealRequestSchema exige texto de 1 a 500 caracteres", () => {
  assert.equal(
    parseMealRequestSchema.safeParse({ text: "", locale: "es-CO" }).success,
    false,
  );
  assert.equal(
    parseMealRequestSchema.safeParse({
      text: "a".repeat(501),
      locale: "es-CO",
    }).success,
    false,
  );
  assert.equal(
    parseMealRequestSchema.safeParse({ text: "una manzana", locale: "es-CO" })
      .success,
    true,
  );
});
