/**
 * SPEC-005: corre `evals/datasets/extract_label.v1/cases.jsonl` (fotos
 * reales de etiquetas colombianas) contra cualquier `AiProvider` y reporta
 * validez de esquema, exactitud por campo (contra la transcripción humana)
 * y latencia.
 *
 * Un campo listado en `human_unreadable_fields` de un caso no se puntúa: si
 * ni una persona pudo leerlo con confianza, comparar la IA contra ese
 * "ground truth" incierto no sería justo. Ver R4 de SPEC-005.
 *
 * Cuando el valor esperado es `null` porque el campo simplemente no está
 * impreso (no porque sea ilegible) y la IA devuelve un valor no nulo, se
 * cuenta como "alucinación" además de como error de exactitud — es
 * exactamente el caso que invariante 1/2 de CLAUDE.md prohíbe (la IA nunca
 * debe completar un valor que no está impreso).
 *
 * Uso:
 *   AI_PROVIDER=ollama OLLAMA_MODEL=gemma4:e4b npm --prefix functions run evals:extract-label -- --save
 *   AI_PROVIDER=vertex VERTEX_PROJECT_ID=<proyecto real> npm --prefix functions run evals:extract-label -- --save
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { AiProvider } from "../ai/provider.js";
import { createFakeAiProvider } from "../ai/fake.js";
import { createOllamaProvider } from "../ai/ollama.js";
import { createVertexAiProvider } from "../ai/vertex.js";
import {
  labelExtractionSchema,
  type LabelExtraction,
  type LabelNutrientSet,
} from "../ai/schemas.js";

interface NutrientSetExpected {
  energy_kcal: number | null;
  protein_g: number | null;
  carbs_g: number | null;
  fat_g: number | null;
  fiber_g: number | null;
  sugar_g: number | null;
  sodium_mg: number | null;
}

interface EvalCase {
  id: string;
  image_path: string;
  expected: {
    product_name: string | null;
    serving_size: { quantity: number; unit: string } | null;
    per_serving: NutrientSetExpected | null;
    per_100: NutrientSetExpected | null;
  };
  human_unreadable_fields: string[];
}

interface FieldCheck {
  field: string;
  expected: unknown;
  actual: unknown;
  scored: boolean;
  correct: boolean;
  hallucinated: boolean;
}

interface CaseResult {
  id: string;
  schemaValid: boolean;
  latencyMs: number;
  tokensInput?: number;
  tokensOutput?: number;
  fieldChecks: FieldCheck[];
  scoredCount: number;
  correctCount: number;
  hallucinatedCount: number;
  error?: string;
}

const NUTRIENT_FIELDS = [
  "energy_kcal",
  "protein_g",
  "carbs_g",
  "fat_g",
  "fiber_g",
  "sugar_g",
  "sodium_mg",
] as const;

export function numbersMatch(a: number | null, b: number | null): boolean {
  if (a === null || b === null) return a === b;
  return Math.abs(a - b) < 0.05;
}

/** Un caso puede marcar un campo específico como no legible ("per_serving.fat_g")
 * o el grupo entero ("per_serving", si ni siquiera se pudo leer si esa sección
 * estaba impresa) — ambas convenciones aparecen en `cases.jsonl` (47 fotos
 * transcritas por 4 personas distintas en paralelo), así que se reconocen las
 * dos en vez de solo la forma con punto. */
function isUnreadable(fieldName: string, unreadable: Set<string>): boolean {
  if (unreadable.has(fieldName)) return true;
  const group = fieldName.split(".")[0];
  return unreadable.has(group);
}

export function checkField(
  fieldName: string,
  expected: unknown,
  actual: unknown,
  unreadable: Set<string>,
): FieldCheck {
  const scored = !isUnreadable(fieldName, unreadable);
  let correct = false;
  let hallucinated = false;
  if (typeof expected === "number" || expected === null) {
    correct = numbersMatch(expected as number | null, actual as number | null);
    hallucinated = expected === null && actual !== null && (actual as number) !== null;
  } else {
    correct = expected === actual;
    hallucinated = expected === null && actual !== null;
  }
  return { field: fieldName, expected, actual, scored, correct, hallucinated };
}

function checkNutrientSet(
  prefix: string,
  expected: NutrientSetExpected | null,
  actual: LabelNutrientSet | null,
  unreadable: Set<string>,
): FieldCheck[] {
  return NUTRIENT_FIELDS.map((field) =>
    checkField(
      `${prefix}.${field}`,
      expected ? expected[field] : null,
      actual ? actual[field] : null,
      unreadable,
    ),
  );
}

/** Ver la nota equivalente en run_parse_meal.ts (`callWithRetry`): llama al
 * proveedor directamente para no perder `tokensInput`/`tokensOutput`, que
 * `buildExtractLabelHandler` no expone. */
async function callWithRetry(
  provider: AiProvider,
  imageBase64: string,
): Promise<{
  valid: boolean;
  extraction: LabelExtraction | null;
  latencyMs: number;
  tokensInput?: number;
  tokensOutput?: number;
}> {
  let attempt = await provider.extractLabel({ image_base64: imageBase64, mime_type: "image/jpeg" });
  let parsedOutput = labelExtractionSchema.safeParse(attempt.raw);
  if (!parsedOutput.success) {
    attempt = await provider.extractLabel({ image_base64: imageBase64, mime_type: "image/jpeg" });
    parsedOutput = labelExtractionSchema.safeParse(attempt.raw);
  }
  return {
    valid: parsedOutput.success,
    extraction: parsedOutput.success ? parsedOutput.data : null,
    latencyMs: attempt.latencyMs,
    tokensInput: attempt.tokensInput,
    tokensOutput: attempt.tokensOutput,
  };
}

function selectProvider(): { provider: AiProvider; modelId: string; providerName: string } {
  switch (process.env.AI_PROVIDER) {
    case "vertex": {
      const project = process.env.VERTEX_PROJECT_ID;
      if (!project) {
        throw new Error(
          "AI_PROVIDER=vertex requiere VERTEX_PROJECT_ID (proyecto real de GCP, cuesta dinero real).",
        );
      }
      const modelId = process.env.GEMINI_MODEL_ID ?? "gemini-2.5-flash";
      return {
        provider: createVertexAiProvider({
          project,
          location: process.env.VERTEX_LOCATION ?? "us-east1",
          modelId,
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

function percentile(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  const index = Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length));
  return sorted[index];
}

async function main(): Promise<void> {
  const { provider, modelId, providerName } = selectProvider();

  const datasetDir = join(__dirname, "../../../evals/datasets/extract_label.v1");
  const casesPath = join(datasetDir, "cases.jsonl");
  const raw = readFileSync(casesPath, "utf-8").trim();
  const cases: EvalCase[] = raw.length === 0 ? [] : raw.split("\n").map((line) => JSON.parse(line));

  const results: CaseResult[] = [];

  for (const testCase of cases) {
    const imagePath = join(datasetDir, testCase.image_path);
    const imageBase64 = readFileSync(imagePath).toString("base64");
    const unreadable = new Set(testCase.human_unreadable_fields);
    try {
      const attempt = await callWithRetry(provider, imageBase64);
      const extraction = attempt.extraction;

      const fieldChecks: FieldCheck[] = !extraction
        ? []
        : [
            checkField(
              "product_name",
              testCase.expected.product_name,
              extraction.product_name,
              unreadable,
            ),
            checkField(
              "serving_size.quantity",
              testCase.expected.serving_size?.quantity ?? null,
              extraction.serving_size?.quantity ?? null,
              unreadable,
            ),
            checkField(
              "serving_size.unit",
              testCase.expected.serving_size?.unit ?? null,
              extraction.serving_size?.unit ?? null,
              unreadable,
            ),
            ...checkNutrientSet(
              "per_serving",
              testCase.expected.per_serving,
              extraction.per_serving,
              unreadable,
            ),
            ...checkNutrientSet("per_100", testCase.expected.per_100, extraction.per_100, unreadable),
          ];

      const scored = fieldChecks.filter((f) => f.scored);
      results.push({
        id: testCase.id,
        schemaValid: attempt.valid,
        latencyMs: attempt.latencyMs,
        tokensInput: attempt.tokensInput,
        tokensOutput: attempt.tokensOutput,
        fieldChecks,
        scoredCount: scored.length,
        correctCount: scored.filter((f) => f.correct).length,
        hallucinatedCount: scored.filter((f) => f.hallucinated).length,
      });
    } catch (error) {
      results.push({
        id: testCase.id,
        schemaValid: false,
        latencyMs: 0,
        fieldChecks: [],
        scoredCount: 0,
        correctCount: 0,
        hallucinatedCount: 0,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  const validCount = results.filter((r) => r.schemaValid).length;
  const totalScored = results.reduce((sum, r) => sum + r.scoredCount, 0);
  const totalCorrect = results.reduce((sum, r) => sum + r.correctCount, 0);
  const totalHallucinated = results.reduce((sum, r) => sum + r.hallucinatedCount, 0);
  const latencies = results.map((r) => r.latencyMs).sort((a, b) => a - b);
  const tokensInputValues = results.map((r) => r.tokensInput).filter((v): v is number => v !== undefined);
  const tokensOutputValues = results.map((r) => r.tokensOutput).filter((v): v is number => v !== undefined);
  const average = (values: number[]): number | "n/a" =>
    values.length === 0 ? "n/a" : Math.round(values.reduce((a, b) => a + b, 0) / values.length);

  const report = {
    dataset: "extract_label.v1",
    provider: providerName,
    modelId,
    ranAt: new Date().toISOString(),
    caseCount: cases.length,
    schemaValidRate:
      cases.length === 0 ? "n/a" : `${validCount}/${cases.length} (${((validCount / cases.length) * 100).toFixed(1)}%)`,
    fieldAccuracy:
      totalScored === 0
        ? "n/a"
        : `${totalCorrect}/${totalScored} (${((totalCorrect / totalScored) * 100).toFixed(1)}%)`,
    hallucinatedFields: totalHallucinated,
    latencyP50Ms: percentile(latencies, 50),
    latencyP95Ms: percentile(latencies, 95),
    avgTokensInput: average(tokensInputValues),
    avgTokensOutput: average(tokensOutputValues),
    results,
  };

  console.log(JSON.stringify(report, null, 2));

  if (process.argv.includes("--save")) {
    const outPath = join(
      __dirname,
      `../../../evals/baselines/extract_label.v1__${providerName}__${modelId}__${new Date().toISOString().slice(0, 10)}.json`,
    );
    writeFileSync(outPath, JSON.stringify(report, null, 2));
    console.log(`Guardado en ${outPath}`);
  }
}

// Ver la nota equivalente en run_parse_meal.ts: solo corre al ejecutar el
// script directamente, nunca al importarlo para test.
if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
