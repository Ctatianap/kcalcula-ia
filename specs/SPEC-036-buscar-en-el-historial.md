# SPEC-036: Buscar en el historial

## Status
Implementing
Path: Standard (búsqueda de solo lectura sobre comidas guardadas; no sale ningún dato)

## Objective
Encontrar los días en que la persona comió un alimento.

## Context
Separada de SPEC-026 (R5/AC5) a pedido de la usuaria (2026-10-08, "sí, confirmo las cuatro"). Decisión
ya tomada: no filtra por tipo de comida.

## User Story
Como persona que quiere saber cuándo comió arepa, quiero buscarlo en el historial.

## Requirements
- R1. Campo "Buscar en tus comidas" en Historial que lista los días con comidas que contienen ese
  alimento (por `name_snapshot`, normalizado como la búsqueda de SPEC-018), del más reciente al más
  antiguo, hasta 50. Tocar un día lo abre en el calendario.
- R2. Sin resultados: "No encontré comidas con ese alimento."
- R3. No filtra por tipo de comida.

## Acceptance Criteria
- AC1. Buscar "arepa" lista los días con arepa, del más reciente al más antiguo `[widget]`.
- AC2. Sin resultados → el mensaje de R2 `[widget]`.
- AC3. "Arepa" y "arepá" dan lo mismo (normalización) `[unit]`.

## Technical Constraints
- La UI pasa por `infra/storage`. Errores como SPEC-009.

## Components / Files Affected
- `app/lib/infra/storage/`, `app/lib/features/history/`.

## Dependencies
- SPEC-013, SPEC-018, SPEC-026.

## Edge Cases
- Menos de 2 letras: no busca.
- Más de 50 días: los 50 más recientes.

## Security & Privacy
- No sale ningún dato del dispositivo.

## Tests Required
- Unit: AC3. Widget: AC1, AC2. Manual: buscar en el teléfono.

## Out of Scope
- Filtrar por tipo de comida, rango de fechas.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC3 con evidencia · analyze y tests verdes · reviewer PASS enlazado.

## Change Log
- 2026-10-08: creación al separar R5/AC5 de SPEC-026. Pendiente de aprobación de la usuaria.
- 2026-10-08: **Approved por la usuaria** ("aprobada la SPEC-036"). Status → Implementing.

## Review
Informe del reviewer:
