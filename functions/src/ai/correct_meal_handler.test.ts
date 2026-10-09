import assert from "node:assert/strict";
import { mock, test } from "node:test";
import type { CallableRequest } from "firebase-functions/v2/https";
import functionsLogger = require("firebase-functions/logger");
import { createFakeAiProvider } from "./fake.js";
import { AI_INVALID_OUTPUT_ERROR_CODE, buildCorrectMealHandler } from "./handler.js";
import { renderCorrectMealPrompt } from "./prompt.js";
import { parseJsonOrUndefined } from "./json.js";
import type { AiProvider, AiProviderResult } from "./provider.js";
import {
  correctMealRequestSchema,
  MEAL_CORRECTION_SCHEMA_VERSION,
  mealCorrectionSchema,
  type CorrectMealRequest,
} from "./schemas.js";

const draftItems: CorrectMealRequest["items"] = [
  { mention: "dos huevos", food_query: "huevo", quantity: 2, unit: "unidad", size: null },
  { mention: "una arepa", food_query: "arepa", quantity: 1, unit: "unidad", size: null },
];

function request(data: unknown): CallableRequest<unknown> {
  return { data } as CallableRequest<unknown>;
}

function mockProvider(responses: unknown[]): {
  provider: AiProvider;
  callCount: () => number;
} {
  let calls = 0;
  const provider: AiProvider = {
    async parseMeal(): Promise<AiProviderResult> {
      throw new Error("no usado en estos tests");
    },
    async extractLabel(): Promise<AiProviderResult> {
      throw new Error("no usado en estos tests");
    },
    async correctMeal(): Promise<AiProviderResult> {
      const raw = responses[calls] ?? responses[responses.length - 1];
      calls += 1;
      return { raw, modelId: "mock", latencyMs: 1, tokensInput: 5 };
    },
  };
  return { provider, callCount: () => calls };
}

const replaceArepa = {
  schema_version: MEAL_CORRECTION_SCHEMA_VERSION,
  operations: [
    {
      op: "replace",
      index: 1,
      item: {
        mention: "un pan integral",
        food_query: "pan integral",
        quantity: 1,
        unit: "unidad",
        size: null,
        preparation: null,
        is_vague: false,
        parent_index: null,
      },
      quantity: null,
      unit: null,
      size: null,
    },
  ],
};

test("SPEC-024 AC1 (backend): el fake convierte la corrección en un replace del ítem 1", async () => {
  const handler = buildCorrectMealHandler(createFakeAiProvider());
  const result = await handler(
    request({
      correction: "No era arepa, era pan integral",
      locale: "es-CO",
      items: draftItems,
    }),
  );
  assert.equal(result.operations.length, 1);
  assert.equal(result.operations[0].op, "replace");
  assert.equal(result.operations[0].index, 1);
  assert.equal(result.operations[0].item?.food_query, "pan integral");
});

test("SPEC-024 AC3: el esquema rechaza nutrientes, gramos o confianza en la salida", () => {
  for (const extra of [{ energy_kcal: 100 }, { grams: 50 }, { confidence: "alta" }]) {
    const withExtra = {
      ...replaceArepa,
      operations: [{ ...replaceArepa.operations[0], ...extra }],
    };
    assert.equal(mealCorrectionSchema.safeParse(withExtra).success, false);
    const itemExtra = {
      ...replaceArepa,
      operations: [
        {
          ...replaceArepa.operations[0],
          item: { ...replaceArepa.operations[0].item, ...extra },
        },
      ],
    };
    assert.equal(mealCorrectionSchema.safeParse(itemExtra).success, false);
  }
  assert.equal(
    mealCorrectionSchema.safeParse({ ...replaceArepa, kcal_total: 300 }).success,
    false,
  );
  assert.equal(mealCorrectionSchema.safeParse(replaceArepa).success, true);
});

test("SPEC-024 AC3: la petición tampoco acepta nutrientes, gramos ni confianza", () => {
  for (const extra of [{ energy_kcal: 100 }, { grams: 50 }, { confidence: "alta" }]) {
    const parsed = correctMealRequestSchema.safeParse({
      correction: "eran tres huevos",
      locale: "es-CO",
      items: [{ ...draftItems[0], ...extra }],
    });
    assert.equal(parsed.success, false);
  }
});

test("SPEC-024 R2: cada operación lleva los campos que le corresponden", () => {
  const bad = [
    { op: "replace", index: 0, item: null, quantity: null, unit: null, size: null },
    { op: "add", index: 0, item: replaceArepa.operations[0].item, quantity: null, unit: null, size: null },
    { op: "remove", index: null, item: null, quantity: null, unit: null, size: null },
    { op: "set_quantity", index: 0, item: null, quantity: null, unit: null, size: null },
  ];
  for (const op of bad) {
    assert.equal(
      mealCorrectionSchema.safeParse({
        schema_version: MEAL_CORRECTION_SCHEMA_VERSION,
        operations: [op],
      }).success,
      false,
      op.op,
    );
  }
});

test("SPEC-024 AC4/R5: un índice que no existe invalida todo, con un reintento", async () => {
  const outOfRange = {
    ...replaceArepa,
    operations: [{ ...replaceArepa.operations[0], index: 5 }],
  };
  const { provider, callCount } = mockProvider([outOfRange, outOfRange]);
  const infoMock = mock.method(functionsLogger, "info", () => {});
  try {
    await assert.rejects(
      buildCorrectMealHandler(provider)(
        request({ correction: "no era arepa", locale: "es-CO", items: draftItems }),
      ),
      (error: { code?: string; details?: { errorCode?: string } }) =>
        error.code === "invalid-argument" &&
        error.details?.errorCode === AI_INVALID_OUTPUT_ERROR_CODE,
    );
    assert.equal(callCount(), 2);
  } finally {
    infoMock.mock.restore();
  }
});

test("SPEC-024: si el reintento sale bien, se usa", async () => {
  const { provider, callCount } = mockProvider([{ bad: true }, replaceArepa]);
  const infoMock = mock.method(functionsLogger, "info", () => {});
  try {
    const result = await buildCorrectMealHandler(provider)(
      request({ correction: "no era arepa", locale: "es-CO", items: draftItems }),
    );
    assert.equal(result.operations[0].index, 1);
    assert.equal(callCount(), 2);
  } finally {
    infoMock.mock.restore();
  }
});

test("SPEC-024 AC8: vacía o de más de 300 caracteres → invalid-argument", async () => {
  const { provider, callCount } = mockProvider([replaceArepa]);
  const infoMock = mock.method(functionsLogger, "info", () => {});
  try {
    for (const correction of ["", "   ", "a".repeat(301)]) {
      await assert.rejects(
        buildCorrectMealHandler(provider)(
          request({ correction, locale: "es-CO", items: draftItems }),
        ),
        (error: { code?: string }) => error.code === "invalid-argument",
      );
    }
    assert.equal(callCount(), 0);
  } finally {
    infoMock.mock.restore();
  }
});

test("SPEC-024 AC7: el log solo lleva metadatos, nunca la corrección ni los ítems", async () => {
  const secret = "SECRETO-91 arepa de chócolo";
  const { provider } = mockProvider([replaceArepa]);
  const infoMock = mock.method(functionsLogger, "info", () => {});
  try {
    await buildCorrectMealHandler(provider)(
      request({
        correction: secret,
        locale: "es-CO",
        items: [{ ...draftItems[0], mention: secret }, draftItems[1]],
      }),
    );
    assert.equal(infoMock.mock.callCount(), 1);
    const [message, entry] = infoMock.mock.calls[0].arguments as [string, Record<string, unknown>];
    assert.equal(message, "correctMeal");
    assert.deepEqual(Object.keys(entry).sort(), [
      "errorCode",
      "latencyMs",
      "modelId",
      "operationCount",
      "promptVersion",
      "requestId",
      "tokensInput",
      "tokensOutput",
      "tokensThinking",
      "valid",
    ]);
    assert.equal(entry.operationCount, 1);
    assert.ok(!JSON.stringify(infoMock.mock.calls).includes("SECRETO-91"));
  } finally {
    infoMock.mock.restore();
  }
});

test("SPEC-024 R2: el prompt lleva los ítems con su índice y la corrección, sin nutrientes", () => {
  const prompt = renderCorrectMealPrompt({
    correction: "no era arepa, era pan integral",
    locale: "es-CO",
    items: draftItems,
  });
  assert.ok(prompt.includes('"index": 1'));
  assert.ok(prompt.includes('"food_query": "arepa"'));
  assert.ok(prompt.includes("no era arepa, era pan integral"));
  assert.ok(!prompt.includes("{{"));
});

test("SPEC-024: texto del usuario con $& o {{CORRECCION}} no deforma el prompt", () => {
  const prompt = renderCorrectMealPrompt({
    correction: "eran $& huevos {{ITEMS}}",
    locale: "es-CO",
    items: [{ ...draftItems[0], mention: "huevos {{CORRECCION}} $'" }],
  });
  assert.ok(prompt.includes("eran $& huevos {{ITEMS}}"));
  assert.ok(prompt.includes("huevos {{CORRECCION}} $'"));
  assert.ok(!prompt.includes("{{LOCALE}}"));
});

test("SPEC-024: JSON mal formado del modelo cuenta como salida inválida", () => {
  assert.equal(parseJsonOrUndefined("{no es json"), undefined);
  assert.equal(parseJsonOrUndefined(undefined), undefined);
  assert.deepEqual(parseJsonOrUndefined('{"a":1}'), { a: 1 });
});
