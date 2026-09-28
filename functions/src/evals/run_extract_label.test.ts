import assert from "node:assert/strict";
import { test } from "node:test";
import { numbersMatch, checkField } from "./run_extract_label.js";

test("numbersMatch: iguales dentro de tolerancia", () => {
  assert.equal(numbersMatch(140, 140), true);
  assert.equal(numbersMatch(140, 140.03), true);
  assert.equal(numbersMatch(140, 141), false);
});

test("numbersMatch: null vs null es igual, null vs número no", () => {
  assert.equal(numbersMatch(null, null), true);
  assert.equal(numbersMatch(null, 5), false);
  assert.equal(numbersMatch(5, null), false);
});

test("checkField: campo en human_unreadable_fields no se puntúa (scored=false)", () => {
  const result = checkField("per_serving.fat_g", null, 6, new Set(["per_serving.fat_g"]));
  assert.equal(result.scored, false);
});

test("checkField: esperado null (no impreso) + actual con valor -> alucinación", () => {
  const result = checkField("per_100.sugar_g", null, 12, new Set());
  assert.equal(result.scored, true);
  assert.equal(result.correct, false);
  assert.equal(result.hallucinated, true);
});

test("checkField: esperado null + actual null -> correcto, sin alucinación", () => {
  const result = checkField("per_100.sugar_g", null, null, new Set());
  assert.equal(result.correct, true);
  assert.equal(result.hallucinated, false);
});

test("checkField: valores numéricos iguales -> correcto", () => {
  const result = checkField("per_serving.energy_kcal", 140, 140, new Set());
  assert.equal(result.correct, true);
});

test("checkField: un marcador de grupo entero ('per_100') excluye todos sus campos", () => {
  const unreadable = new Set(["per_100"]);
  const result = checkField("per_100.energy_kcal", 350, null, unreadable);
  assert.equal(result.scored, false);
});

test("checkField: marcador específico ('per_serving.fat_g') no afecta otros campos del mismo grupo", () => {
  const unreadable = new Set(["per_serving.fat_g"]);
  assert.equal(checkField("per_serving.fat_g", 6, null, unreadable).scored, false);
  assert.equal(checkField("per_serving.protein_g", 2, 2, unreadable).scored, true);
});

test("checkField: product_name (string) comparado por igualdad exacta", () => {
  const correct = checkField("product_name", "Castellano", "Castellano", new Set());
  assert.equal(correct.correct, true);
  const wrong = checkField("product_name", "Castellano", "Otro", new Set());
  assert.equal(wrong.correct, false);
});
