import { GoogleGenAI } from "@google/genai";
import type { AiProvider, AiProviderResult } from "./provider.js";
import { parseJsonOrUndefined } from "./json.js";
import { buildGenerationConfig } from "./thinking.js";
import {
  renderCorrectMealPrompt,
  renderExtractLabelPrompt,
  renderParseMealPrompt,
} from "./prompt.js";
import {
  LABEL_EXTRACTION_RESPONSE_SCHEMA,
  MEAL_CORRECTION_RESPONSE_SCHEMA,
  PARSED_MEAL_RESPONSE_SCHEMA,
  type CorrectMealRequest,
  type ExtractLabelRequest,
  type ParseMealRequest,
} from "./schemas.js";

export interface VertexAiProviderConfig {
  project: string;
  location: string;
  modelId: string;
  /** SPEC-039: `undefined` = valor por defecto del modelo. */
  thinkingBudget?: number;
}

/** Adaptador real a Gemini vía Vertex AI (`@google/genai`, `vertexai: true`). */
export function createVertexAiProvider(
  config: VertexAiProviderConfig,
): AiProvider {
  const client = new GoogleGenAI({
    vertexai: true,
    project: config.project,
    location: config.location,
  });

  return {
    async parseMeal(input: ParseMealRequest): Promise<AiProviderResult> {
      const start = Date.now();
      const response = await client.models.generateContent({
        model: config.modelId,
        contents: renderParseMealPrompt(input),
        config: buildGenerationConfig(
          PARSED_MEAL_RESPONSE_SCHEMA,
          config.thinkingBudget,
        ),
      });
      const text = response.text;
      if (text === undefined) {
        throw new Error("Vertex AI no devolvió texto en la respuesta.");
      }
      return {
        raw: JSON.parse(text),
        modelId: config.modelId,
        latencyMs: Date.now() - start,
        tokensInput: response.usageMetadata?.promptTokenCount,
        tokensOutput: response.usageMetadata?.candidatesTokenCount,
        // SPEC-039 R2.
        tokensThinking: response.usageMetadata?.thoughtsTokenCount,
      };
    },

    async correctMeal(input: CorrectMealRequest): Promise<AiProviderResult> {
      const start = Date.now();
      const response = await client.models.generateContent({
        model: config.modelId,
        contents: renderCorrectMealPrompt(input),
        config: buildGenerationConfig(
          MEAL_CORRECTION_RESPONSE_SCHEMA,
          config.thinkingBudget,
        ),
      });
      return {
        // JSON mal formado = salida inválida (reintento y
        // `ai-invalid-output`), nunca un error con el texto del modelo.
        raw: parseJsonOrUndefined(response.text),
        modelId: config.modelId,
        latencyMs: Date.now() - start,
        tokensInput: response.usageMetadata?.promptTokenCount,
        tokensOutput: response.usageMetadata?.candidatesTokenCount,
        tokensThinking: response.usageMetadata?.thoughtsTokenCount,
      };
    },

    async extractLabel(input: ExtractLabelRequest): Promise<AiProviderResult> {
      const start = Date.now();
      const response = await client.models.generateContent({
        model: config.modelId,
        contents: [
          {
            inlineData: {
              mimeType: input.mime_type,
              data: input.image_base64,
            },
          },
          { text: renderExtractLabelPrompt() },
        ],
        config: buildGenerationConfig(
          LABEL_EXTRACTION_RESPONSE_SCHEMA,
          config.thinkingBudget,
        ),
      });
      const text = response.text;
      if (text === undefined) {
        throw new Error("Vertex AI no devolvió texto en la respuesta.");
      }
      return {
        raw: JSON.parse(text),
        modelId: config.modelId,
        latencyMs: Date.now() - start,
        tokensInput: response.usageMetadata?.promptTokenCount,
        tokensOutput: response.usageMetadata?.candidatesTokenCount,
        // SPEC-039 R2.
        tokensThinking: response.usageMetadata?.thoughtsTokenCount,
      };
    },
  };
}
