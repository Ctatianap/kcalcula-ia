import { setGlobalOptions } from "firebase-functions";
import { onCall, onRequest } from "firebase-functions/v2/https";
import {
  geminiModelIdParam,
  vertexLocationParam,
  vertexProjectIdParam,
} from "./ai/config.js";
import { createFakeAiProvider } from "./ai/fake.js";
import { buildExtractLabelHandler, buildParseMealHandler } from "./ai/handler.js";
import { createOllamaProvider } from "./ai/ollama.js";
import type { AiProvider } from "./ai/provider.js";
import { resolveProviderName } from "./ai/provider_name.js";
import { createVertexAiProvider } from "./ai/vertex.js";
import { ping } from "./ping.js";

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit.
//
// SPEC-007 R9: revisado para una beta cerrada (cientos de usuarios, no
// miles) — 10 instancias concurrentes por función es suficiente margen y
// además acota el gasto máximo posible si `AI_PROVIDER=vertex` quedara
// activo por error (cada instancia solo puede llamar a Vertex AI una vez
// a la vez). Se sube si el checklist de beta muestra que el tráfico real
// lo satura.
setGlobalOptions({ maxInstances: 10 });

/**
 * `fake` por defecto (sin costo). `ollama` usa un modelo local (gratis) —
 * ver docs/decisions/ADR-002-ia-local-vs-vertex.md. `vertex` sí cuesta
 * dinero real: el backend desplegado de `kcalcula-ia-dev` lo usa desde
 * SPEC-029. Cómo se elige: `resolveProviderName`.
 */
function selectProvider(): AiProvider {
  switch (resolveProviderName(process.env)) {
    case "vertex": {
      const project = vertexProjectIdParam.value();
      if (!project) {
        throw new Error(
          "El proveedor vertex requiere VERTEX_PROJECT_ID configurado (un proyecto real de GCP con Vertex AI habilitado).",
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

// Una sola instancia: evita crear dos clientes (Vertex/Ollama) para el
// mismo proveedor cuando ambos callables comparten configuración. Se crea
// en la primera llamada, no al cargar el módulo: `firebase deploy` carga el
// código para descubrir las funciones y ahí no debe leer los params de
// Vertex ni crear su cliente (SPEC-029).
let selectedProvider: AiProvider | undefined;
const aiProvider: AiProvider = {
  parseMeal: (input) => (selectedProvider ??= selectProvider()).parseMeal(input),
  extractLabel: (input) =>
    (selectedProvider ??= selectProvider()).extractLabel(input),
};

export const parseMeal = onCall(
  {
    region: "us-east1",
    enforceAppCheck: true,
    timeoutSeconds: 10,
  },
  buildParseMealHandler(aiProvider),
);

export const extractLabel = onCall(
  {
    region: "us-east1",
    enforceAppCheck: true,
    // SPEC-029: con Vertex, leer una etiqueta tarda p50 8,5 s y p95 21 s
    // (evals del 2026-10-07); con 10 s fallaría 1 de cada 4.
    timeoutSeconds: 60,
  },
  buildExtractLabelHandler(aiProvider),
);

// Placeholder de T-000 para verificar que el emulador arranca.
export const healthCheck = onRequest((request, response) => {
  response.status(200).send(ping());
});
