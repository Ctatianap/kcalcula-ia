# SPEC-005: Evals de IA

## Status
Draft
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
  (mínimo viable, no exige que las 20 fotos ya existan para que el código funcione) `[unit]`.
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
`run_smoke.ts`) · `functions/src/evals/run_extract_label.ts` (nuevo) · `functions/package.json`
(script `evals`) · `functions/src/ai/fake.ts` (sus fixtures de texto siguen siendo las 10 de
siempre; se revisa si conviene alinear ids con el dataset ampliado, sin romper los tests
existentes que ya las usan).

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
- **Las ~20 fotos de etiquetas reales**: ¿las aporta el usuario durante esta SPEC (fotos de
  productos que tenga a mano), o se deja la infraestructura lista (R3/R4/AC5) con el dataset vacío
  y las fotos quedan pendientes para cuando se retome T-006 más adelante? Si las aporta: ¿dónde las
  deja (carpeta local que yo lea) y prefiere que las fotos NO se suban a git (mismo criterio que
  `data/sources/`, `.gitignore`) o sí quiere versionarlas?
- **Reemplazar `run_smoke.ts`/`slice_smoke.jsonl` vs. mantenerlos**: propongo reemplazarlos (ver
  Technical Constraints) para no dejar dos runners de texto parcialmente redundantes — ¿de acuerdo?
- **Proveedor para el baseline "oficial" de esta SPEC**: propongo `ollama` (gratis, ya verificado
  que funciona para texto e imagen) como el baseline que sí se ejecuta ahora, dejando `vertex`
  como AC4/pendiente aceptado hasta que exista el proyecto GCP real — ¿de acuerdo, o prefieres
  gastar en un run puntual de Vertex ahora para tener ambos?

## Definition of Done
- AC1-AC8 con evidencia enlazada (AC4 y posiblemente AC6 pueden quedar "pendiente aceptado").
- `tsc`/`npm test` sin errores en `functions`.
- Reviewer: `PASS` enlazado.
- `evals/README.md` refleja los comandos reales que funcionan.

## Change Log
- 2026-09-28: creación, a partir de T-006 de `docs/backlog.md`.

## Review
Informe del reviewer:
