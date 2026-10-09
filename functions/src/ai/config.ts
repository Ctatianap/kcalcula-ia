import { defineString } from "firebase-functions/params";

/**
 * Modelo y región vienen de configuración, no del código (ai-pipeline,
 * regla 7). Defaults según PV-02/PV-04 (`docs/research/2026-09-27-vertex-ai-functions.md`).
 */
// Sin default, la descubierta de funciones de Firebase pregunta el valor de
// forma interactiva y rompe el emulador en modo no interactivo (CI, o
// cualquier arranque con AI_PROVIDER != vertex que ni siquiera necesita este
// valor). Con default vacío, la resolución solo falla en tiempo de
// ejecución si de verdad se usa el proveedor vertex sin configurarlo — ver
// el chequeo en index.ts.
export const vertexProjectIdParam = defineString("VERTEX_PROJECT_ID", {
  default: "",
});
export const vertexLocationParam = defineString("VERTEX_LOCATION", {
  default: "us-east1",
});
export const geminiModelIdParam = defineString("GEMINI_MODEL_ID", {
  default: "gemini-2.5-flash",
});
