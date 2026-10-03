# SPEC-017: Comidas recientes

## Status
Draft
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

## Change Log
- 2026-10-03: creación a partir de T-018 y del diseño "kcalcula ia UI".

## Review
Informe del reviewer: pendiente.
