import assert from "node:assert/strict";
import { test } from "node:test";
import { createFakeAiProvider } from "./fake.js";
import { labelExtractionSchema, parsedMealSchema } from "./schemas.js";

test("AC1: 'dos huevos y una arepa' devuelve 2 ítems", async () => {
  const provider = createFakeAiProvider();
  const result = await provider.parseMeal({
    text: "dos huevos y una arepa",
    locale: "es-CO",
  });
  const parsed = parsedMealSchema.parse(result.raw);
  assert.equal(parsed.items.length, 2);
  assert.equal(parsed.items[0].food_query, "huevo");
  assert.equal(parsed.items[1].food_query, "arepa");
});

test("s10: texto sin comida devuelve items: [] (nunca inventa)", async () => {
  const provider = createFakeAiProvider();
  const result = await provider.parseMeal({
    text: "hola, ¿cómo estás?",
    locale: "es-CO",
  });
  const parsed = parsedMealSchema.parse(result.raw);
  assert.deepEqual(parsed.items, []);
});

test("texto desconocido también devuelve items: []", async () => {
  const provider = createFakeAiProvider();
  const result = await provider.parseMeal({
    text: "esto no está en ningún fixture",
    locale: "es-CO",
  });
  const parsed = parsedMealSchema.parse(result.raw);
  assert.deepEqual(parsed.items, []);
});

test("todas las respuestas del fake pasan el esquema (evita drift)", async () => {
  const provider = createFakeAiProvider();
  const smokeTexts = [
    "dos huevos revueltos y una arepa pequeña con queso",
    "150 gramos de pechuga de pollo a la plancha",
    "un café con leche",
    "media taza de arroz blanco y un plátano maduro frito",
    "almorcé 180 g de arroz, medio aguacate y ensalada con una cucharada de aceite de oliva",
    "me comí un poquito de queso",
    "una manzana",
    "dos tajadas de pan integral con mantequilla de maní",
    "un vaso de jugo de naranja",
    "hola, ¿cómo estás?",
  ];
  for (const text of smokeTexts) {
    const result = await provider.parseMeal({ text, locale: "es-CO" });
    const parsed = parsedMealSchema.safeParse(result.raw);
    assert.equal(parsed.success, true, `falló para: "${text}"`);
  }
});

test("AC2 SPEC-004: fixture '30g-140kcal' está dentro de ±20% Atwater", async () => {
  const provider = createFakeAiProvider();
  const result = await provider.extractLabel({
    image_base64: "fixture:etiqueta-30g-140kcal",
    mime_type: "image/jpeg",
  });
  const parsed = labelExtractionSchema.parse(result.raw);
  assert.equal(parsed.per_serving?.energy_kcal, 140);
  assert.deepEqual(parsed.unreadable_fields, []);
});

test("AC3 SPEC-004: fixture fuera de Atwater no se filtra ni se corrige (la IA no valida)", async () => {
  const provider = createFakeAiProvider();
  const result = await provider.extractLabel({
    image_base64: "fixture:etiqueta-fuera-de-atwater",
    mime_type: "image/jpeg",
  });
  const parsed = labelExtractionSchema.parse(result.raw);
  // El fake solo transcribe; la validación Atwater vive en nutrition_core,
  // no aquí — por eso el fixture "inconsistente" pasa el esquema igual.
  assert.equal(parsed.per_serving?.energy_kcal, 500);
  assert.equal(parsed.per_serving?.protein_g, 1);
});

test("AC4 SPEC-004: fixture con grasa ilegible marca fat_g en null y en unreadable_fields", async () => {
  const provider = createFakeAiProvider();
  const result = await provider.extractLabel({
    image_base64: "fixture:etiqueta-grasa-ilegible",
    mime_type: "image/jpeg",
  });
  const parsed = labelExtractionSchema.parse(result.raw);
  assert.equal(parsed.per_serving?.fat_g, null);
  assert.deepEqual(parsed.unreadable_fields, ["fat_g"]);
});

test("marcador de imagen desconocido nunca inventa: todo null y marcado ilegible", async () => {
  const provider = createFakeAiProvider();
  const result = await provider.extractLabel({
    image_base64: "esto-no-es-un-fixture-conocido",
    mime_type: "image/jpeg",
  });
  const parsed = labelExtractionSchema.parse(result.raw);
  assert.equal(parsed.product_name, null);
  assert.equal(parsed.per_serving, null);
  assert.ok(parsed.unreadable_fields.length > 0);
});

test("todas las fixtures de etiqueta pasan el esquema (evita drift)", async () => {
  const provider = createFakeAiProvider();
  const markers = [
    "fixture:etiqueta-30g-140kcal",
    "fixture:etiqueta-fuera-de-atwater",
    "fixture:etiqueta-grasa-ilegible",
    "fixture:etiqueta-ilegible",
  ];
  for (const marker of markers) {
    const result = await provider.extractLabel({
      image_base64: marker,
      mime_type: "image/jpeg",
    });
    const parsed = labelExtractionSchema.safeParse(result.raw);
    assert.equal(parsed.success, true, `falló para: "${marker}"`);
  }
});
