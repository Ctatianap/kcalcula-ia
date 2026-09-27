/**
 * AC11: corre evals/datasets/slice_smoke.jsonl contra Vertex AI real
 * (no el provider fake) y reporta validez de esquema + latencia p50.
 *
 * Requiere un proyecto real de Firebase/GCP con Vertex AI habilitado y
 * `gcloud auth application-default login` ya hecho (checklist de cuentas).
 * No se pudo ejecutar todavía por esa razón — ver Evidencia de AC en
 * specs/SPEC-001-registro-por-texto.md.
 *
 * Uso:
 *   VERTEX_PROJECT_ID=<proyecto real> npm --prefix functions run evals
 *   VERTEX_PROJECT_ID=<proyecto real> npm --prefix functions run evals -- --save
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { CallableRequest } from "firebase-functions/v2/https";
import { buildParseMealHandler } from "../ai/handler.js";
import { createVertexAiProvider } from "../ai/vertex.js";

interface SmokeCase {
  id: string;
  text: string;
  expected_foods: string[];
}

interface SmokeResult {
  id: string;
  text: string;
  valid: boolean;
  itemsFound: string[];
  expectedFoods: string[];
  latencyMs: number;
  error?: string;
}

function fakeRequest(text: string): CallableRequest<unknown> {
  return { data: { text, locale: "es-CO" } } as CallableRequest<unknown>;
}

async function main(): Promise<void> {
  const project = process.env.VERTEX_PROJECT_ID;
  if (!project) {
    throw new Error(
      "Falta VERTEX_PROJECT_ID. Este script llama a Vertex AI real con costo; " +
        "exporta el proyecto real de GCP antes de correrlo.",
    );
  }
  const location = process.env.VERTEX_LOCATION ?? "us-east1";
  const modelId = process.env.GEMINI_MODEL_ID ?? "gemini-2.5-flash";

  const datasetPath = join(__dirname, "../../../evals/datasets/slice_smoke.jsonl");
  const cases: SmokeCase[] = readFileSync(datasetPath, "utf-8")
    .trim()
    .split("\n")
    .map((line) => JSON.parse(line));

  const handler = buildParseMealHandler(createVertexAiProvider({ project, location, modelId }));

  const results: SmokeResult[] = [];
  for (const testCase of cases) {
    const start = Date.now();
    try {
      const parsed = await handler(fakeRequest(testCase.text));
      results.push({
        id: testCase.id,
        text: testCase.text,
        valid: true,
        itemsFound: parsed.items.map((item) => item.food_query),
        expectedFoods: testCase.expected_foods,
        latencyMs: Date.now() - start,
      });
    } catch (error) {
      results.push({
        id: testCase.id,
        text: testCase.text,
        valid: false,
        itemsFound: [],
        expectedFoods: testCase.expected_foods,
        latencyMs: Date.now() - start,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  const validCount = results.filter((r) => r.valid).length;
  const latencies = results.map((r) => r.latencyMs).sort((a, b) => a - b);
  const p50 = latencies[Math.floor(latencies.length / 2)];

  const report = {
    promptVersion: "parse_meal.v1",
    modelId,
    location,
    ranAt: new Date().toISOString(),
    schemaValidRate: `${validCount}/${cases.length}`,
    latencyP50Ms: p50,
    results,
  };

  console.log(JSON.stringify(report, null, 2));

  if (process.argv.includes("--save")) {
    const outPath = join(
      __dirname,
      `../../../evals/baselines/parse_meal.v1__${modelId}__${new Date().toISOString().slice(0, 10)}.json`,
    );
    writeFileSync(outPath, JSON.stringify(report, null, 2));
    console.log(`Guardado en ${outPath}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
