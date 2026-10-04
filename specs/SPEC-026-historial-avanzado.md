# SPEC-026: Historial avanzado (editar, borrar, mover y buscar)

## Status
Draft
Path: Standard (cambia comidas guardadas en `user.db`; recalcula con `nutrition_core` sin reglas
nuevas; no sale ningún dato)

## Objective
Que la persona pueda arreglar comidas ya guardadas (cantidades, ingredientes, tipo, fecha y hora),
borrarlas y encontrarlas por alimento.

## Context
Fase F3 de `docs/backlog.md` ("historial avanzado"). Hoy una comida guardada no se puede editar ni
borrar (SPEC-012 y SPEC-013 lo dejaron fuera de alcance); solo existe "Borrar todos mis datos". Cada
comida guarda una instantánea de valores (`docs/architecture.md`, Modelo de datos).

## User Story
Como persona que se equivocó al registrar, quiero corregir o borrar esa comida en el historial, para
que mis promedios sean reales.

## Requirements
- R1. **Abrir una comida guardada** desde Hoy o Historial: el "Detalle de comida" en modo edición, con
  sus ítems, cantidades, tipo, fecha y hora.
- R2. **Editar:** −/+ de gramos, quitar ítems, "Añadir ingrediente" (SPEC-018), tipo de comida y
  fecha/hora (no futura). Al guardar se reemplaza la comida en una transacción; los ítems editados se
  recalculan con el catálogo actual y `nutrition_core`; los no tocados conservan su instantánea.
  `updated_at` cambia.
- R3. **Borrar una comida** con confirmación ("¿Borrar el almuerzo de las 13:00?").
- R4. **Duplicar en otro día:** "Repetir hoy" desde una comida antigua (equivale a una reciente de
  SPEC-017).
- R5. **Buscar en el historial:** campo en Historial que lista los días con comidas que contienen ese
  alimento (por `name_snapshot`, normalizado como la búsqueda de SPEC-018), del más reciente al más
  antiguo, hasta 50.
- R6. Hoy, Historial, Progreso, la racha y la exportación reflejan los cambios al volver.

## Acceptance Criteria
- AC1. Editar el huevo de 100 g a 150 g en una comida de ayer y guardar → la comida conserva su `id`,
  el ítem tiene 150 g y sus kcal de `nutrition_core`; el día de ayer en el Historial muestra el total
  nuevo `[integration]`.
- AC2. Mover una comida de las 13:00 de ayer a las 8:00 de hoy → aparece en Hoy y desaparece de ayer;
  una fecha futura no se permite `[widget + integration]`.
- AC3. Borrar con confirmación quita la comida y sus ítems; cancelar no borra nada `[integration]`.
- AC4. Un ítem no tocado conserva su instantánea aunque el catálogo haya cambiado; uno editado usa el
  catálogo actual `[unit]`.
- AC5. Buscar "arepa" lista los días con arepa, del más reciente al más antiguo; sin resultados →
  "No encontré comidas con ese alimento." `[widget]`.
- AC6. Un fallo de escritura muestra un mensaje en español y deja la comida como estaba (SPEC-009)
  `[widget]`.
- AC7. "Repetir hoy" desde una comida antigua abre el detalle con sus alimentos y gramos y guarda una
  comida nueva con la hora actual; al volver, Hoy, Historial, Progreso y la racha muestran los cambios
  `[integration]`.

## Technical Constraints
- Invariantes 3, 4 y 8. Errores como SPEC-009. Confianza de la comida recalculada por reglas
  (regla del 15 %) al guardar.

## Components / Files Affected
- `app/lib/infra/storage/` (actualizar y borrar comida, búsqueda), `app/lib/features/review/` (modo
  edición), `app/lib/features/history/`, `app/lib/features/diary/`.

## Dependencies
- SPEC-012, SPEC-013, SPEC-017, SPEC-018.

## Edge Cases
- Quitar todos los ítems: "Guardar" deshabilitado; para eliminar se usa "Borrar comida".
- Producto personal borrado desde que se registró la comida: el ítem se puede ajustar en gramos con su
  instantánea, pero no recalcular con valores nuevos.
- Editar mientras otra pantalla tiene la comida cargada: al volver se recarga.

## Security & Privacy
- No sale ningún dato del dispositivo.

## Tests Required
- Unit: AC4. Widget: AC2, AC5, AC6. Integration: AC1–AC3, AC7. Manual: recorrido en el teléfono.

## Out of Scope
- Historial de cambios (versiones de una comida), editar desde la exportación, borrar por rango de
  fechas, deshacer un borrado.

## Open Questions
- ¿Al editar un ítem no tocado con un catálogo más nuevo se ofrece "Actualizar con la base actual"? (Por
  defecto, no.)
- ¿La búsqueda del historial también filtra por tipo de comida?

## Definition of Done
- AC1–AC7 con evidencia · analyze y tests verdes · reviewer PASS enlazado · arquitectura actualizada
  (edición de comidas guardadas).

## Change Log
- 2026-10-04: creación a partir de F3 ("historial avanzado").

## Review
Informe del reviewer: pendiente.
