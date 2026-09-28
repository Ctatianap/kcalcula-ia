import { setGlobalOptions } from "firebase-functions";
import { onCall, onRequest } from "firebase-functions/v2/https";
import {
  geminiModelIdParam,
  vertexLocationParam,
  vertexProjectIdParam,
} from "./ai/config.js";
import { createFakeAiProvider } from "./ai/fake.js";
import { buildParseMealHandler } from "./ai/handler.js";
import { createOllamaProvider } from "./ai/ollama.js";
import type { AiProvider } from "./ai/provider.js";
import { createVertexAiProvider } from "./ai/vertex.js";
import { ping } from "./ping.js";

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit.
setGlobalOptions({ maxInstances: 10 });

/**
 * `fake` por defecto (sin costo). `AI_PROVIDER=ollama` usa un modelo local
 * (gratis, mientras el proyecto sigue en MVP) — ver
 * docs/decisions/ADR-002-ia-local-vs-vertex.md. `AI_PROVIDER=vertex` sí
 * cuesta dinero real: solo para cuando se decida pasar a producción o para
 * los evals puntuales de AC11.
 */
function selectProvider(): AiProvider {
  switch (process.env.AI_PROVIDER) {
    case "vertex": {
      const project = vertexProjectIdParam.value();
      if (!project) {
        throw new Error(
          "AI_PROVIDER=vertex requiere VERTEX_PROJECT_ID configurado (un proyecto real de GCP con Vertex AI habilitado).",
        );
      }
      return createVertexAiProvider({
        project,
        location: vertexLocationParam.value(),
        modelId: geminiModelIdParam.value(),
      });
    }
    case "ollama":
      return createOllamaProvider({
        model: process.env.OLLAMA_MODEL ?? "gemma4:e4b",
        host: process.env.OLLAMA_HOST,
      });
    default:
      return createFakeAiProvider();
  }
}

export const parseMeal = onCall(
  {
    region: "us-east1",
    enforceAppCheck: true,
    timeoutSeconds: 10,
  },
  buildParseMealHandler(selectProvider()),
);

// Placeholder de T-000 para verificar que el emulador arranca.
export const healthCheck = onRequest((request, response) => {
  response.status(200).send(ping());
});
