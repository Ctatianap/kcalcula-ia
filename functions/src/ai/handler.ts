import { randomUUID } from "node:crypto";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import {
  logCorrectMealAttempt,
  logExtractLabelAttempt,
  logParseMealAttempt,
} from "./logger.js";
import type { AiProvider } from "./provider.js";
import {
  correctionIndexesAreValid,
  correctMealRequestSchema,
  MEAL_CORRECTION_SCHEMA_VERSION,
  mealCorrectionSchema,
  type MealCorrection,
  extractLabelRequestSchema,
  labelExtractionSchema,
  LABEL_EXTRACTION_SCHEMA_VERSION,
  PARSED_MEAL_SCHEMA_VERSION,
  parseMealRequestSchema,
  parsedMealSchema,
  type LabelExtraction,
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
      tokensThinking: attempt.tokensThinking,
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

/**
 * Handler puro de `extractLabel` (SPEC-004), mismo patrón que
 * `buildParseMealHandler`: 1 reintento si la salida no valida, nunca repara
 * con heurísticas, log sin contenido del usuario (nunca la imagen).
 */
export function buildExtractLabelHandler(provider: AiProvider) {
  return async (request: CallableRequest<unknown>): Promise<LabelExtraction> => {
    const requestId = randomUUID();
    const parsedInput = extractLabelRequestSchema.safeParse(request.data);

    if (!parsedInput.success) {
      logExtractLabelAttempt({
        requestId,
        promptVersion: LABEL_EXTRACTION_SCHEMA_VERSION,
        modelId: "n/a",
        latencyMs: 0,
        valid: false,
        errorCode: "invalid-argument",
      });
      throw new HttpsError(
        "invalid-argument",
        "La imagen no es válida o es demasiado grande.",
      );
    }

    let attempt = await provider.extractLabel(parsedInput.data);
    let parsedOutput = labelExtractionSchema.safeParse(attempt.raw);

    if (!parsedOutput.success) {
      attempt = await provider.extractLabel(parsedInput.data);
      parsedOutput = labelExtractionSchema.safeParse(attempt.raw);
    }

    logExtractLabelAttempt({
      requestId,
      promptVersion: LABEL_EXTRACTION_SCHEMA_VERSION,
      modelId: attempt.modelId,
      latencyMs: attempt.latencyMs,
      tokensInput: attempt.tokensInput,
      tokensOutput: attempt.tokensOutput,
      tokensThinking: attempt.tokensThinking,
      valid: parsedOutput.success,
      errorCode: parsedOutput.success ? undefined : AI_INVALID_OUTPUT_ERROR_CODE,
    });

    if (!parsedOutput.success) {
      throw new HttpsError(
        "invalid-argument",
        "No pude leer la etiqueta, ¿puedes tomar otra foto?",
        { errorCode: AI_INVALID_OUTPUT_ERROR_CODE },
      );
    }

    return parsedOutput.data;
  };
}

/**
 * SPEC-024: handler puro de `correctMeal`, mismo patrón que `parseMeal`: 1
 * reintento si la salida no valida (también si usa un índice que no existe,
 * R5), nunca repara con heurísticas, log solo con metadatos (AC7).
 */
export function buildCorrectMealHandler(provider: AiProvider) {
  return async (request: CallableRequest<unknown>): Promise<MealCorrection> => {
    const requestId = randomUUID();
    const parsedInput = correctMealRequestSchema.safeParse(request.data);

    if (!parsedInput.success) {
      logCorrectMealAttempt({
        requestId,
        promptVersion: MEAL_CORRECTION_SCHEMA_VERSION,
        modelId: "n/a",
        latencyMs: 0,
        valid: false,
        errorCode: "invalid-argument",
      });
      throw new HttpsError(
        "invalid-argument",
        "La corrección debe tener entre 1 y 300 caracteres.",
      );
    }

    const itemCount = parsedInput.data.items.length;
    const validate = (raw: unknown) => {
      const parsed = mealCorrectionSchema.safeParse(raw);
      return parsed.success && correctionIndexesAreValid(parsed.data, itemCount)
        ? parsed.data
        : null;
    };

    let attempt = await provider.correctMeal(parsedInput.data);
    let output = validate(attempt.raw);
    if (output === null) {
      attempt = await provider.correctMeal(parsedInput.data);
      output = validate(attempt.raw);
    }

    logCorrectMealAttempt({
      requestId,
      promptVersion: MEAL_CORRECTION_SCHEMA_VERSION,
      modelId: attempt.modelId,
      latencyMs: attempt.latencyMs,
      tokensInput: attempt.tokensInput,
      tokensOutput: attempt.tokensOutput,
      tokensThinking: attempt.tokensThinking,
      operationCount: output?.operations.length,
      valid: output !== null,
      errorCode: output === null ? AI_INVALID_OUTPUT_ERROR_CODE : undefined,
    });

    if (output === null) {
      throw new HttpsError(
        "invalid-argument",
        "No pude aplicar esa corrección. Prueba a decirla de otra forma.",
        { errorCode: AI_INVALID_OUTPUT_ERROR_CODE },
      );
    }
    return output;
  };
}
