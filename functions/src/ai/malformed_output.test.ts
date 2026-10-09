import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { mock, test } from "node:test";
import type { CallableRequest } from "firebase-functions/v2/https";
import functionsLogger = require("firebase-functions/logger");
import {
  AI_INVALID_OUTPUT_ERROR_CODE,
  buildExtractLabelHandler,
  buildParseMealHandler,
} from "./handler.js";
import { renderParseMealPrompt } from "./prompt.js";
import type { AiProvider, AiProviderResult } from "./provider.js";
import {
  LABEL_EXTRACTION_SCHEMA_VERSION,
  PARSED_MEAL_SCHEMA_VERSION,
} from "./schemas.js";

function request(data: unknown): CallableRequest<unknown> {
  return { data } as CallableRequest<unknown>;
}

/** Proveedor que devuelve [raws] en orden (como lo dejarían los adaptadores). */
function provider(raws: unknown[]): { provider: AiProvider; calls: () => number } {
  let calls = 0;
  const next = async (): Promise<AiProviderResult> => {
    const raw = raws[Math.min(calls, raws.length - 1)];
    calls += 1;
    return { raw, modelId: "mock", latencyMs: 1 };
  };
  return {
    provider: { parseMeal: next, extractLabel: next, correctMeal: next },
    calls: () => calls,
  };
}

const validMeal = { schema_version: PARSED_MEAL_SCHEMA_VERSION, meal_type: null, items: [] };
const validLabel = {
  schema_version: LABEL_EXTRACTION_SCHEMA_VERSION,
  product_name: null,
  serving_size: null,
  per_serving: null,
  per_100: null,
  unreadable_fields: [],
};

const isInvalidOutput = (error: { code?: string; details?: { errorCode?: string } }) =>
  error.code === "invalid-argument" && error.details?.errorCode === AI_INVALID_OUTPUT_ERROR_CODE;

test("SPEC-044 AC1: parseMeal con JSON mal formado (raw undefined) dos veces → ai-invalid-output", async () => {
  const p = provider([undefined, undefined]);
  const info = mock.method(functionsLogger, "info", () => {});
  try {
    await assert.rejects(
      buildParseMealHandler(p.provider)(request({ text: "dos huevos", locale: "es-CO" })),
      isInvalidOutput,
    );
    assert.equal(p.calls(), 2);
  } finally {
    info.mock.restore();
  }
});

test("SPEC-044 AC1: parseMeal reintenta y usa la salida válida", async () => {
  const p = provider([undefined, validMeal]);
  const info = mock.method(functionsLogger, "info", () => {});
  try {
    const result = await buildParseMealHandler(p.provider)(
      request({ text: "dos huevos", locale: "es-CO" }),
    );
    assert.deepEqual(result, validMeal);
    assert.equal(p.calls(), 2);
  } finally {
    info.mock.restore();
  }
});

test("SPEC-044 AC2: extractLabel con JSON mal formado dos veces → ai-invalid-output; luego válido → válido", async () => {
  const info = mock.method(functionsLogger, "info", () => {});
  try {
    const bad = provider([undefined, undefined]);
    await assert.rejects(
      buildExtractLabelHandler(bad.provider)(
        request({ image_base64: "aGVsbG8=", mime_type: "image/jpeg" }),
      ),
      isInvalidOutput,
    );
    assert.equal(bad.calls(), 2);

    const retry = provider([undefined, validLabel]);
    const result = await buildExtractLabelHandler(retry.provider)(
      request({ image_base64: "aGVsbG8=", mime_type: "image/jpeg" }),
    );
    assert.deepEqual(result, validLabel);
  } finally {
    info.mock.restore();
  }
});

test("SPEC-044 AC3: $& $' y {{LOCALE}} en el texto quedan literales", () => {
  const text = "dos huevos $& {{LOCALE}} $'";
  const prompt = renderParseMealPrompt({ text, locale: "es-CO" });
  assert.ok(prompt.includes(text));
  assert.ok(prompt.includes("(locale es-CO)"));
});

test("SPEC-044 AC4: para un texto normal, el prompt es idéntico a la sustitución anterior", () => {
  const template = readFileSync(join(__dirname, "prompts", "parse_meal.v1.md"), "utf-8");
  for (const text of [
    "dos huevos y una arepa",
    "150 gramos de pechuga de pollo a la plancha",
    "un café con leche, sin azúcar",
  ]) {
    const before = template.replace("{{LOCALE}}", "es-CO").replace("{{TEXTO_USUARIO}}", text);
    assert.equal(renderParseMealPrompt({ text, locale: "es-CO" }), before);
  }
});

test("SPEC-044 AC5: los adaptadores ya no llaman JSON.parse directamente", () => {
  for (const file of ["vertex.ts", "ollama.ts"]) {
    const source = readFileSync(join(__dirname, "..", "..", "src", "ai", file), "utf-8");
    assert.ok(!source.includes("JSON.parse("), file);
  }
});
