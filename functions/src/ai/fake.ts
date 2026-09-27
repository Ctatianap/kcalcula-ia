import type { AiProvider, AiProviderResult } from "./provider.js";
import {
  PARSED_MEAL_SCHEMA_VERSION,
  type ParsedMeal,
  type ParsedMealItem,
} from "./schemas.js";

function item(
  overrides: Pick<ParsedMealItem, "mention" | "food_query"> &
    Partial<ParsedMealItem>,
): ParsedMealItem {
  return {
    quantity: null,
    unit: null,
    size: null,
    preparation: null,
    is_vague: false,
    parent_index: null,
    ...overrides,
  };
}

function meal(
  items: ParsedMealItem[],
  mealType: ParsedMeal["meal_type"] = null,
): ParsedMeal {
  return {
    schema_version: PARSED_MEAL_SCHEMA_VERSION,
    meal_type: mealType,
    items,
  };
}

/**
 * Fixtures deterministas: cubren AC1 y las 10 frases de
 * `evals/datasets/slice_smoke.jsonl`. La clave es el texto normalizado
 * (recortado y en minúsculas). Un texto sin fixture nunca se inventa:
 * devuelve `items: []` (ver `s10` — "hola, ¿cómo estás?").
 */
const FIXTURES: Record<string, () => ParsedMeal> = {
  // AC1 (literal de la SPEC-001, distinto de s01 del smoke test).
  "dos huevos y una arepa": () =>
    meal([
      item({ mention: "dos huevos", food_query: "huevo", quantity: 2, unit: "unidad" }),
      item({ mention: "una arepa", food_query: "arepa", quantity: 1, unit: "unidad" }),
    ]),

  // s01
  "dos huevos revueltos y una arepa pequeña con queso": () =>
    meal([
      item({
        mention: "dos huevos revueltos",
        food_query: "huevo",
        quantity: 2,
        unit: "unidad",
        preparation: "revueltos",
      }),
      item({
        mention: "una arepa pequeña",
        food_query: "arepa",
        quantity: 1,
        size: "pequeno",
      }),
      item({
        mention: "con queso",
        food_query: "queso",
        is_vague: true,
        parent_index: 1,
      }),
    ]),

  // s02
  "150 gramos de pechuga de pollo a la plancha": () =>
    meal([
      item({
        mention: "150 gramos de pechuga de pollo a la plancha",
        food_query: "pechuga de pollo",
        quantity: 150,
        unit: "g",
        preparation: "a la plancha",
      }),
    ]),

  // s03
  "un café con leche": () =>
    meal([
      item({
        mention: "un café con leche",
        food_query: "café con leche",
        is_vague: true,
      }),
    ]),

  // s04
  "media taza de arroz blanco y un plátano maduro frito": () =>
    meal([
      item({
        mention: "media taza de arroz blanco",
        food_query: "arroz blanco",
        quantity: 0.5,
        unit: "taza",
      }),
      item({
        mention: "un plátano maduro frito",
        food_query: "plátano maduro",
        quantity: 1,
        unit: "unidad",
        preparation: "frito",
      }),
    ]),

  // s05
  "almorcé 180 g de arroz, medio aguacate y ensalada con una cucharada de aceite de oliva": () =>
    meal([
      item({
        mention: "180 g de arroz",
        food_query: "arroz",
        quantity: 180,
        unit: "g",
      }),
      item({
        mention: "medio aguacate",
        food_query: "aguacate",
        quantity: 0.5,
        unit: "unidad",
      }),
      item({ mention: "ensalada", food_query: "ensalada", is_vague: true }),
      item({
        mention: "una cucharada de aceite de oliva",
        food_query: "aceite de oliva",
        quantity: 1,
        unit: "cucharada",
        parent_index: 2,
      }),
    ]),

  // s06 (literal de AC5: "un poquito de queso").
  "me comí un poquito de queso": () =>
    meal([
      item({
        mention: "un poquito de queso",
        food_query: "queso",
        is_vague: true,
      }),
    ]),

  // s07
  "una manzana": () =>
    meal([
      item({
        mention: "una manzana",
        food_query: "manzana",
        quantity: 1,
        unit: "unidad",
      }),
    ]),

  // s08
  "dos tajadas de pan integral con mantequilla de maní": () =>
    meal([
      item({
        mention: "dos tajadas de pan integral",
        food_query: "pan integral",
        quantity: 2,
        unit: "unidad",
      }),
      item({
        mention: "con mantequilla de maní",
        food_query: "mantequilla de maní",
        is_vague: true,
        parent_index: 0,
      }),
    ]),

  // s09
  "un vaso de jugo de naranja": () =>
    meal([
      item({
        mention: "un vaso de jugo de naranja",
        food_query: "jugo de naranja",
        quantity: 1,
        unit: "vaso",
      }),
    ]),

  // s10 ("hola, ¿cómo estás?") no tiene fixture a propósito: cae en el
  // fallback de abajo, que nunca inventa alimentos.
};

function normalize(text: string): string {
  return text.trim().toLowerCase();
}

export function createFakeAiProvider(): AiProvider {
  return {
    async parseMeal({ text }): Promise<AiProviderResult> {
      const start = Date.now();
      const build = FIXTURES[normalize(text)];
      const raw: ParsedMeal = build ? build() : meal([]);
      return {
        raw,
        modelId: "fake",
        latencyMs: Date.now() - start,
      };
    },
  };
}
