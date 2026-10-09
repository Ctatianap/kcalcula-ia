/** SPEC-024: `undefined` si no hay texto o no es JSON (sin propagar el texto). */
export function parseJsonOrUndefined(text: string | undefined): unknown {
  if (text === undefined) return undefined;
  try {
    return JSON.parse(text);
  } catch {
    return undefined;
  }
}
