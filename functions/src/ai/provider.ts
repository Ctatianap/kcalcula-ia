import type { ParseMealRequest } from "./schemas.js";

export interface AiProviderResult {
  /** JSON crudo devuelto por el modelo, sin validar todavía contra zod. */
  raw: unknown;
  modelId: string;
  latencyMs: number;
  tokensInput?: number;
  tokensOutput?: number;
}

export interface AiProvider {
  parseMeal(input: ParseMealRequest): Promise<AiProviderResult>;
}
