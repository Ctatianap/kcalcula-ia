/**
 * SPEC-005: corre `evals/datasets/parse_meal.v1.jsonl` (~50 frases) contra
 * cualquier `AiProvider` y reporta las 4 categorías de métrica que pide la
 * skill `ai-pipeline`: validez de esquema, detección de alimentos,
 * exactitud de cantidad/unidad, latencia p50/p95 y tokens promedio.
 *
 * Reemplaza a `run_smoke.ts` (SPEC-005, Technical Constraints): mismo
 * dataset base (los 10 casos s01-s10), ampliado a 50 y con métricas que
 * `run_smoke.ts` no calculaba.
 *
 * Uso:
 *   AI_PROVIDER=fake npm --prefix functions run evals:parse-meal
 *   AI_PROVIDER=ollama OLLAMA_MODEL=gemma4:e4b npm --prefix functions run evals:parse-meal -- --save
 *   AI_PROVIDER=vertex VERTEX_PROJECT_ID=<proyecto real> npm --prefix functions run evals:parse-meal -- --save
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { AiProvider } from "../ai/provider.js";
import { createFakeAiProvider } from "../ai/fake.js";
import { createOllamaProvider } from "../ai/ollama.js";
import { parseThinkingBudget } from "../ai/thinking.js";
import { createVertexAiProvider } from "../ai/vertex.js";
import { parsedMealSchema, type ParsedMealItem } from "../ai/schemas.js";

interface EvalCase {
  id: string;
  text: string;
  expected_items: ParsedMealItem[];
}

interface CaseResult {
  id: string;
  text: string;
  schemaValid: boolean;
  latencyMs: number;
  tokensInput?: number;
  tokensOutput?: number;
  tokensThinking?: number;
  itemsFound: string[];
  expectedFoods: string[];
  expectedCount: number;
  matchedCount: number;
  quantityUnitCorrect: number;
  error?: string;
}

export function normalize(text: string): string {
  const withAccents = "áéíóúÁÉÍÓÚñÑ";
  const withoutAccents = "aeiouAEIOUnN";
  let result = text.trim().toLowerCase();
  for (let i = 0; i < withAccents.length; i++) {
    result = result.split(withAccents[i]).join(withoutAccents[i].toLowerCase());
  }
  return result;
}

/** Empareja cada `expected_item` con a lo más un ítem devuelto, por nombre
 * normalizado (contiene/está-contenido-en), sin reusar el mismo ítem dos
 * veces. Ver Edge Cases de SPEC-005: es una aproximación, no un match
 * exacto — el reporte siempre incluye la tabla caso por caso. */
export function matchItems(
  expected: ParsedMealItem[],
  actual: ParsedMealItem[],
): { matchedCount: number; quantityUnitCorrect: number } {
  const usedActual = new Set<number>();
  let matchedCount = 0;
  let quantityUnitCorrect = 0;

  for (const exp of expected) {
    const expNorm = normalize(exp.food_query);
    const foundIndex = actual.findIndex((act, i) => {
      if (usedActual.has(i)) return false;
      const actNorm = normalize(act.food_query);
      return actNorm.includes(expNorm) || expNorm.includes(actNorm);
    });
    if (foundIndex === -1) continue;
    usedActual.add(foundIndex);
    matchedCount++;
    const act = actual[foundIndex];
    if (exp.quantity === act.quantity && exp.unit === act.unit) {
      quantityUnitCorrect++;
    }
  }
  return { matchedCount, quantityUnitCorrect };
}

/**
 * Llama al proveedor directamente (no `buildParseMealHandler`, que solo
 * devuelve el `ParsedMeal` validado y descarta `tokensInput`/`tokensOutput`
 * — el eval sí los necesita para R2). Replica el mismo "1 reintento si la
 * salida no valida" de `handler.ts`, sin envolver el error en `HttpsError`
 * (esto no es un callable real).
 */
async function callWithRetry(
  provider: AiProvider,
  text: string,
): Promise<{
  valid: boolean;
  items: ParsedMealItem[];
  latencyMs: number;
  tokensInput?: number;
  tokensOutput?: number;
  tokensThinking?: number;
}> {
  let attempt = await provider.parseMeal({ text, locale: "es-CO" });
  let parsedOutput = parsedMealSchema.safeParse(attempt.raw);
  if (!parsedOutput.success) {
    attempt = await provider.parseMeal({ text, locale: "es-CO" });
    parsedOutput = parsedMealSchema.safeParse(attempt.raw);
  }
  return {
    valid: parsedOutput.success,
    items: parsedOutput.success ? parsedOutput.data.items : [],
    latencyMs: attempt.latencyMs,
    tokensInput: attempt.tokensInput,
    tokensOutput: attempt.tokensOutput,
    tokensThinking: attempt.tokensThinking,
  };
}

/** SPEC-039 R1: `GEMINI_THINKING_BUDGET` (vacío = valor por defecto del modelo). */
function thinkingBudget(): number | undefined {
  const parsed = parseThinkingBudget(process.env.GEMINI_THINKING_BUDGET);
  if (parsed.invalid) {
    throw new Error("GEMINI_THINKING_BUDGET debe ser un número entero.");
  }
  return parsed.budget;
}

/** El baseline con presupuesto lleva `__thinking<n>` en el nombre. */
function thinkingSuffix(): string {
  const budget = thinkingBudget();
  return budget === undefined ? "" : `__thinking${budget}`;
}

function selectProvider(): { provider: AiProvider; modelId: string; providerName: string } {
  switch (process.env.AI_PROVIDER) {
    case "vertex": {
      const project = process.env.VERTEX_PROJECT_ID;
      if (!project) {
        throw new Error(
          "AI_PROVIDER=vertex requiere VERTEX_PROJECT_ID (un proyecto real de GCP con Vertex AI habilitado, cuesta dinero real).",
        );
      }
      const modelId = process.env.GEMINI_MODEL_ID ?? "gemini-2.5-flash";
      return {
        provider: createVertexAiProvider({
          project,
          location: process.env.VERTEX_LOCATION ?? "us-east1",
          modelId,
          // SPEC-039 R1/R3.
          thinkingBudget: thinkingBudget(),
        }),
        modelId,
        providerName: "vertex",
      };
    }
    case "ollama": {
      const modelId = process.env.OLLAMA_MODEL ?? "gemma4:e4b";
      return {
        provider: createOllamaProvider({ model: modelId, host: process.env.OLLAMA_HOST }),
        modelId,
        providerName: "ollama",
      };
    }
    default:
      return { provider: createFakeAiProvider(), modelId: "fake", providerName: "fake" };
  }
}

export function percentile(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  const index = Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length));
  return sorted[index];
}

async function main(): Promise<void> {
  const { provider, modelId, providerName } = selectProvider();

  const datasetPath = join(__dirname, "../../../evals/datasets/parse_meal.v1.jsonl");
  const cases: EvalCase[] = readFileSync(datasetPath, "utf-8")
    .trim()
    .split("\n")
    .map((line) => JSON.parse(line));

  const results: CaseResult[] = [];

  for (const testCase of cases) {
    try {
      const attempt = await callWithRetry(provider, testCase.text);
      const { matchedCount, quantityUnitCorrect } = matchItems(
        testCase.expected_items,
        attempt.items,
      );
      results.push({
        id: testCase.id,
        text: testCase.text,
        schemaValid: attempt.valid,
        latencyMs: attempt.latencyMs,
        tokensInput: attempt.tokensInput,
        tokensOutput: attempt.tokensOutput,
        tokensThinking: attempt.tokensThinking,
        itemsFound: attempt.items.map((i) => i.food_query),
        expectedFoods: testCase.expected_items.map((i) => i.food_query),
        expectedCount: testCase.expected_items.length,
        matchedCount,
        quantityUnitCorrect,
      });
    } catch (error) {
      results.push({
        id: testCase.id,
        text: testCase.text,
        schemaValid: false,
        latencyMs: 0,
        itemsFound: [],
        expectedFoods: testCase.expected_items.map((i) => i.food_query),
        expectedCount: testCase.expected_items.length,
        matchedCount: 0,
        quantityUnitCorrect: 0,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  const validCount = results.filter((r) => r.schemaValid).length;
  const totalExpected = results.reduce((sum, r) => sum + r.expectedCount, 0);
  const totalMatched = results.reduce((sum, r) => sum + r.matchedCount, 0);
  const totalQtyUnitCorrect = results.reduce((sum, r) => sum + r.quantityUnitCorrect, 0);
  const latencies = results.map((r) => r.latencyMs).sort((a, b) => a - b);
  const tokensInputValues = results.map((r) => r.tokensInput).filter((v): v is number => v !== undefined);
  const tokensOutputValues = results.map((r) => r.tokensOutput).filter((v): v is number => v !== undefined);
  const tokensThinkingValues = results.map((r) => r.tokensThinking).filter((v): v is number => v !== undefined);
  const average = (values: number[]): number | "n/a" =>
    values.length === 0 ? "n/a" : Math.round(values.reduce((a, b) => a + b, 0) / values.length);

  const report = {
    dataset: "parse_meal.v1",
    provider: providerName,
    modelId,
    ranAt: new Date().toISOString(),
    schemaValidRate: `${validCount}/${cases.length} (${((validCount / cases.length) * 100).toFixed(1)}%)`,
    foodDetectionRate:
      totalExpected === 0
        ? "n/a"
        : `${totalMatched}/${totalExpected} (${((totalMatched / totalExpected) * 100).toFixed(1)}%)`,
    quantityUnitAccuracy:
      totalMatched === 0
        ? "n/a"
        : `${totalQtyUnitCorrect}/${totalMatched} (${((totalQtyUnitCorrect / totalMatched) * 100).toFixed(1)}%)`,
    latencyP50Ms: percentile(latencies, 50),
    latencyP95Ms: percentile(latencies, 95),
    avgTokensInput: average(tokensInputValues),
    avgTokensOutput: average(tokensOutputValues),
    // SPEC-039 R2/R3.
    avgTokensThinking: average(tokensThinkingValues),
    thinkingBudget: thinkingBudget() ?? null,
    results,
  };

  console.log(JSON.stringify(report, null, 2));

  if (process.argv.includes("--save")) {
    const outPath = join(
      __dirname,
      `../../../evals/baselines/parse_meal.v1__${providerName}__${modelId}${thinkingSuffix()}__${new Date().toISOString().slice(0, 10)}.json`,
    );
    writeFileSync(outPath, JSON.stringify(report, null, 2));
    console.log(`Guardado en ${outPath}`);
  }
}

// Solo corre al ejecutar el script directamente (`node lib/evals/run_parse_meal.js`),
// nunca al importarlo (p. ej. desde `run_parse_meal.test.ts` para probar `normalize`/
// `matchItems`/`percentile`) — si no, `npm test` dispararía una corrida real (y con
// AI_PROVIDER=vertex, una llamada paga real) como efecto secundario de cargar el módulo.
if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
