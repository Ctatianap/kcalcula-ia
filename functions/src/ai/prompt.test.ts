import assert from "node:assert/strict";
import { test } from "node:test";
import { renderExtractLabelPrompt, renderParseMealPrompt } from "./prompt.js";

test("renderParseMealPrompt sustituye el locale y el texto del usuario", () => {
  const prompt = renderParseMealPrompt({ text: "dos huevos", locale: "es-CO" });
  assert.ok(prompt.includes("dos huevos"));
  assert.ok(prompt.includes("es-CO"));
  assert.ok(!prompt.includes("{{TEXTO_USUARIO}}"));
  assert.ok(!prompt.includes("{{LOCALE}}"));
});

test("instruye explícitamente no calcular nutrientes (invariante 1)", () => {
  const prompt = renderParseMealPrompt({ text: "una manzana", locale: "es-CO" });
  assert.ok(/nunca.*calcul|no.*calcul/i.test(prompt));
  assert.ok(prompt.includes("parsed_meal.v1"));
});

test("renderExtractLabelPrompt instruye solo transcribir, nunca calcular (SPEC-004)", () => {
  const prompt = renderExtractLabelPrompt();
  assert.ok(prompt.includes("label_extraction.v1"));
  assert.ok(/nunca.*calcul|no.*calcul/i.test(prompt));
  assert.ok(prompt.includes("unreadable_fields"));
});
