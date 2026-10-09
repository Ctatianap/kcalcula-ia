# SPEC-017: Comidas recientes

## Status
Done
Path: Standard (reutiliza el catálogo y el cálculo existentes; no llama a la IA)

## Objective
Que la persona pueda repetir una comida que ya registró antes, sin volver a escribirla ni a enviarla a
la IA.

## Context
Backlog T-018 (parte de F2). Diseño: sección "Recientes" del artboard "¿Qué comiste?" del lienzo
https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD ("Café con leche y pan con mantequilla · 246
kcal").

## User Story
Como persona que come cosas parecidas casi todos los días, quiero repetir una comida reciente con un
toque.

## Requirements
- R1. **Sección "Recientes"** en "¿Qué comiste?" (debajo del campo de texto): hasta 5 comidas
  distintas, de las más recientes a las más antiguas. Dos comidas son "la misma" si tienen los mismos
  alimentos (`food_id` o producto personal) con los mismos gramos.
- R2. Cada una muestra un nombre corto (los nombres de sus alimentos, unidos con "y") y sus kcal
  **recalculadas hoy** con el catálogo actual (como la revisión), no la instantánea vieja.
- R3. Tocar una abre el "Detalle de comida" (SPEC-012) con esos alimentos y gramos ya resueltos, sin
  llamar a la IA; el tipo de comida se asigna por la hora actual; se puede ajustar antes de guardar.
- R4. Si un alimento ya no existe en el catálogo (o el producto personal fue borrado), esa comida no
  aparece en Recientes.
- R5. Sin comidas previas, la sección no se muestra.

## Acceptance Criteria
- AC1. Con 7 comidas registradas (2 repetidas), Recientes muestra 5 distintas, en orden `[widget]`.
- AC2. Tocar una abre el detalle con los mismos alimentos y gramos y **no** llama al `AiClient`
  (fake que falla si se llama) `[integration]`.
- AC3. Las kcal mostradas salen del catálogo actual: si el catálogo de prueba cambia el valor de un
  alimento, la tarjeta muestra el valor nuevo `[unit + widget]`.
- AC4. Una comida con un alimento que ya no está en el catálogo no aparece `[unit]`.
- AC5. Guardar desde el detalle crea una comida nueva con la hora actual `[integration]`.

## Technical Constraints
- Invariantes 1, 3 y 8: sin IA; valores del catálogo con su `source_ref`; cálculo en `nutrition_core`.

## Components / Files Affected
- `app/lib/infra/storage/` (consulta de comidas recientes), `app/lib/features/capture/` (sección),
  `app/lib/features/review/` (entrada sin IA).

## Dependencies
- SPEC-012.

## Edge Cases
- Comida con un ítem de cantidad vaga (estimación): se repite con los mismos gramos, que la persona
  puede ajustar.
- Muchas comidas en el diario: la consulta se limita a las últimas 50.

## Security & Privacy
- No sale ningún dato nuevo del dispositivo (no se usa la IA).

## Tests Required
- Unit: AC3, AC4. Widget: AC1. Integration: AC2, AC5.

## Out of Scope
- Favoritos fijados, renombrar comidas, sugerencias por hora del día.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC5 con evidencia; analyze y tests verdes; reviewer PASS.

## Evidencia
| AC | Evidencia |
|----|-----------|
| AC1 | `app/test/features/capture/recent_meals_flow_test.dart` › "AC1: Recientes muestra 5 comidas distintas, en orden" (widget); `app/test/infra/food_resolution/recent_meals_test.dart` › "AC1/R1: 7 comidas (2 repetidas) → 5 distintas…" (unit) |
| AC2 | `recent_meals_flow_test.dart` › "AC2 + AC5: tocar una abre el detalle con los mismos alimentos y gramos sin llamar a la IA…" (app completa; el `AiClient` falla el test si se llama) |
| AC3 | `recent_meals_test.dart` › "AC3: las kcal salen del catálogo actual, no de la instantánea" (unit) y `recent_meals_flow_test.dart` › "AC3: la tarjeta muestra las kcal del catálogo actual" (widget) |
| AC4 | `recent_meals_test.dart` › "AC4: una comida con un alimento que ya no está en el catálogo no aparece" (y "R4: un producto personal borrado…") |
| AC5 | `recent_meals_flow_test.dart` › "AC2 + AC5: …guardar crea una comida nueva con la hora actual" |

Además: R5 sin comidas previas (unit y widget), texto ×2 en 360 px.

## Change Log
- 2026-10-03: creación a partir de T-018 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.
- 2026-10-03: implementada (autorización única de la usuaria para el lote). Detalles menores:
  - `MealDraft` (en `infra/food_resolution`, compartido por "¿Qué comiste?" y el detalle; lo
    reutilizará la búsqueda manual de SPEC-018) y `ReviewController.fromDraft`. La ruta `/review`
    acepta la etiqueta confirmada o un `MealDraft`.
  - **Confianza al repetir:** se conserva la base de la cantidad y la confianza que las reglas le
    dieron a cada ítem al registrarlo (no la reporta la IA); repetir una comida no la vuelve más
    precisa. Las kcal y macros sí se recalculan con el catálogo actual.
  - "La misma comida": mismo conjunto de alimentos (id del catálogo o del producto personal) con los
    mismos gramos, sin importar el orden.
  - Recientes aparece en la pestaña Texto, debajo de "Analizar"; muestra el nombre (alimentos del
    catálogo actual unidos con "," e "y") y las kcal ("~" salvo si todo es "Alta precisión"). Si la
    lectura falla, la sección no aparece y escribir sigue funcionando.
  - `joinNamesEs` pasó a `format/text_es.dart` (lo usan el detalle y Recientes).
  Status → Review.
- 2026-10-03: reviewer **PASS** (commit c50775b; app 278/278), sin BLOCKER ni MAJOR. MINOR atendidos
  antes de fusionar:
  - el "~" de la tarjeta usa la confianza de la comida de `nutrition_core` (regla del 15 %), igual
    que el detalle, en lugar de una regla propia;
  - "Recientes" es encabezado para el lector de pantalla;
  - la comida repetida guarda la cantidad tal como se dijo la primera vez ("2" "unidad"), no solo
    los gramos;
  - tests: tope de 5 con 8 comidas distintas, límite de 50 en la consulta, regla del 15 % y
    cantidad original; el `AiClient` falso cuenta las llamadas (deben ser 0).
  - Aceptado: si un alimento desaparece entre armar la lista y tocar la tarjeta (muy raro), se omite;
    si no queda ninguno, el detalle muestra "Quitaste todos los alimentos…" con Guardar
    deshabilitado. Una comida repetida conserva la confianza con la que se registró aunque las
    reglas cambien después.
  Fusionada en `develop` por la autorización única de la usuaria. Sigue en Review hasta el
  recorrido manual en el teléfono.
- 2026-10-07: recorrido manual en el teléfono (Motorola edge 50 pro, Android 16, build debug de
  `develop` en `dc92f55`). La usuaria lo dio por bueno ("si ya creo que el resto esta bien").
  Status Review → Done.

## Review
Informe del reviewer (2026-10-03, commit c50775b): **PASS**. AC1–AC5 con evidencia
(`recent_meals_test.dart`, `recent_meals_flow_test.dart`); sin IA, kcal del catálogo actual con
`nutrition_core`, confianza de reglas y `source_ref` del catálogo; fronteras respetadas. MINOR
atendidos (ver Change Log).
