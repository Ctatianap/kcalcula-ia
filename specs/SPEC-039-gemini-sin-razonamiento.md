# SPEC-039: Medir gemini-2.5-flash sin razonamiento

## Status
Draft
Path: Strict (parámetros del modelo de IA; skill `ai-pipeline`; evals con Vertex real, cuestan dinero)

## Objective
Medir si desactivar el "razonamiento" (thinking) de `gemini-2.5-flash` baja la latencia de leer
etiquetas y de analizar texto sin perder precisión, y adoptarlo en desarrollo solo si las evals lo
justifican.

## Context
Backlog T-028. Con Vertex (SPEC-029), leer una etiqueta tarda p50 8,5–12,1 s y p95 21–34 s según la
corrida (baseline `extract_label.v1__vertex__gemini-2.5-flash__2026-10-07.json`), cerca del límite
de 60 s, y el texto p50 3,0 s / p95 5,8 s (`parse_meal.v1__vertex__gemini-2.5-flash__2026-10-02.json`).

Verificado en el SDK instalado (`@google/genai` 2.24.0, `dist/genai.d.ts`): `GenerateContentConfig`
acepta `thinkingConfig.thinkingBudget`, "0 is DISABLED. -1 is AUTOMATIC. The default values and
allowed ranges are model dependent"; `usageMetadata.thoughtsTokenCount` informa los tokens de
razonamiento. Hoy `vertex.ts` no fija `thinkingConfig` (usa el valor por defecto del modelo) y solo
registra `candidatesTokenCount`, así que los tokens de razonamiento no se miden. Que
`gemini-2.5-flash` admita `thinkingBudget: 0` está POR VERIFICAR: lo confirma o descarta la propia
eval (AC3).

## User Story
Como persona que fotografía etiquetas, quiero que la lectura tarde menos sin que lea peor.

## Requirements
- R1. **Parámetro por configuración** (regla 7 de `ai-pipeline`): `GEMINI_THINKING_BUDGET`
  (`defineString` en `functions/src/ai/config.ts` y variable de entorno para el runner de evals). Sin
  valor, no se envía `thinkingConfig` (comportamiento de hoy). Con un entero (por ejemplo "0"), se envía
  `thinkingConfig: { thinkingBudget: <n> }` en `parseMeal` y `extractLabel`. Un valor que no es entero
  se ignora y se registra el código `invalid-config` en el log (sin texto del usuario).
- R2. **Medir el razonamiento:** `AiProviderResult` y los logs de metadatos incluyen
  `tokensThinking` (`usageMetadata.thoughtsTokenCount`); los reportes de evals informan su promedio.
- R3. **Evals con presupuesto 0:** correr `parse_meal.v1` (50 casos) y `extract_label.v1` (47 casos)
  con `AI_PROVIDER=vertex` y `GEMINI_THINKING_BUDGET=0`, y una corrida de referencia de cada dataset
  **sin** el parámetro (para tener los tokens de razonamiento de hoy). Comparar contra los baselines:
  validez de esquema, detección de alimentos / exactitud de campos, campos inventados, latencia
  p50/p95 y tokens (entrada, salida y razonamiento).
- R4. **Regla de adopción** (se decide con los números, y la usuaria aprueba):
  - validez de esquema 100 % en los dos datasets;
  - detección de alimentos y exactitud de campos sin bajar más de 2 puntos frente al baseline;
  - campos inventados en etiquetas no más que en el baseline (2);
  - p95 de etiquetas menor que el del baseline.
  Si se cumple: `GEMINI_THINKING_BUDGET=0` en `functions/.env.kcalcula-ia-dev` (lo agrega la usuaria),
  despliegue (con su confirmación) y nuevos baselines. Si no: se deja como está y se anota el
  resultado.
- R5. No cambia ningún prompt ni esquema; el `fake` no cambia.

## Acceptance Criteria
- AC1. Con `GEMINI_THINKING_BUDGET=0`, la configuración que arma `vertex.ts` para `generateContent`
  incluye `thinkingConfig: { thinkingBudget: 0 }`; sin el parámetro no incluye `thinkingConfig`; con
  "abc" no lo incluye `[unit]`.
- AC2. Un resultado con `thoughtsTokenCount: 120` registra `tokensThinking: 120` en el log de
  metadatos, sin texto del usuario `[unit]`.
- AC3. Evals de R3 corridas; tabla comparativa en la Verificación con las métricas de R3 para:
  baseline, sin parámetro (hoy) y presupuesto 0 `[eval]`.
- AC4. Decisión según R4 anotada en el Change Log con la aprobación de la usuaria; si se adopta,
  baselines nuevos guardados y una lectura de etiqueta real en el teléfono con su latencia en Cloud
  Logging `[eval + manual]`.
- AC5. `npm --prefix functions run build && npm --prefix functions test` verdes; prompts y esquemas
  sin cambios frente a `develop` `[unit]`.

## Technical Constraints
- Invariante 1: la IA sigue estructurando; no se toca el contrato de salida.
- Invariante 5: logs solo con metadatos (se agrega un número).
- Invariante 7: sin secretos; el `.env` lo edita la usuaria.
- `firebase deploy` requiere confirmación.

## Components / Files Affected
- `functions/src/ai/config.ts`, `vertex.ts`, `provider.ts`, `logger.ts`, `handler.ts` (pasar el
  dato al log), `index.ts`.
- `functions/src/evals/run_parse_meal.ts`, `run_extract_label.ts` (leer el parámetro e informar
  tokens de razonamiento).
- `evals/baselines/` (si se adopta).
- Tests de `functions/`.

## Dependencies
- SPEC-005 (evals), SPEC-029 (Vertex en dev).

## Edge Cases
- `gemini-2.5-flash` no acepta `thinkingBudget: 0`: la eval lo muestra como error del proveedor en
  todos los casos → no se adopta y se anota.
- Un 429 de cuota en un caso: se repite con `--case` (como en SPEC-029).
- Respuestas inválidas: un reintento y luego `ai-invalid-output`, como hoy (R5 de `ai-pipeline`).

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No. Los datasets de evals son los de siempre.

## Tests Required
- Unit: AC1, AC2, AC5. Eval: AC3, AC4. Manual: AC4 (si se adopta).

## Out of Scope
- Cambiar de modelo o de región.
- Bajar los tiempos límite (60 s / 10 s); se puede proponer después con los números.
- Prompts nuevos (T-030).

## Open Questions
- Ninguna. La regla de adopción (R4) decide; la usuaria aprueba el resultado.

## Definition of Done
- AC1–AC5 con evidencia · build y tests de `functions` verdes · evals sin regresión o resultado
  anotado · reviewer PASS enlazado · aprobación de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-08: creación a pedido de la usuaria ("sigamos con la T-028"). Backlog T-028.

## Review
Informe del reviewer:
