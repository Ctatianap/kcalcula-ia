import assert from "node:assert/strict";
import { mock, test } from "node:test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import functionsLogger = require("firebase-functions/logger");
import {
  AI_INVALID_OUTPUT_ERROR_CODE,
  buildExtractLabelHandler,
} from "./handler.js";
import type { AiProvider, AiProviderResult } from "./provider.js";
import { LABEL_EXTRACTION_SCHEMA_VERSION } from "./schemas.js";

function fakeRequest(data: unknown): CallableRequest<unknown> {
  return { data } as CallableRequest<unknown>;
}

function countingProvider(
  responses: unknown[],
): { provider: AiProvider; callCount: () => number } {
  let calls = 0;
  const provider: AiProvider = {
    // SPEC-024: no usado en estos tests.
    async correctMeal(): Promise<AiProviderResult> {
      throw new Error("no usado en estos tests");
    },
    async parseMeal(): Promise<AiProviderResult> {
      throw new Error("no usado en estos tests");
    },
    async extractLabel(): Promise<AiProviderResult> {
      const raw = responses[calls] ?? responses[responses.length - 1];
      calls += 1;
      return { raw, modelId: "mock", latencyMs: 1 };
    },
  };
  return { provider, callCount: () => calls };
}

const validLabel = {
  schema_version: LABEL_EXTRACTION_SCHEMA_VERSION,
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

const invalidLabel = {
  ...validLabel,
  confidence: "alta", // campo extra no permitido (invariante 4)
};

test("imagen vacía -> invalid-argument sin llamar al proveedor", async () => {
  const { provider, callCount } = countingProvider([validLabel]);
  const handler = buildExtractLabelHandler(provider);

  await assert.rejects(
    () => handler(fakeRequest({ image_base64: "", mime_type: "image/jpeg" })),
    (error: unknown) => error instanceof HttpsError && error.code === "invalid-argument",
  );
  assert.equal(callCount(), 0);
});

test("mime_type fuera del enum -> invalid-argument sin llamar al proveedor", async () => {
  const { provider, callCount } = countingProvider([validLabel]);
  const handler = buildExtractLabelHandler(provider);

  await assert.rejects(() =>
    handler(fakeRequest({ image_base64: "abc", mime_type: "image/gif" })),
  );
  assert.equal(callCount(), 0);
});

test("salida inválida dos veces -> 1 reintento y luego ai-invalid-output", async () => {
  const { provider, callCount } = countingProvider([invalidLabel, invalidLabel]);
  const handler = buildExtractLabelHandler(provider);

  await assert.rejects(
    () =>
      handler(fakeRequest({ image_base64: "abc", mime_type: "image/jpeg" })),
    (error: unknown) =>
      error instanceof HttpsError &&
      (error.details as { errorCode?: string } | undefined)?.errorCode ===
        AI_INVALID_OUTPUT_ERROR_CODE,
  );
  assert.equal(callCount(), 2);
});

test("inválida en el primer intento, válida en el reintento -> éxito", async () => {
  const { provider, callCount } = countingProvider([invalidLabel, validLabel]);
  const handler = buildExtractLabelHandler(provider);

  const result = await handler(
    fakeRequest({ image_base64: "abc", mime_type: "image/jpeg" }),
  );
  assert.deepEqual(result, validLabel);
  assert.equal(callCount(), 2);
});

test("los logs de extractLabel no contienen la imagen", async () => {
  const secretImage = "BASE64-SECRETO-a19f-contenido-de-la-foto";
  const infoMock = mock.method(functionsLogger, "info", () => {});

  try {
    const { provider } = countingProvider([invalidLabel, invalidLabel]);
    const handler = buildExtractLabelHandler(provider);
    await assert.rejects(() =>
      handler(
        fakeRequest({ image_base64: secretImage, mime_type: "image/jpeg" }),
      ),
    );

    assert.ok(infoMock.mock.callCount() > 0);
    for (const call of infoMock.mock.calls) {
      const serialized = JSON.stringify(call.arguments);
      assert.equal(serialized.includes(secretImage), false);
      assert.equal(serialized.includes("SECRETO-a19f"), false);
    }
  } finally {
    infoMock.mock.restore();
  }
});
