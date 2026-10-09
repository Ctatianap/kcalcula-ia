// `require` directo (no `import * as`): así el objeto es el mismo que
// referencian los tests al mockear `info` para AC10 — `import * as` de
// TypeScript reexpone las propiedades como getters, que `node:test`'s
// `mock.method` no reconoce como método mockeable.
import logger = require("firebase-functions/logger");

/**
 * Todo lo que se registra de un intento de `parseMeal`. Tipado a propósito
 * sin ningún campo de texto libre: es estructuralmente imposible filtrar el
 * contenido del usuario (invariante 5, AC10).
 */
export interface ParseMealLogEntry {
  requestId: string;
  promptVersion: string;
  modelId: string;
  latencyMs: number;
  valid: boolean;
  tokensInput?: number;
  tokensOutput?: number;
  /** SPEC-039 R2. */
  tokensThinking?: number;
  errorCode?: string;
}

export function logParseMealAttempt(entry: ParseMealLogEntry): void {
  logger.info("parseMeal", entry);
}

/** Igual que `ParseMealLogEntry`, para `extractLabel` (SPEC-004, R11). */
export interface ExtractLabelLogEntry {
  requestId: string;
  promptVersion: string;
  modelId: string;
  latencyMs: number;
  valid: boolean;
  tokensInput?: number;
  tokensOutput?: number;
  /** SPEC-039 R2. */
  tokensThinking?: number;
  errorCode?: string;
}

export function logExtractLabelAttempt(entry: ExtractLabelLogEntry): void {
  logger.info("extractLabel", entry);
}

/**
 * SPEC-039 R1: una variable de configuración con un valor que no sirve. Solo
 * el nombre de la variable y el código, nunca su valor ni datos del usuario.
 */
export function logInvalidConfig(variable: string): void {
  logger.warn("config", { errorCode: "invalid-config", variable });
}

/** SPEC-024 AC7: igual que `ParseMealLogEntry`, para `correctMeal`. */
export interface CorrectMealLogEntry {
  requestId: string;
  promptVersion: string;
  modelId: string;
  latencyMs: number;
  valid: boolean;
  tokensInput?: number;
  tokensOutput?: number;
  tokensThinking?: number;
  /** Cuántas operaciones devolvió (un número, nunca su contenido). */
  operationCount?: number;
  errorCode?: string;
}

export function logCorrectMealAttempt(entry: CorrectMealLogEntry): void {
  logger.info("correctMeal", entry);
}
