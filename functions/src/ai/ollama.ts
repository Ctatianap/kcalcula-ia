import { Ollama } from "ollama";
import { z } from "zod";
import type { AiProvider, AiProviderResult } from "./provider.js";
import { renderExtractLabelPrompt, renderParseMealPrompt } from "./prompt.js";
import {
  labelExtractionSchema,
  parsedMealSchema,
  type ExtractLabelRequest,
  type ParseMealRequest,
} from "./schemas.js";

const PARSED_MEAL_JSON_SCHEMA = z.toJSONSchema(parsedMealSchema);
const LABEL_EXTRACTION_JSON_SCHEMA = z.toJSONSchema(labelExtractionSchema);

export interface OllamaProviderConfig {
  model: string;
  host?: string;
}

/**
 * Adaptador de DESARROLLO: modelo local vía Ollama (gratis, nada sale de
 * esta máquina). Implementa el mismo AiProvider que vertex.ts — mismo
 * prompt, mismo esquema, mismo handler/reintento — para que cambiar a
 * Vertex AI en producción sea solo cambiar `AI_PROVIDER`, no reescribir
 * nada. Requiere `ollama serve` corriendo y el modelo ya descargado
 * (`ollama pull <model>`).
 */
export function createOllamaProvider(config: OllamaProviderConfig): AiProvider {
  const client = new Ollama({ host: config.host ?? "http://localhost:11434" });

  return {
    async parseMeal(input: ParseMealRequest): Promise<AiProviderResult> {
      const start = Date.now();
      const response = await client.chat({
        model: config.model,
        messages: [{ role: "user", content: renderParseMealPrompt(input) }],
        format: PARSED_MEAL_JSON_SCHEMA,
        stream: false,
        think: false,
        options: { temperature: 0 },
      });
      return {
        raw: JSON.parse(response.message.content),
        modelId: config.model,
        latencyMs: Date.now() - start,
        tokensInput: response.prompt_eval_count,
        tokensOutput: response.eval_count,
      };
    },

    async extractLabel(input: ExtractLabelRequest): Promise<AiProviderResult> {
      const start = Date.now();
      const response = await client.chat({
        model: config.model,
        messages: [
          {
            role: "user",
            content: renderExtractLabelPrompt(),
            images: [input.image_base64],
          },
        ],
        format: LABEL_EXTRACTION_JSON_SCHEMA,
        stream: false,
        think: false,
        options: { temperature: 0 },
      });
      return {
        raw: JSON.parse(response.message.content),
        modelId: config.model,
        latencyMs: Date.now() - start,
        tokensInput: response.prompt_eval_count,
        tokensOutput: response.eval_count,
      };
    },
  };
}
