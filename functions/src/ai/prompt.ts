import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { ParseMealRequest } from "./schemas.js";

const PROMPT_TEMPLATE = readFileSync(
  join(__dirname, "prompts", "parse_meal.v1.md"),
  "utf-8",
);

/** Compartido entre todos los `AiProvider` (vertex, ollama, ...): mismo prompt siempre. */
export function renderParseMealPrompt(input: ParseMealRequest): string {
  return PROMPT_TEMPLATE.replace("{{LOCALE}}", input.locale).replace(
    "{{TEXTO_USUARIO}}",
    input.text,
  );
}
