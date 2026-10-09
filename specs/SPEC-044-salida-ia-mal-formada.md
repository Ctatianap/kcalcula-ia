# SPEC-044: Salida de IA mal formada y prompts seguros en parseMeal y extractLabel

## Status
Done
Path: Strict (capa de IA: adaptadores y renderizado de prompts; sin cambiar prompts ni esquemas)

## Objective
Que `parseMeal` y `extractLabel` traten una respuesta de la IA que no es JSON como **salida inválida**
(reintento y `ai-invalid-output`), sin dejar escapar su texto, y que el texto del usuario nunca deforme
el prompt, igual que ya hace `correctMeal` (SPEC-024).

## Context
Backlog T-044, hallazgo del reviewer de SPEC-024. Hoy, en `vertex.ts` y `ollama.ts`, `parseMeal` y
`extractLabel` hacen `JSON.parse(text)` antes de validar: si el modelo devuelve algo que no es JSON
(o no devuelve texto), se lanza un error que no pasa por el reintento ni por `ai-invalid-output`; el
usuario ve un error genérico, y el mensaje de `SyntaxError` puede llevar un fragmento del texto del
modelo (que puede repetir lo que escribió el usuario) a los logs de errores no manejados (invariante
5). Además, `renderParseMealPrompt` usa `String.replace` con un string: un texto con `$&`, `` $` `` o
`$'` se interpreta como patrón y deforma el prompt.

## User Story
Como persona que registra, quiero que un fallo raro de la IA se trate como "no te entendí,
reformúlalo" y nunca deje mi texto en un log.

## Requirements
- R1. En los adaptadores de Vertex y Ollama, `parseMeal` y `extractLabel` usan
  `parseJsonOrUndefined` (`functions/src/ai/json.ts`): sin texto o con JSON mal formado, `raw` es
  `undefined`, que zod rechaza → reintento → `ai-invalid-output` (el mismo camino que una salida que no
  cumple el esquema).
- R2. `renderParseMealPrompt` sustituye con funciones (y el texto del usuario de último lugar), de modo
  que `$&`, `` $` ``, `$'` o "{{LOCALE}}" dentro del texto quedan literales.
- R3. Los prompts (`parse_meal.v1.md`, `extract_label.v1.md`) y los esquemas no cambian; las evals no
  tienen que volver a correrse (el texto que recibe el modelo es idéntico para entradas normales).
- R4. Logs: solo metadatos, como hoy.

## Acceptance Criteria
- AC1. `parseMeal` con un proveedor que devuelve `raw: undefined` dos veces → `invalid-argument` con
  `errorCode: ai-invalid-output` y 2 llamadas; con `undefined` y luego una salida válida → la válida
  `[unit, functions]`.
- AC2. Igual para `extractLabel` `[unit, functions]`.
- AC3. `renderParseMealPrompt` con el texto "dos huevos $& {{LOCALE}} $'" → el prompt contiene ese
  texto literal y el locale "es-CO" en su lugar `[unit, functions]`.
- AC4. Para un texto normal, el prompt renderizado es idéntico al de antes (comparado con la
  sustitución anterior) `[unit, functions]`.
- AC5. Los adaptadores de Vertex y Ollama ya no llaman `JSON.parse` directamente (revisión de código)
  y todos los tests existentes siguen verdes `[unit + reviewer]`.

## Technical Constraints
- Skill `ai-pipeline`. Invariantes 1, 5 y 7. Sin cambios en la app.

## Components / Files Affected
- `functions/src/ai/vertex.ts`, `ollama.ts`, `prompt.ts`, tests de `functions/src/ai/`.

## Dependencies
- SPEC-001, SPEC-004, SPEC-024.

## Edge Cases
- El modelo no devuelve texto (`response.text` undefined): hoy lanza "Vertex AI no devolvió texto";
  pasa a ser salida inválida (reintento).
- Errores de red o de cuota de Vertex: siguen lanzándose como hoy (no son salida del modelo).

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No. Reduce el riesgo de que texto del usuario llegue a logs.

## Tests Required
- Unit (functions): AC1–AC4. Regresión: AC5. Sin evals (R3). Sin despliegue obligatorio: se incluye en
  el próximo despliegue (con confirmación).

## Out of Scope
- Cambiar prompts, esquemas, modelo o tiempos de espera.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC5 con evidencia · build y tests verdes en `functions` · reviewer PASS enlazado · aprobación
  explícita de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-09: creación (backlog T-044) a pedido de la usuaria ("continuemos con la t 44").
- 2026-10-09: **Approved por la usuaria** ("si"). Status → Implementing.
- 2026-10-09: implementada. `vertex.ts` y `ollama.ts` usan `parseJsonOrUndefined` en las tres llamadas
  (sin texto deja de lanzar "Vertex AI no devolvió texto": es salida inválida); `renderParseMealPrompt`
  sustituye con funciones. Prompts y esquemas sin cambios. functions 79/79.
- 2026-10-09: reviewer PASS. Status → Review: falta la aprobación explícita de la usuaria para fusionar.
- 2026-10-09: **aprobación explícita de la usuaria para fusionar, hacer push y desplegar** ("si"). Status → Done.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `functions/src/ai/malformed_output.test.ts` › "SPEC-044 AC1…" (dos tests) |
| AC2 | ✅ | mismo archivo › "SPEC-044 AC2…" |
| AC3 | ✅ | mismo archivo › "SPEC-044 AC3…" |
| AC4 | ✅ | mismo archivo › "SPEC-044 AC4…" (tres textos normales, prompt idéntico) |
| AC5 | ✅ | mismo archivo › "SPEC-044 AC5…"; functions 79/79 sin cambiar tests existentes |

## Review
Revisión (2026-10-09, subagente `reviewer`, sobre `4938b43`): **PASS**. AC1–AC5 con evidencia; prompts y
esquemas sin cambios; prompt idéntico para textos normales; salida mal formada por reintento y
`ai-invalid-output`; errores de red o cuota se propagan como antes; logs solo con metadatos. MINOR
(sin bloquear): los tests usan un proveedor simulado, no los adaptadores reales; el test de AC5 busca
la cadena `JSON.parse(` (la revisión de código lo confirma).
