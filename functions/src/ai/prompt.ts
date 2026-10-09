import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { CorrectMealRequest, ParseMealRequest } from "./schemas.js";

const PARSE_MEAL_PROMPT_TEMPLATE = readFileSync(
  join(__dirname, "prompts", "parse_meal.v1.md"),
  "utf-8",
);

const CORRECT_MEAL_PROMPT_TEMPLATE = readFileSync(
  join(__dirname, "prompts", "correct_meal.v1.md"),
  "utf-8",
);

const EXTRACT_LABEL_PROMPT_TEMPLATE = readFileSync(
  join(__dirname, "prompts", "extract_label.v1.md"),
  "utf-8",
);

/** Compartido entre todos los `AiProvider` (vertex, ollama, ...): mismo prompt siempre. */
export function renderParseMealPrompt(input: ParseMealRequest): string {
  return PARSE_MEAL_PROMPT_TEMPLATE.replace("{{LOCALE}}", input.locale).replace(
    "{{TEXTO_USUARIO}}",
    input.text,
  );
}

/**
 * SPEC-004: sin sustituciones (la imagen viaja aparte, no dentro del texto
 * del prompt) — función igual a `renderParseMealPrompt` por consistencia y
 * para que un cambio de prompt no tenga que tocar los tres providers.
 */
export function renderExtractLabelPrompt(): string {
  return EXTRACT_LABEL_PROMPT_TEMPLATE;
}

/**
 * SPEC-024: los ítems actuales (sin nutrientes, R2) como JSON con su índice,
 * y la corrección del usuario.
 */
export function renderCorrectMealPrompt(input: CorrectMealRequest): string {
  const items = JSON.stringify(
    input.items.map((item, index) => ({ index, ...item })),
    null,
    2,
  );
  // La corrección primero y con funciones como reemplazo: así un `$&` o un
  // "{{CORRECCION}}" dentro del texto del usuario no deforma el prompt.
  return CORRECT_MEAL_PROMPT_TEMPLATE.replace("{{CORRECCION}}", () => input.correction)
    .replace("{{LOCALE}}", () => input.locale)
    .replace("{{ITEMS}}", () => items);
}
