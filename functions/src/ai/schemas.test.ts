import assert from "node:assert/strict";
import { test } from "node:test";
import { parsedMealSchema, parseMealRequestSchema } from "./schemas.js";

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
