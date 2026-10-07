export type ProviderName = "vertex" | "ollama" | "fake";

/**
 * SPEC-029 R1/R4: qué proveedor de IA usar.
 *
 * - Emulador (`FUNCTIONS_EMULATOR=true`): solo `AI_PROVIDER`, para que los
 *   comandos de CLAUDE.md (`AI_PROVIDER=ollama firebase emulators:start`)
 *   sigan funcionando y el emulador nunca pase a Vertex por leer
 *   `.env.<proyecto>` (el emulador carga esos archivos y ganan sobre el
 *   shell — ver docs/research/2026-10-07-vertex-dev-config.md).
 * - Desplegado: `DEPLOYED_AI_PROVIDER` (de `.env.<proyecto>`), luego
 *   `AI_PROVIDER`.
 *
 * Cualquier otro valor, o ninguno, es `fake`: sin costo.
 */
export function resolveProviderName(env: NodeJS.ProcessEnv): ProviderName {
  const raw =
    env.FUNCTIONS_EMULATOR === "true"
      ? env.AI_PROVIDER
      : (env.DEPLOYED_AI_PROVIDER ?? env.AI_PROVIDER);
  return raw === "vertex" || raw === "ollama" ? raw : "fake";
}
