# SPEC-019: Racha de días registrados

## Status
Draft
Path: Standard (cuenta días con registros; no es un cálculo nutricional)

## Objective
Mostrar en "Hoy" cuántos días seguidos lleva la persona registrando lo que come, en tono neutro.

## Context
Backlog T-020 (opcional). Diseño: contador con ícono de llama junto al saludo en "Hoy" (lienzo
https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD).

## User Story
Como persona que intenta ser constante, quiero ver cuántos días seguidos llevo registrando.

## Requirements
- R1. **Racha:** número de días seguidos, hasta hoy, con al menos una comida registrada. Si hoy aún no
  hay registros, la racha cuenta hasta ayer (no se "rompe" hasta que termina el día).
- R2. Se muestra en el encabezado de "Hoy" como una píldora con ícono y número, con etiqueta
  semántica "N días seguidos registrando".
- R3. **Tono neutro:** sin mensajes de pérdida, castigos ni notificaciones. Con racha 0, la píldora
  muestra 0 sin texto adicional.
- R4. La regla vive en una función pura (en la app o en `nutrition_core`), con tests.

## Acceptance Criteria
- AC1. Registros hoy, ayer y anteayer → 3; registros ayer y anteayer (hoy vacío) → 2; registros hoy y
  anteayer (ayer vacío) → 1; sin registros → 0 `[unit]`.
- AC2. La píldora muestra el número y su etiqueta semántica `[widget]`.
- AC3. Ningún texto de la pantalla menciona perder la racha `[revisión]`.

## Technical Constraints
- Días por fecha local de `eaten_at`. Sistema visual de SPEC-010.

## Components / Files Affected
- `app/lib/features/diary/` (píldora y lectura), función de racha y su test.

## Dependencies
- SPEC-011.

## Edge Cases
- Cambio de zona horaria o de hora: se usa la fecha local de cada comida.
- Racha muy larga (más de 365): la lectura se limita a los últimos 400 días.

## Security & Privacy
- No sale ningún dato del dispositivo.

## Tests Required
- Unit: AC1. Widget: AC2. Revisión: AC3.

## Out of Scope
- Logros, medallas, notificaciones o recordatorios.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC3 con evidencia; analyze y tests verdes; reviewer PASS.

## Change Log
- 2026-10-03: creación a partir de T-020 y del diseño "kcalcula ia UI".

## Review
Informe del reviewer: pendiente.
