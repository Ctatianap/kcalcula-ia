import assert from "node:assert/strict";
import { test } from "node:test";
import { createFakeAiProvider } from "./fake.js";
import { parsedMealSchema } from "./schemas.js";

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
