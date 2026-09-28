import assert from "node:assert/strict";
import { mock, test } from "node:test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import functionsLogger = require("firebase-functions/logger");
import { AI_INVALID_OUTPUT_ERROR_CODE, buildParseMealHandler } from "./handler.js";
import type { AiProvider, AiProviderResult } from "./provider.js";
import { PARSED_MEAL_SCHEMA_VERSION } from "./schemas.js";

function fakeRequest(data: unknown): CallableRequest<unknown> {
  return { data } as CallableRequest<unknown>;
}

function countingProvider(
  responses: unknown[],
): { provider: AiProvider; callCount: () => number } {
  let calls = 0;
  const provider: AiProvider = {
    async parseMeal(): Promise<AiProviderResult> {
      const raw = responses[calls] ?? responses[responses.length - 1];
      calls += 1;
      return { raw, modelId: "mock", latencyMs: 1 };
    },
    async extractLabel(): Promise<AiProviderResult> {
      throw new Error("no usado en estos tests");
    },
  };
  return { provider, callCount: () => calls };
}

const validParsedMeal = {
  schema_version: PARSED_MEAL_SCHEMA_VERSION,
  meal_type: null,
  items: [],
};

const invalidParsedMeal = {
  schema_version: PARSED_MEAL_SCHEMA_VERSION,
  meal_type: null,
  items: [],
  kcal: 150, // campo extra no permitido
};

test("AC2: texto vacío -> invalid-argument sin llamar al proveedor", async () => {
  const { provider, callCount } = countingProvider([validParsedMeal]);
  const handler = buildParseMealHandler(provider);

  await assert.rejects(
    () => handler(fakeRequest({ text: "", locale: "es-CO" })),
    (error: unknown) => error instanceof HttpsError && error.code === "invalid-argument",
  );
  assert.equal(callCount(), 0);
});

test("AC2: texto > 500 caracteres -> invalid-argument sin llamar al proveedor", async () => {
  const { provider, callCount } = countingProvider([validParsedMeal]);
  const handler = buildParseMealHandler(provider);

  await assert.rejects(() =>
    handler(fakeRequest({ text: "a".repeat(501), locale: "es-CO" })),
  );
  assert.equal(callCount(), 0);
});

test("AC3: salida inválida dos veces -> 1 reintento y luego ai-invalid-output", async () => {
  const { provider, callCount } = countingProvider([
    invalidParsedMeal,
    invalidParsedMeal,
  ]);
  const handler = buildParseMealHandler(provider);

  await assert.rejects(
    () => handler(fakeRequest({ text: "dos huevos", locale: "es-CO" })),
    (error: unknown) =>
      error instanceof HttpsError &&
      (error.details as { errorCode?: string } | undefined)?.errorCode ===
        AI_INVALID_OUTPUT_ERROR_CODE,
  );
  assert.equal(callCount(), 2);
});

test("inválida en el primer intento, válida en el reintento -> éxito", async () => {
  const { provider, callCount } = countingProvider([
    invalidParsedMeal,
    validParsedMeal,
  ]);
  const handler = buildParseMealHandler(provider);

  const result = await handler(fakeRequest({ text: "arroz", locale: "es-CO" }));
  assert.deepEqual(result, validParsedMeal);
  assert.equal(callCount(), 2);
});

test("AC10: los logs de parseMeal no contienen el texto de entrada", async () => {
  const secretText = "SECRETO-a19f un plátano y dos huevos revueltos";
  const infoMock = mock.method(functionsLogger, "info", () => {});

  try {
    const { provider } = countingProvider([invalidParsedMeal, invalidParsedMeal]);
    const handler = buildParseMealHandler(provider);
    await assert.rejects(() =>
      handler(fakeRequest({ text: secretText, locale: "es-CO" })),
    );

    assert.ok(infoMock.mock.callCount() > 0);
    for (const call of infoMock.mock.calls) {
      const serialized = JSON.stringify(call.arguments);
      assert.equal(serialized.includes(secretText), false);
      assert.equal(serialized.includes("SECRETO-a19f"), false);
    }
  } finally {
    infoMock.mock.restore();
  }
});
