# SPEC-039: Medir gemini-2.5-flash sin razonamiento

## Status
Review
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
  (variable de entorno, leída de `process.env` como `AI_PROVIDER`, en el backend y en el runner de
  evals; no `defineString`, que obligaría a escribirla en el `.env` antes de cualquier despliegue). Sin
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
- 2026-10-08: **Approved por la usuaria** ("aprobada"). Status → Implementing.
- 2026-10-08: implementada. `functions/src/ai/thinking.ts` (`parseThinkingBudget`,
  `buildGenerationConfig`); `vertex.ts` usa la configuración y devuelve `tokensThinking`; logs con
  `tokensThinking`; `logInvalidConfig` para un valor inválido. Nota de implementación (R1): en el
  backend se lee `process.env.GEMINI_THINKING_BUDGET` (como `AI_PROVIDER`) y no con `defineString`,
  porque `firebase deploy --non-interactive` exige en el `.env` cualquier param nuevo aunque tenga valor
  por defecto. Evals corridas (ver Verificación). R4 se cumple. **La usuaria aprueba adoptarlo**
  ("ok"); baselines guardados desde las corridas ya hechas.
- 2026-10-08: la usuaria añadió `GEMINI_THINKING_BUDGET=0` al `.env` y se desplegó con su confirmación.
- 2026-10-08: reviewer CHANGES_REQUESTED solo por AC4 (prueba manual pendiente). MINOR atendidos:
  R1 corregido para decir lo implementado (`process.env`, no `defineString`; motivo en el Change Log
  anterior; **pendiente el visto bueno de la usuaria** a este texto); "n/a" en la tabla donde Vertex no
  informa tokens de razonamiento; `resolveThinkingBudget` en `thinking.ts` con test del log
  `invalid-config` sin el valor. functions 62/62. La usuaria pidió fusionar a `develop` ("fusiona
  todo") con AC4 pendiente. Status → Review. Riesgo a vigilar: `latencyMs` de `parseMeal` en Cloud
  Logging (casos aislados de Vertex de más de 10 s en las evals).
- 2026-10-08: AC4 con evidencia (prueba de la usuaria en el S25 y latencias de Cloud Logging). Solo falta
  el visto bueno de la usuaria al texto corregido de R1 para pasar a Done.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `functions/src/ai/thinking.test.ts` › "SPEC-039 AC1…" (con 0: `thinkingConfig: { thinkingBudget: 0 }`; sin valor o "abc": sin `thinkingConfig`) y "SPEC-039 R1: parseThinkingBudget" |
| AC2 | ✅ | mismo archivo › "SPEC-039 AC2…" (`tokensThinking: 120` en el log; sin el texto) |
| AC3 | ✅ | Tabla de abajo. Corridas del 2026-10-08 con `AI_PROVIDER=vertex`, guardadas en `evals/baselines/` (`…__2026-10-08.json` "como hoy" y `…__thinking0__2026-10-08*.json`) |
| AC4 | ✅ | Decisión: **se adopta** (R4 se cumple; la usuaria aprobó: "ok"). `GEMINI_THINKING_BUDGET=0` en `functions/.env.kcalcula-ia-dev` y desplegado el 2026-10-08. Prueba en el S25 de la usuaria ("quedó perfecto"). Cloud Logging de `extractLabel` desde el despliegue (7 lecturas, todas `valid: true`, sin `tokensThinking`): 2,3 · 2,6 · 2,6 · 2,9 · 6,6 · 9,9 · 10,9 s (antes p50 12,1 s y p95 34,0 s) |
| AC5 | ✅ | functions 62/62; `git diff develop -- functions/src/ai/prompts functions/src/ai/schemas.ts` vacío |

| Métrica | Baseline | Como hoy | Presupuesto 0 |
|---|---|---|---|
| Etiquetas: esquema | 47/47 | 47/47 | 47/47 |
| Etiquetas: campos | 96,1 % | 96,4 % | 95,8 % |
| Etiquetas: inventados | 2 | 2 | 2 |
| Etiquetas: p50 / p95 | 12,1 / 34,0 s | 8,7 / 24,4 s | 2,8 / 4,3 s |
| Etiquetas: > 10 s | — | 13 de 47 (máx. 76,8 s) | 1 de 47 (25,4 s) |
| Etiquetas: tokens entrada / salida / razonamiento | 2.851 / 240 / — | 2.851 / 240 / 1.064 | 2.851 / 219 / n/a (Vertex no lo informa; equivale a 0) |
| Frases: esquema | 50/50 | 50/50 | 50/50 y 50/50 (dos corridas) |
| Frases: detección | 94,5 % | 94,5 % | 96,7 % y 97,8 % |
| Frases: cantidad y unidad | 90,7 % | 91,9 % | 92,0 % y 91,0 % |
| Frases: p50 / p95 | 3,0 / 5,8 s | 3,2 / 6,9 s | 1,5 / 10,2 s y 1,3 / 3,3 s |
| Frases: tokens entrada / salida / razonamiento | 648 / 172 / — | 648 / 172 / 353 | 648 / 136 / n/a (Vertex no lo informa; equivale a 0) |

Casos aislados muy lentos en frases con presupuesto 0: 3 en la primera corrida (s13 10,2 s, s05 107 s,
s44 151 s) y 1 en la segunda (s08 64 s), con los tokens de salida normales. El cliente no configura
reintentos del SDK (`retryOptions` no se pasa, verificado en `@google/genai` 2.24.0), así que la demora
es de Vertex. "Como hoy" también los tiene en etiquetas (13 de más de 10 s, uno de 76,8 s). En la app,
una frase así da el error de tiempo agotado (10 s) y se puede reintentar.

## Review
Informe del reviewer:
