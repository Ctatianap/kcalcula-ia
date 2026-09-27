import { defineString } from "firebase-functions/params";

/**
 * Modelo y región vienen de configuración, no del código (ai-pipeline,
 * regla 7). Defaults según PV-02/PV-04 (`docs/research/2026-09-27-vertex-ai-functions.md`).
 */
export const vertexProjectIdParam = defineString("VERTEX_PROJECT_ID");
export const vertexLocationParam = defineString("VERTEX_LOCATION", {
  default: "us-east1",
});
export const geminiModelIdParam = defineString("GEMINI_MODEL_ID", {
  default: "gemini-2.5-flash",
});
