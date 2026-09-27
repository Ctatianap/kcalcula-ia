import { randomUUID } from "node:crypto";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logParseMealAttempt } from "./logger.js";
import type { AiProvider } from "./provider.js";
import {
  PARSED_MEAL_SCHEMA_VERSION,
  parseMealRequestSchema,
  parsedMealSchema,
  type ParsedMeal,
} from "./schemas.js";

/** No es un código nativo de `HttpsError`: viaja en `details.errorCode`. */
export const AI_INVALID_OUTPUT_ERROR_CODE = "ai-invalid-output";

/**
 * Handler puro de `parseMeal`, separado de su registro como Cloud Function
 * (`index.ts`) para poder probarlo con un `AiProvider` fake o mock (AC2, AC3,
 * AC10).
 */
export function buildParseMealHandler(provider: AiProvider) {
  return async (request: CallableRequest<unknown>): Promise<ParsedMeal> => {
    const requestId = randomUUID();
    const parsedInput = parseMealRequestSchema.safeParse(request.data);

    if (!parsedInput.success) {
      logParseMealAttempt({
        requestId,
        promptVersion: PARSED_MEAL_SCHEMA_VERSION,
        modelId: "n/a",
        latencyMs: 0,
        valid: false,
        errorCode: "invalid-argument",
      });
      throw new HttpsError(
        "invalid-argument",
        "El texto debe tener entre 1 y 500 caracteres.",
      );
    }

    let attempt = await provider.parseMeal(parsedInput.data);
    let parsedOutput = parsedMealSchema.safeParse(attempt.raw);

    if (!parsedOutput.success) {
      attempt = await provider.parseMeal(parsedInput.data);
      parsedOutput = parsedMealSchema.safeParse(attempt.raw);
    }

    logParseMealAttempt({
      requestId,
      promptVersion: PARSED_MEAL_SCHEMA_VERSION,
      modelId: attempt.modelId,
      latencyMs: attempt.latencyMs,
      tokensInput: attempt.tokensInput,
      tokensOutput: attempt.tokensOutput,
      valid: parsedOutput.success,
      errorCode: parsedOutput.success ? undefined : AI_INVALID_OUTPUT_ERROR_CODE,
    });

    if (!parsedOutput.success) {
      throw new HttpsError(
        "invalid-argument",
        "No pude entender la comida, ¿puedes reformularla?",
        { errorCode: AI_INVALID_OUTPUT_ERROR_CODE },
      );
    }

    return parsedOutput.data;
  };
}
