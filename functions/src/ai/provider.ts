import type { ExtractLabelRequest, ParseMealRequest } from "./schemas.js";

export interface AiProviderResult {
  /** JSON crudo devuelto por el modelo, sin validar todavía contra zod. */
  raw: unknown;
  modelId: string;
  latencyMs: number;
  tokensInput?: number;
  tokensOutput?: number;
  /** SPEC-039 R2: tokens de razonamiento (`thoughtsTokenCount`). */
  tokensThinking?: number;
}

export interface AiProvider {
  parseMeal(input: ParseMealRequest): Promise<AiProviderResult>;
  extractLabel(input: ExtractLabelRequest): Promise<AiProviderResult>;
}
