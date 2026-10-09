/**
 * SPEC-024 AC6: corre `evals/datasets/correct_meal.v1.jsonl` (20 correcciones
 * en es-CO) contra cualquier `AiProvider` y reporta validez de esquema
 * (incluye índices dentro de rango, R5), correcciones con todas las
 * operaciones correctas, latencia p50/p95 y tokens promedio.
 *
 * Uso:
 *   AI_PROVIDER=fake npm --prefix functions run evals:correct-meal
 *   AI_PROVIDER=vertex VERTEX_PROJECT_ID=<proyecto real> GEMINI_THINKING_BUDGET=0 \
 *     npm --prefix functions run evals:correct-meal -- --save
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { AiProvider } from "../ai/provider.js";
import { createFakeAiProvider } from "../ai/fake.js";
import { createOllamaProvider } from "../ai/ollama.js";
import { parseThinkingBudget } from "../ai/thinking.js";
import { createVertexAiProvider } from "../ai/vertex.js";
import {
  correctionIndexesAreValid,
  mealCorrectionSchema,
  type CorrectMealRequest,
  type CorrectionOperation,
} from "../ai/schemas.js";
import { normalize, percentile } from "./run_parse_meal.js";

/** Lo que se espera de cada operación (solo lo que importa para acertar). */
export interface ExpectedOperation {
  op: CorrectionOperation["op"];
  index?: number;
  food_query?: string;
  quantity?: number;
  unit?: string;
  size?: string;
}

interface EvalCase {
  id: string;
  items: CorrectMealRequest["items"];
  correction: string;
  expected_operations: ExpectedOperation[];
}

/**
 * Una operación devuelta cumple la esperada si coincide `op`, el índice (si
 * se espera), el alimento (contiene / está contenido, normalizado) y la
 * cantidad, unidad o tamaño que se esperan.
 */
export function operationMatches(
  expected: ExpectedOperation,
  actual: CorrectionOperation,
): boolean {
  if (expected.op !== actual.op) return false;
  if (expected.index !== undefined && expected.index !== actual.index) return false;
  if (expected.food_query !== undefined) {
    const query = actual.item?.food_query;
    if (!query) return false;
    const e = normalize(expected.food_query);
    const a = normalize(query);
    if (!a.includes(e) && !e.includes(a)) return false;
  }
  if (expected.quantity !== undefined && expected.quantity !== actual.quantity) return false;
  if (expected.unit !== undefined && expected.unit !== actual.unit) return false;
  if (expected.size !== undefined && expected.size !== actual.size) return false;
  return true;
}

/** Todas las esperadas, en cualquier orden, y ninguna de más. */
export function correctionMatches(
  expected: ExpectedOperation[],
  actual: CorrectionOperation[],
): boolean {
  if (expected.length !== actual.length) return false;
  const used = new Set<number>();
  return expected.every((exp) => {
    const i = actual.findIndex((act, j) => !used.has(j) && operationMatches(exp, act));
    if (i < 0) return false;
    used.add(i);
    return true;
  });
}

function thinkingBudget(): number | undefined {
  const parsed = parseThinkingBudget(process.env.GEMINI_THINKING_BUDGET);
  if (parsed.invalid) throw new Error("GEMINI_THINKING_BUDGET debe ser un número entero.");
  return parsed.budget;
}

function selectProvider(): { provider: AiProvider; modelId: string; providerName: string } {
  switch (process.env.AI_PROVIDER) {
    case "vertex": {
      const project = process.env.VERTEX_PROJECT_ID;
      if (!project) {
        throw new Error("AI_PROVIDER=vertex requiere VERTEX_PROJECT_ID (cuesta dinero real).");
      }
      const modelId = process.env.GEMINI_MODEL_ID ?? "gemini-2.5-flash";
      return {
        provider: createVertexAiProvider({
          project,
          location: process.env.VERTEX_LOCATION ?? "us-east1",
          modelId,
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

async function main(): Promise<void> {
  const { provider, modelId, providerName } = selectProvider();
  const datasetPath = join(__dirname, "../../../evals/datasets/correct_meal.v1.jsonl");
  const cases: EvalCase[] = readFileSync(datasetPath, "utf-8")
    .trim()
    .split("\n")
    .map((line) => JSON.parse(line));
  const onlyCase = process.argv.find((a) => a.startsWith("--case="))?.slice("--case=".length);

  const results = [];
  for (const testCase of cases) {
    if (onlyCase && testCase.id !== onlyCase) continue;
    const request: CorrectMealRequest = {
      correction: testCase.correction,
      locale: "es-CO",
      items: testCase.items,
    };
    try {
      // Mismo "1 reintento" que `buildCorrectMealHandler`.
      const validate = (raw: unknown) => {
        const parsed = mealCorrectionSchema.safeParse(raw);
        return parsed.success && correctionIndexesAreValid(parsed.data, testCase.items.length)
          ? parsed.data
          : null;
      };
      let attempt = await provider.correctMeal(request);
      let output = validate(attempt.raw);
      if (output === null) {
        attempt = await provider.correctMeal(request);
        output = validate(attempt.raw);
      }
      results.push({
        id: testCase.id,
        correction: testCase.correction,
        schemaValid: output !== null,
        correct: output !== null && correctionMatches(testCase.expected_operations, output.operations),
        latencyMs: attempt.latencyMs,
        tokensInput: attempt.tokensInput,
        tokensOutput: attempt.tokensOutput,
        tokensThinking: attempt.tokensThinking,
        expected: testCase.expected_operations,
        actual: output?.operations ?? attempt.raw,
      });
    } catch (error) {
      results.push({
        id: testCase.id,
        correction: testCase.correction,
        schemaValid: false,
        correct: false,
        latencyMs: 0,
        expected: testCase.expected_operations,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  const n = results.length;
  const valid = results.filter((r) => r.schemaValid).length;
  const correct = results.filter((r) => r.correct).length;
  const latencies = results.map((r) => r.latencyMs).sort((a, b) => a - b);
  const average = (values: (number | undefined)[]): number | "n/a" => {
    const xs = values.filter((v): v is number => v !== undefined);
    return xs.length === 0 ? "n/a" : Math.round(xs.reduce((a, b) => a + b, 0) / xs.length);
  };
  const report = {
    dataset: "correct_meal.v1",
    provider: providerName,
    modelId,
    ranAt: new Date().toISOString(),
    schemaValidRate: `${valid}/${n} (${((valid / n) * 100).toFixed(1)}%)`,
    correctionAccuracy: `${correct}/${n} (${((correct / n) * 100).toFixed(1)}%)`,
    latencyP50Ms: percentile(latencies, 50),
    latencyP95Ms: percentile(latencies, 95),
    avgTokensInput: average(results.map((r) => r.tokensInput)),
    avgTokensOutput: average(results.map((r) => r.tokensOutput)),
    avgTokensThinking: average(results.map((r) => r.tokensThinking)),
    thinkingBudget: thinkingBudget() ?? null,
    results,
  };
  console.log(JSON.stringify(report, null, 2));

  if (process.argv.includes("--save")) {
    if (onlyCase) throw new Error("--case no se puede combinar con --save.");
    const budget = thinkingBudget();
    const outPath = join(
      __dirname,
      `../../../evals/baselines/correct_meal.v1__${providerName}__${modelId}${budget === undefined ? "" : `__thinking${budget}`}__${new Date().toISOString().slice(0, 10)}.json`,
    );
    writeFileSync(outPath, JSON.stringify(report, null, 2));
    console.log(`Guardado en ${outPath}`);
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
