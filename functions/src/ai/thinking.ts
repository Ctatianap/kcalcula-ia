import { logInvalidConfig } from "./logger.js";

/**
 * SPEC-039 R1: presupuesto de "razonamiento" (thinking) de Gemini por
 * configuración. `@google/genai` 2.24.0: `thinkingConfig.thinkingBudget`,
 * "0 is DISABLED. -1 is AUTOMATIC" (los valores permitidos dependen del
 * modelo).
 */
export interface ThinkingBudget {
  /** `undefined`: no se envía `thinkingConfig` (valor por defecto del modelo). */
  budget?: number;
  /** El valor configurado no era un entero; se ignora. */
  invalid: boolean;
}

export function parseThinkingBudget(raw: string | undefined): ThinkingBudget {
  const text = raw?.trim() ?? "";
  if (text === "") return { invalid: false };
  if (!/^-?\d+$/.test(text)) return { invalid: true };
  return { budget: Number.parseInt(text, 10), invalid: false };
}

/** La `config` de `generateContent` para una salida JSON con [schema]. */
export function buildGenerationConfig(
  schema: unknown,
  thinkingBudget: number | undefined,
): Record<string, unknown> {
  return {
    responseMimeType: "application/json",
    responseJsonSchema: schema,
    temperature: 0,
    ...(thinkingBudget === undefined
      ? {}
      : { thinkingConfig: { thinkingBudget } }),
  };
}

/**
 * SPEC-039 R1: presupuesto a usar a partir de la variable de entorno. Un
 * valor que no es entero se ignora y se registra `invalid-config` (solo el
 * nombre de la variable, nunca su valor).
 */
export function resolveThinkingBudget(raw: string | undefined): number | undefined {
  const thinking = parseThinkingBudget(raw);
  if (thinking.invalid) logInvalidConfig("GEMINI_THINKING_BUDGET");
  return thinking.budget;
}
