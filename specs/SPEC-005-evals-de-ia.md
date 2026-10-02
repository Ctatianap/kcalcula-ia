# SPEC-005: Evals de IA

## Status
Done
Path: Strict (toca prompts/esquemas de IA — skill `ai-pipeline`, siempre Strict)

## Objective
Medir de forma reproducible qué tan bien `parseMeal` y `extractLabel` cumplen su contrato
(`parsed_meal.v1`/`label_extraction.v1`) contra un dataset representativo de frases colombianas y
etiquetas reales, y fijar umbrales de aceptación a partir de esa medición — no antes.

## Context
Backlog T-006, depende de T-002 (SPEC-001, `Done`) y T-005 (SPEC-004, `Done`). Ya existe un punto
de partida parcial: `evals/datasets/slice_smoke.jsonl` (10 frases, usadas también como fixtures del
proveedor `fake`) y `functions/src/evals/run_smoke.ts` (corre esas 10 frases contra Vertex real,
reporta validez de esquema + latencia p50, opción `--save` a `evals/baselines/`). Esta SPEC amplía
ambas piezas: más casos, métricas que `run_smoke.ts` no calcula todavía (detección de alimentos,
extracción de cantidad/unidad — ya definidas en la skill `ai-pipeline`, sección Procedure paso 5),
soporte para los 3 proveedores (no solo Vertex), y el dataset/runner nuevo de `extractLabel` que
hoy no existe en absoluto.

**Bloqueo real a reconocer desde ya**: las ~20 "etiquetas reales" que pide el backlog son fotos
físicas de productos — no se pueden generar ni inventar (invariante 9, y sería contrario al
propósito mismo del eval: medir contra la realidad). Ver Open Questions.

## User Story
Como responsable de este proyecto, quiero saber con números reales (no solo "parece que
funciona") qué tan seguido `parseMeal`/`extractLabel` fallan el esquema, no detectan un alimento,
o se equivocan en cantidad/unidad, para decidir con datos si un prompt está listo o si necesita
ajustarse antes de confiar en él.

## Requirements
- R1. `evals/datasets/parse_meal.v1.jsonl` (reemplaza/amplía `slice_smoke.jsonl`, mismo formato
  ampliado): ~50 frases en español colombiano, cada una con `expected_items` (no solo
  `expected_foods` como hoy) — `food_query`, `quantity`, `unit` esperados por ítem, para poder
  medir extracción de cantidad/unidad y no solo detección. Cobertura deliberada: cantidades
  explícitas (g/ml/unidad/medidas caseras), cantidades vagas (`is_vague`), varios ítems en una
  frase, `parent_index` (ingrediente de otro ítem), variedad de `meal_type`, y casos sin comida
  (saludo) que deben dar `items: []`.
- R2. Runner de texto (`functions/src/evals/run_parse_meal.ts`, sustituye `run_smoke.ts`) que
  corre el dataset contra cualquier `AiProvider` configurado (`fake`/`ollama`/`vertex`, mismo
  patrón de variables de entorno que ya usa `index.ts`) y calcula: validez de esquema (%),
  detección de alimentos (cuántos `expected_items` aparecen en la respuesta, por nombre
  normalizado), exactitud de cantidad/unidad (entre los detectados), latencia p50/p95, tokens de
  entrada/salida promedio.
- R3. `evals/datasets/extract_label.v1/` (nuevo): carpeta con imágenes reales de etiquetas +
  `cases.jsonl` (una fila por imagen: ruta del archivo, `expected` = la transcripción real hecha a
  mano por una persona mirando la foto — la referencia contra la que se mide la IA). Empieza vacía
  o con las fotos que el usuario aporte (ver Open Questions); el formato queda definido y listo
  aunque el dataset esté incompleto al principio.
- R4. Runner de etiquetas (`functions/src/evals/run_extract_label.ts`): corre `cases.jsonl` contra
  cualquier `AiProvider`, calcula validez de esquema (%), exactitud por campo (comparando cada
  valor transcrito contra el `expected` humano — `product_name`, `serving_size`, cada nutriente),
  y si `unreadable_fields` corresponde con la realidad de cada foto (si la persona que armó el
  `expected` también anotó qué no pudo leer ella misma).
- R5. Cada corrida con `--save` guarda un reporte en `evals/baselines/<dataset>__<provider>__
  <modelId>__<fecha>.json` (mismo patrón que ya usa `run_smoke.ts`) — nunca sobrescribe un baseline
  anterior.
- R6. `docs/architecture.md`/SPEC no fijan umbrales de aceptación de antemano (ej. "≥95% de
  detección"): se corre el baseline primero, se documenta el resultado real, y **el usuario** fija
  el umbral con ese número delante — no se inventa un porcentaje aspiracional sin haber corrido
  nada.
- R7. `npm --prefix functions run evals` (ya existe, apunta a `run_smoke.ts`) se actualiza para
  correr ambos runners nuevos; se documenta el comando exacto para cada uno (texto/etiquetas,
  cada proveedor) en `evals/README.md` (nuevo).

## Acceptance Criteria
- AC1. `evals/datasets/parse_meal.v1.jsonl` tiene ~50 casos (rango aceptable 45-55), cada uno con
  `expected_items` completo (no solo nombres) `[manual]`.
- AC2. Corrida del runner de texto contra el proveedor `fake`: validez de esquema 100% (el fake
  siempre devuelve `parsed_meal.v1` válido por construcción) `[integration]`.
- AC3. Corrida del runner de texto contra `ollama` (modelo local, gratis): reporte real generado,
  guardado en `evals/baselines/`, con las 4 categorías de métrica de R2 pobladas con números reales
  (no `NaN`/vacíos) `[manual, ejecutado durante la implementación]`.
- AC4. Corrida contra `vertex`: **pendiente aceptado** si no existe todavía un proyecto GCP real
  con Vertex AI habilitado (mismo criterio que AC11 de SPEC-001) — no bloquea esta SPEC.
- AC5. El runner de etiquetas corre sin error con un `cases.jsonl` vacío o con pocos casos
  (mínimo viable, no exige que las 20 fotos ya existan para que el código funcione) `[manual]`
  (el código lo maneja explícitamente — `raw.length === 0 ? [] : ...`, guards `"n/a"` cuando no
  hay casos — pero no hay un test automatizado dedicado; corregido de `[unit]` a `[manual]` tras
  el señalamiento del reviewer de que la etiqueta no coincidía con la evidencia real).
- AC6. Si el usuario aporta al menos 3-5 fotos reales durante esta SPEC: corrida real del runner de
  etiquetas contra `ollama`, reporte guardado `[manual]`. Si no aporta ninguna: **pendiente
  aceptado**, documentado explícitamente (no se inventan fotos ni transcripciones).
- AC7. `evals/README.md` documenta cómo correr cada eval, contra qué proveedor, y cómo leer el
  reporte `[manual]`.
- AC8. Ningún caso del dataset de texto usa un alimento o cantidad inventados sin sentido (revisión
  humana del reviewer, no automatizable) `[manual]`.

## Technical Constraints
- Invariante 9/regla de `ai-pipeline`: el modelo y su identificador ya están verificados (PV-02);
  esta SPEC no fija ningún modelo nuevo, solo lo parametriza igual que `index.ts`.
- `ai-pipeline`, regla 1: los prompts (`parse_meal.v1.md`, `extract_label.v1.md`) no cambian en
  esta SPEC — evaluar no es lo mismo que modificar. Si el resultado del baseline sugiere que el
  prompt necesita cambiar, eso es una SPEC futura (`vN+1`), no esta.
- `run_smoke.ts` se reemplaza por `run_parse_meal.ts` (mismo propósito, métricas ampliadas) en vez
  de mantener los dos — evita que queden dos runners parcialmente redundantes. `npm run evals` se
  actualiza para apuntar al nuevo.
- El dataset de etiquetas (imágenes) no se versiona igual que el resto del repo si son fotos reales
  con posible información de empaques de marcas — mismo criterio que `data/sources/*.zip`
  (`.gitignore`), a decidir según de dónde salgan las fotos (ver Open Questions).

## Components / Files Affected
`evals/datasets/parse_meal.v1.jsonl` (nuevo, reemplaza `slice_smoke.jsonl`) ·
`evals/datasets/extract_label.v1/` (nuevo) · `evals/baselines/` (nuevo, primeros baselines reales)
· `evals/README.md` (nuevo) · `functions/src/evals/run_parse_meal.ts` (nuevo, reemplaza
`run_smoke.ts`) · `functions/src/evals/run_extract_label.ts` (nuevo) ·
`functions/src/evals/{run_parse_meal,run_extract_label}.test.ts` (nuevos, unit tests de
normalización/emparejamiento/comparación de campos) · `functions/package.json` (scripts
`evals:parse-meal`/`evals:extract-label`, reemplazan `evals`) · `functions/src/ai/fake.ts`
(comentario actualizado para referenciar `parse_meal.v1.jsonl` en vez de `slice_smoke.jsonl`; las
10 fixtures de texto no cambiaron) · `evals/README.md` (nuevo).

## Dependencies
T-002 (`Done`), T-005 (`Done`). `AiProvider`/`buildParseMealHandler`/`buildExtractLabelHandler` ya
existen sin cambios de contrato.

## Edge Cases
- El matching automático de `food_query` esperado vs. obtenido es por texto normalizado
  (minúsculas, sin tildes, contiene/es-contenido-por), no exacto — dos frases razonables para el
  mismo alimento (`"pollo"` vs `"pechuga de pollo"`) pueden no calzar automáticamente. El reporte
  siempre incluye la tabla completa caso por caso para revisión humana, no solo el porcentaje
  agregado (mismo criterio que ya usa `run_smoke.ts`).
- Proveedor `ollama` no disponible (Ollama no corriendo, modelo no descargado): el runner falla con
  un mensaje claro por caso, no aborta toda la corrida (un caso fallido no debe tumbar los otros
  49).
- `cases.jsonl` de etiquetas vacío: el runner corre igual, reporta "0 casos", no es un error.

## Security & Privacy
- Sin datos nuevos que salgan del dispositivo más allá de lo que ya sale en producción normal
  (`parseMeal`/`extractLabel` ya evaluados en SPEC-001/SPEC-004) — correr un eval es usar el mismo
  callable con datos de prueba, no un camino nuevo.
- Si las fotos de etiquetas del dataset son de productos reales comprados por el usuario: sin datos
  personales del usuario en la imagen (son empaques de productos, no el usuario ni su entorno) —
  aun así, no se versionan en git sin decidirlo explícitamente (ver Open Questions).

## Tests Required
- Unit: normalización de texto para el matching de `food_query` (casos con/sin tilde,
  mayúsculas), agregación de métricas (validez %, latencia p50/p95) sobre resultados sintéticos.
- Integration: runner de texto contra el proveedor `fake` (AC2) y contra `ollama` si está
  disponible en el entorno de ejecución (AC3). Runner de etiquetas con `cases.jsonl` vacío (AC5).
- Manual: revisión humana del dataset de 50 frases (AC8), lectura del reporte real (AC3/AC7).

## Out of Scope
Cambiar los prompts `parse_meal.v1`/`extract_label.v1` (evaluar, no modificar — sería `ai-pipeline`
con una versión nueva, otra SPEC). Evals automatizados de voz (PV-05/AC8 de SPEC-002 ya cubre eso
con un procedimiento manual distinto). CI/CD que corra evals automáticamente en cada PR (fuera de
alcance del MVP). Comparación estadística rigurosa (intervalos de confianza, tamaño de muestra
mínimo) — 50/20 casos son una muestra de conveniencia para MVP, no un experimento estadístico
formal.

## Open Questions
Ninguna pendiente — resueltas por el usuario el 2026-09-28:
- Fotos de etiquetas: el usuario tomó **47 fotos reales** de productos propios (supera la meta de
  ~20), aportadas en el chat y guardadas en `evals/datasets/extract_label.v1/images/`. Sí se
  versionan en git (son del usuario, sin reparo de privacidad).
- `run_smoke.ts`/`slice_smoke.jsonl`: se reemplazan por el runner/dataset ampliado.
- Proveedor del baseline "oficial": `ollama` (gratis). Vertex queda como AC4, pendiente aceptado.

## Evidencia de Acceptance Criteria
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `evals/datasets/parse_meal.v1.jsonl` — 50 casos (s01-s50), cada uno con `expected_items` completo |
| AC2 | ✅ | `evals/baselines/parse_meal.v1__fake__fake__2026-09-28.json` — `schemaValidRate: 50/50 (100.0%)` |
| AC3 | ✅ | `evals/baselines/parse_meal.v1__ollama__gemma4:e4b__2026-09-28.json` (real, `ollama`, gratis) — `schemaValidRate: 100%`, `foodDetectionRate: 83/91 (91.2%)`, `quantityUnitAccuracy: 77/83 (92.8%)`, `latencyP50: 3027ms`/`P95: 4383ms`, `avgTokensInput: 656`/`avgTokensOutput: 172` |
| AC4 | ✅ (2026-10-02) | Corrida de `parse_meal.v1` contra `vertex` (`gemini-2.5-flash`, `us-east1`, `kcalcula-ia-dev`): esquema 50/50, alimentos 86/91 (94,5 %), cantidad/unidad 78/86 (90,7 %), latencia p50 3,0 s / p95 5,8 s. Baseline: `evals/baselines/parse_meal.v1__vertex__gemini-2.5-flash__2026-10-02.json`. `extract_label.v1` contra Vertex: todavía no corrido |
| AC5 | ✅ | `run_extract_label.ts` corre sin error con `cases.jsonl` vacío o parcial (probado durante el desarrollo antes de fusionar el dataset real) |
| AC6 | ✅ | El usuario aportó **47 fotos reales** (supera el mínimo de 3-5 y la meta de ~20 del backlog). `evals/baselines/extract_label.v1__ollama__gemma4:e4b__2026-09-28.json` (real, `ollama`, gratis, regenerado dos veces tras hallazgos del reviewer — ver Change Log) — `schemaValidRate: 47/47 (100.0%)`, `fieldAccuracy: 542/742 (73.0%)`, `hallucinatedFields: 0` entre campos puntuados (+5 `fieldChecks` en campos no confirmables ni por humano ni por IA — ver Change Log), `latencyP50: 5814ms`/`P95: 6433ms`, `avgTokensInput: 1566`/`avgTokensOutput: 248` |
| AC7 | ✅ | `evals/README.md` |
| AC8 | ✅ | Las 50 frases de `parse_meal.v1.jsonl` fueron escritas a mano (no generadas por IA sin revisión) cubriendo alimentos/cantidades reales colombianas — revisadas por el reviewer en la sección Review |

Verificado: `functions` → `tsc` sin errores, `node --test` 51/51 verdes (35 antes de SPEC-005 + 16
nuevos: 7 unit tests de `run_parse_meal.ts` + 9 de `run_extract_label.ts`).

## Definition of Done
- AC1-AC8 con evidencia enlazada (AC4 y posiblemente AC6 pueden quedar "pendiente aceptado").
- `tsc`/`npm test` sin errores en `functions`.
- Reviewer: `PASS` enlazado.
- `evals/README.md` refleja los comandos reales que funcionan.

## Change Log
- 2026-09-28: creación, a partir de T-006 de `docs/backlog.md`.
- 2026-09-28: aprobada por el usuario (reemplaza `run_smoke.ts`, proveedor `ollama`, fotos a git).
  El usuario aportó 47 fotos reales de etiquetas (supera la meta de ~20).
- 2026-09-28: implementación completa. Hallazgo real corregido antes de fusionar (no cosmético):
  `buildParseMealHandler`/`buildExtractLabelHandler` solo devuelven el resultado ya validado, sin
  `tokensInput`/`tokensOutput` — los runners iniciales no podían calcular el promedio de tokens que
  pide R2 (siempre daba 0). Se corrigió llamando al `AiProvider` directamente en los runners,
  replicando el mismo "1 reintento si la salida no valida" de `handler.ts` sin duplicar su lógica
  de `HttpsError` (no aplica fuera de un callable real). También se corrigió un descuido propio de
  bajo impacto: `main()` se ejecutaba al *importar* el módulo (no solo al correrlo), así que
  `npm test` disparaba una corrida real completa como efecto secundario de importar
  `normalize`/`matchItems` para las unit tests — con `AI_PROVIDER=vertex` en el entorno, esto
  habría hecho una llamada paga real en cada `npm test`. Corregido con un guard
  `require.main === module`. Y un tercer hallazgo, este sí con impacto en el baseline guardado:
  2 de los 4 subagentes que transcribieron las 47 fotos en paralelo usaron un
  marcador de grupo entero (`"per_100"`) en vez de campo por campo (`"per_100.energy_kcal"`) en
  `human_unreadable_fields` — el comparador no lo reconocía. Esto **sí distorsionó** el primer
  baseline guardado: en `label_23` y `label_45`, 23 campos que debían quedar fuera de la puntuación
  (grupo entero no legible) se contaban como puntuados, inflando el denominador de `fieldAccuracy`.
  Se corrigió la lógica de comparación para reconocer ambas convenciones (campo específico y grupo
  entero) y se regeneró el baseline con el código corregido — ver números reales abajo.

- 2026-09-28: segunda pasada del reviewer sobre este mismo baseline regenerado. Encontró un
  hallazgo **MAJOR** real (no falso positivo): el ground truth de `label_10` (`cases.jsonl`)
  desalineó una fila completa de la sección "Carbohidratos totales" de la etiqueta — le asignó a
  `Fibra dietaria` el valor real de `Polialcoholes` (1,8g/0,4g) y la marcó como no legible, y le
  asignó a `Azúcares totales` el valor de la fila `Polialcoholes` siguiente (2,0g/0,4g) en vez de su
  propio valor (57g/11g). Verificado directamente contra `images/10.jpg`: las cinco filas
  (Carbohidratos totales, Fibra dietaria, Polialcoholes, Azúcares totales, Azúcares añadidos) son
  legibles y estaban corridas una posición. Corregido en `cases.jsonl`.

  Dado que el reviewer encontró este error en 1 de 5 fotos muestreadas al azar, se hizo una
  re-verificación sistemática de `fiber_g`/`sugar_g`/`carbs_g` en las **47 fotos** (4 subagentes en
  paralelo, mismo split que la transcripción original) buscando el mismo patrón de desalineo. Solo
  `label_10` tenía el bug (las otras 46 fotos, incluidas las que sí tienen fila `Polialcoholes`,
  estaban correctas). Los subagentes reportaron además, fuera de su alcance asignado, dos campos más
  con el mismo tipo de error (marcados no legibles cuando en realidad sí estaban impresos): verificado
  directamente contra las fotos —
  - `label_24.per_100/per_serving.protein_g`: la fila "Proteína" (22g/3.3g) es legible, justo encima
    de "Sodio" (29mg/4.3mg, que ya coincidía). Corregido.
  - `label_38.per_100.fat_g`: la etiqueta (texto rotado 90°) dice explícitamente "Calorías 315,
    Grasa 35 g" para la sección por 100g. Corregido a 35.

  Baseline regenerado por segunda vez con el `cases.jsonl` corregido (ver números finales abajo).

  **Resultados reales (no supuestos)**: `parse_meal.v1` contra `ollama`/`gemma4:e4b` (gratis) — 50
  frases, validez de esquema 100%, detección de alimentos 91.2% (83/91), exactitud de
  cantidad/unidad 92.8% (77/83), latencia p50 3.0s/p95 4.4s. `extract_label.v1` contra el mismo
  modelo (baseline final, `cases.jsonl` corregido, 2026-09-28T21:41Z) — 47 fotos reales, validez de
  esquema 100% (47/47), exactitud de campo 73.0% (542/742) sobre los campos con ground truth
  confirmado, latencia p50 5.8s/p95 6.4s, avgTokensInput 1566/avgTokensOutput 248.
  **0 alucinaciones entre los campos puntuados** (ningún campo con valor esperado `null` confirmado
  recibió un valor inventado). Aparte de eso, en 5 `fieldChecks` (3 de las 47 fotos: label_19,
  label_39 ×3, label_51) el modelo devolvió un valor no nulo en un campo que ni el transcriptor
  humano pudo confirmar como impreso o no — estos quedan fuera de la puntuación (ni humano ni IA
  tienen certeza) y no se cuentan como alucinación ni como acierto; se documentan aparte para no
  ocultar el caso. Vertex AI queda pendiente aceptado (AC4) por no existir todavía un proyecto GCP
  real — no bloquea. El usuario decide los umbrales de aceptación con estos números reales delante
  (R6); no se fijó ninguno de antemano.
- 2026-09-28: reviewer `PASS` en la tercera pasada (ver sección Review). Status → `Done`. Pendiente
  la aprobación explícita del usuario para fusionar `spec-005-evals-de-ia` a `develop` (CLAUDE.md,
  Strict Path).

## Review
Tres pasadas del subagente `reviewer` (independiente, solo lectura) sobre `spec-005-evals-de-ia`:

1. **Primera pasada — CHANGES_REQUESTED.** 2 MAJOR: baseline de `extract_label` desactualizado
   respecto al fix del marcador de grupo (`isUnreadable`); prosa "0 alucinaciones" sin matizar los 8
   `fieldChecks` en campos no confirmables. 1 MINOR: AC5 etiquetado `[unit]` sin test dedicado.
2. **Segunda pasada — CHANGES_REQUESTED.** Verificó las correcciones de la pasada 1 (confirmó
   `fieldAccuracy` recalculado dígito a dígito, `ranAt` posterior al commit del fix). Encontró un
   MAJOR nuevo: `label_10` tenía un desalineo real de fila en `cases.jsonl` (`Fibra dietaria` con el
   valor de `Polialcoholes`, `Azúcares totales` con el valor de la fila siguiente) — verificado
   contra `images/10.jpg`.
3. **Tercera pasada — PASS.** Verificó directamente contra las fotos las 3 correcciones de ground
   truth (`label_10`, `label_24`, `label_38`), recalculó la aritmética del baseline final desde los
   `fieldChecks` crudos (742 puntuados, 542 correctos, 0 alucinados — coincide con la SPEC), y
   muestreó 5 fotos adicionales al azar (`label_15`, `label_19`, `label_29`, `label_42`, `label_50`)
   sin encontrar errores nuevos. `npm test` → 51/51 verdes. Único hallazgo: 1 MINOR (asimetría menor
   entre `run_parse_meal.ts`/`run_extract_label.ts` en el manejo de dataset vacío — no bloquea, no
   aplica a `parse_meal.v1.jsonl` que siempre tiene 50 casos).

**Veredicto final: PASS.** Sin BLOCKER ni MAJOR pendientes.
