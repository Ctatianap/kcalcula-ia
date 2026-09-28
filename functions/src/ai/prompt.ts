import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { ParseMealRequest } from "./schemas.js";

const PARSE_MEAL_PROMPT_TEMPLATE = readFileSync(
  join(__dirname, "prompts", "parse_meal.v1.md"),
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
