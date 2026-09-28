import assert from "node:assert/strict";
import { test } from "node:test";
import { normalize, matchItems, percentile } from "./run_parse_meal.js";

function item(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    mention: "x",
    food_query: "huevo",
    quantity: null,
    unit: null,
    size: null,
    preparation: null,
    is_vague: false,
    parent_index: null,
    ...overrides,
  };
}

test("normalize: minúsculas y sin tildes", () => {
  assert.equal(normalize("Café con Leche"), "cafe con leche");
  assert.equal(normalize("  Ñame  "), "name");
});

test("matchItems: detecta por nombre normalizado (contiene/es-contenido-en)", () => {
  const expected = [item({ food_query: "pechuga de pollo" })];
  const actual = [item({ food_query: "pollo" })];
  const { matchedCount } = matchItems(expected, actual);
  assert.equal(matchedCount, 1);
});

test("matchItems: cuenta cantidad/unidad correcta solo entre los emparejados", () => {
  const expected = [
    item({ food_query: "huevo", quantity: 2, unit: "unidad" }),
    item({ food_query: "arepa", quantity: 1, unit: "unidad" }),
  ];
  const actual = [
    item({ food_query: "huevo", quantity: 2, unit: "unidad" }),
    item({ food_query: "arepa", quantity: 3, unit: "unidad" }), // cantidad incorrecta
  ];
  const { matchedCount, quantityUnitCorrect } = matchItems(expected, actual);
  assert.equal(matchedCount, 2);
  assert.equal(quantityUnitCorrect, 1);
});

test("matchItems: un ítem esperado sin ninguna coincidencia no cuenta como match", () => {
  const expected = [item({ food_query: "queso" })];
  const actual = [item({ food_query: "arroz" })];
  const { matchedCount } = matchItems(expected, actual);
  assert.equal(matchedCount, 0);
});

test("matchItems: no reutiliza el mismo ítem devuelto para dos esperados", () => {
  const expected = [item({ food_query: "pollo" }), item({ food_query: "pollo" })];
  const actual = [item({ food_query: "pollo" })];
  const { matchedCount } = matchItems(expected, actual);
  assert.equal(matchedCount, 1);
});

test("percentile: p50/p95 sobre una lista ordenada", () => {
  const sorted = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
  assert.equal(percentile(sorted, 50), 60);
  assert.equal(percentile(sorted, 95), 100);
});

test("percentile: lista vacía da 0", () => {
  assert.equal(percentile([], 50), 0);
});
