import { setGlobalOptions } from "firebase-functions";
import { onCall, onRequest } from "firebase-functions/v2/https";
import {
  geminiModelIdParam,
  vertexLocationParam,
  vertexProjectIdParam,
} from "./ai/config.js";
import { createFakeAiProvider } from "./ai/fake.js";
import { buildParseMealHandler } from "./ai/handler.js";
import type { AiProvider } from "./ai/provider.js";
import { createVertexAiProvider } from "./ai/vertex.js";
import { ping } from "./ping.js";

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit.
setGlobalOptions({ maxInstances: 10 });

/**
 * `fake` por defecto: nunca se llama a Vertex AI (con costo real) a menos
 * que se ponga explícitamente `AI_PROVIDER=vertex` (evals de AC11).
 */
function selectProvider(): AiProvider {
  if (process.env.AI_PROVIDER === "vertex") {
    return createVertexAiProvider({
      project: vertexProjectIdParam.value(),
      location: vertexLocationParam.value(),
      modelId: geminiModelIdParam.value(),
    });
  }
  return createFakeAiProvider();
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
