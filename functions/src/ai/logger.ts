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
  errorCode?: string;
}

export function logExtractLabelAttempt(entry: ExtractLabelLogEntry): void {
  logger.info("extractLabel", entry);
}
