import assert from "node:assert/strict";
import { mock, test } from "node:test";
import type { CallableRequest } from "firebase-functions/v2/https";
import functionsLogger = require("firebase-functions/logger");
import { buildParseMealHandler } from "./handler.js";
import type { AiProvider, AiProviderResult } from "./provider.js";
import { PARSED_MEAL_SCHEMA_VERSION } from "./schemas.js";
import { buildGenerationConfig, parseThinkingBudget, resolveThinkingBudget } from "./thinking.js";

test("SPEC-039 R1: parseThinkingBudget", () => {
  assert.deepEqual(parseThinkingBudget(undefined), { invalid: false });
  assert.deepEqual(parseThinkingBudget(""), { invalid: false });
  assert.deepEqual(parseThinkingBudget(" 0 "), { budget: 0, invalid: false });
  assert.deepEqual(parseThinkingBudget("-1"), { budget: -1, invalid: false });
  assert.deepEqual(parseThinkingBudget("512"), { budget: 512, invalid: false });
  assert.deepEqual(parseThinkingBudget("abc"), { invalid: true });
  assert.deepEqual(parseThinkingBudget("1.5"), { invalid: true });
});

test("SPEC-039 AC1: con presupuesto 0, la configuración incluye thinkingConfig", () => {
  const schema = { type: "object" };
  assert.deepEqual(buildGenerationConfig(schema, 0), {
    responseMimeType: "application/json",
    responseJsonSchema: schema,
    temperature: 0,
    thinkingConfig: { thinkingBudget: 0 },
  });
});

test("SPEC-039 AC1: sin presupuesto (o inválido), no se envía thinkingConfig", () => {
  const schema = { type: "object" };
  const none = buildGenerationConfig(schema, undefined);
  assert.equal("thinkingConfig" in none, false);
  const invalid = buildGenerationConfig(
    schema,
    parseThinkingBudget("abc").budget,
  );
  assert.equal("thinkingConfig" in invalid, false);
});

test("SPEC-039 AC2: el log de parseMeal registra tokensThinking y no el texto", async () => {
  const secret = "SECRETO-77 tres huevos";
  const infoMock = mock.method(functionsLogger, "info", () => {});
  try {
    const provider: AiProvider = {
      // SPEC-024: no usado en estos tests.
      async correctMeal(): Promise<AiProviderResult> {
        throw new Error("no usado en estos tests");
      },
      async parseMeal(): Promise<AiProviderResult> {
        return {
          raw: {
            schema_version: PARSED_MEAL_SCHEMA_VERSION,
            meal_type: null,
            items: [],
          },
          modelId: "mock",
          latencyMs: 1,
          tokensInput: 10,
          tokensOutput: 5,
          tokensThinking: 120,
        };
      },
      async extractLabel(): Promise<AiProviderResult> {
        throw new Error("no usado");
      },
    };
    await buildParseMealHandler(provider)({
      data: { text: secret, locale: "es-CO" },
    } as CallableRequest<unknown>);

    const entries = infoMock.mock.calls.map((c) => c.arguments[1] as Record<string, unknown>);
    assert.ok(entries.some((e) => e.tokensThinking === 120));
    for (const call of infoMock.mock.calls) {
      assert.equal(JSON.stringify(call.arguments).includes("SECRETO-77"), false);
    }
  } finally {
    infoMock.mock.restore();
  }
});

test("SPEC-039 R1: un valor inválido se ignora y registra invalid-config sin el valor", (t) => {
  const warn = t.mock.method(functionsLogger, "warn", () => {});
  assert.equal(resolveThinkingBudget("abc"), undefined);
  assert.equal(warn.mock.callCount(), 1);
  assert.deepEqual(warn.mock.calls[0].arguments, [
    "config",
    { errorCode: "invalid-config", variable: "GEMINI_THINKING_BUDGET" },
  ]);
  assert.ok(!JSON.stringify(warn.mock.calls[0].arguments).includes("abc"));

  warn.mock.resetCalls();
  assert.equal(resolveThinkingBudget("0"), 0);
  assert.equal(resolveThinkingBudget(undefined), undefined);
  assert.equal(warn.mock.callCount(), 0);
});
