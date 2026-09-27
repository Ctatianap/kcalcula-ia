import { GoogleGenAI } from "@google/genai";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { AiProvider, AiProviderResult } from "./provider.js";
import { PARSED_MEAL_RESPONSE_SCHEMA, type ParseMealRequest } from "./schemas.js";

const PROMPT_TEMPLATE = readFileSync(
  join(__dirname, "prompts", "parse_meal.v1.md"),
  "utf-8",
);

function renderPrompt(input: ParseMealRequest): string {
  return PROMPT_TEMPLATE.replace("{{LOCALE}}", input.locale).replace(
    "{{TEXTO_USUARIO}}",
    input.text,
  );
}

export interface VertexAiProviderConfig {
  project: string;
  location: string;
  modelId: string;
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
        contents: renderPrompt(input),
        config: {
          responseMimeType: "application/json",
          responseJsonSchema: PARSED_MEAL_RESPONSE_SCHEMA,
          temperature: 0,
        },
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
      };
    },
  };
}
