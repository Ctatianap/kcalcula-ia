# SPEC-025: Marcas

## Status
Draft
Path: Strict (cambia el esquema de IA y la resolución de alimentos; podría tocar el catálogo
nutricional)

## Objective
Que "un yogur Alpina" o "una arepa Doñarepa" se resuelva al producto de esa marca cuando la persona ya
lo tiene (por su etiqueta confirmada), en lugar del alimento genérico.

## Context
Fase F3 de `docs/backlog.md` ("marcas"). Invariante 8: los valores nutricionales solo vienen de TCAC,
USDA FDC o una **etiqueta confirmada**, con `source_id` y `source_ref`. Hoy la marca solo existe como
parte del nombre de un producto personal (SPEC-004) y `parsed_meal.v1` no tiene campo de marca. Una
base de productos de marca externa (p. ej. Open Food Facts) **no es una fuente aprobada**: su licencia,
cobertura en Colombia y calidad son POR VERIFICAR, y requeriría un ADR.

## User Story
Como persona que compra siempre las mismas marcas, quiero que la app use los valores de mi producto y
no los de un alimento genérico.

## Requirements
- R1. **Esquema `parsed_meal.v2`:** campo opcional `brand` (texto tal como se dijo, o nulo) por ítem.
  Sin nutrientes. Prompt `parse_meal.v2.md`; la app acepta v1 y v2 durante la transición.
- R2. **Productos personales con marca:** campo `brand` en `personal_products` (migración), editable en
  la confirmación de etiqueta (SPEC-004) y prellenado si la IA de la etiqueta lo transcribe
  (`label_extraction.v2`, solo texto impreso).
- R3. **Resolución:** si el ítem trae `brand` y hay productos personales de esa marca que coinciden
  con `food_query`, se proponen primero (`matched` si es uno solo, `ambiguous` si hay varios); si no,
  se resuelve como hoy y el detalle dice "No tienes este producto de {marca}: usé el genérico. Toma
  foto de su etiqueta para guardarlo."
- R4. La marca se guarda en la instantánea del ítem (`meal_items`) y aparece en el detalle, el
  historial y la exportación.
- R5. **Sin fuentes nuevas:** esta SPEC no añade productos de marca al catálogo; evaluar una fuente
  externa es una investigación aparte (Open Questions).

## Acceptance Criteria
- AC1. Con el producto personal "Yogur griego" de marca "Alpina" y el proveedor falso devolviendo
  `{food_query: "yogur", brand: "Alpina"}`, el ítem se resuelve a ese producto con "Alta precisión" si
  la cantidad está en g/ml `[integration]`.
- AC2. Con `brand: "Alpina"` y sin productos de esa marca → genérico del catálogo y el aviso de R3
  `[widget]`.
- AC3. `parsed_meal.v2` acepta `brand` y sigue rechazando nutrientes; la app procesa respuestas v1 y v2
  `[unit, functions + app]`.
- AC4. Migración de `personal_products` y `meal_items` conserva todo y `brand` queda nulo; una comida
  guardada con marca la muestra en el historial y la exportación la incluye `[integration]`.
- AC5. Evals del texto sin regresión frente al baseline de v1 y con casos nuevos de marca `[eval]`.

## Technical Constraints
- Invariantes 1, 2, 4, 8. Skills `ai-pipeline` y `nutrition-data`.

## Components / Files Affected
- `functions/src/ai/` (v2 de esquema y prompt), `evals/`, `app/lib/infra/ai_client/`,
  `app/lib/infra/food_resolution/`, `app/lib/infra/storage/` (migración), `app/lib/features/capture/`
  (confirmación de etiqueta), `app/lib/features/review/`.

## Dependencies
- SPEC-004, SPEC-005, SPEC-018.

## Edge Cases
- Marca escrita distinto ("doña arepa" / "Doñarepa"): normalización como en la búsqueda (SPEC-018,
  SPEC-020).
- Marca sin `food_query` claro ("un Alpina") → `is_vague` y se pide elegir.
- Dos productos de la misma marca → `ambiguous`.

## Security & Privacy
- No sale ningún dato nuevo: la marca ya iba dentro del texto que se envía hoy. Se actualiza
  `docs/privacy.md` solo si se añade una fuente externa (fuera de esta SPEC).

## Tests Required
- Unit: AC3, resolución con marca. Widget: AC2. Integration: AC1, AC4. Eval: AC5.

## Out of Scope
- Base de datos de productos de marca externa, códigos de barras, descarga de datos de internet.

## Open Questions
- ¿Se investiga una fuente de productos de marca (Open Food Facts u otra)? Licencia, cobertura en
  Colombia y calidad: POR VERIFICAR con el subagente `researcher` (nuevo PV) antes de cualquier ADR.
- ¿La IA de etiquetas debe transcribir la marca (cambio a `label_extraction.v2`) o la escribe la
  persona?

## Definition of Done
- AC1–AC5 con evidencia · analyze, tests y evals sin regresión · reviewer PASS enlazado · arquitectura
  actualizada · aprobación de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-04: creación a partir de F3 ("marcas").

## Review
Informe del reviewer: pendiente.
