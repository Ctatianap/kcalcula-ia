# SPEC-014: Progreso

## Status
Approved
Path: Strict (cálculos nuevos en `packages/nutrition_core`: promedios y días en meta)

## Objective
Que la pestaña Progreso muestre promedios de kcal y macros por semana, mes y 3 meses, y cuántos días
se estuvo en la meta.

## Context
Backlog T-015. Diseño: artboard "Progreso" del lienzo
https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD. Reemplaza el estado provisional de SPEC-010 R5. La
tarjeta de peso es SPEC-015.

## User Story
Como persona que sigue un objetivo, quiero ver cómo me ha ido en promedio para ajustar lo que como.

## Requirements
- R1. **Periodo:** selector "Semana" (últimos 7 días, hoy incluido), "Mes" (últimos 30) y "3 meses"
  (últimos 90).
- R2. **Promedio diario de kcal** (`nutrition_core`): suma de kcal de los días **con al menos un
  registro**, dividida por el número de esos días, sin redondear hasta presentar. Los días sin
  registros no cuentan: un día no registrado no es un día en 0. **Decisión de producto**,
  documentada.
- R3. **Días en meta:** "N de M días en meta", donde M son los días con registros del periodo y N los
  que quedan "en tu meta" según SPEC-011 R3, frente a la meta vigente. Se muestra "meta 1.640".
- R4. **Gráfico:** en "Semana", una barra por día con la línea de la meta; en "Mes" y "3 meses", una
  barra por semana con el promedio diario de esa semana. Las barras usan los colores de estado de
  SPEC-010 (sin alarma) y llevan su valor como texto accesible.
- R5. **Macros:** promedio diario de proteína, carbohidratos y grasa (misma regla que R2), en tarjetas
  con el color de cada macro.
- R6. **Sin registros en el periodo:** "Todavía no hay registros en este periodo." sin gráfico ni
  promedios.
- R7. Sin meta: promedios sin "días en meta" y sin línea de meta.

## Acceptance Criteria
- AC1. Promedio: días con 1.500, 1.700 y 0 registros (sin comidas) → 1.600 sobre 2 días; macros con
  la misma regla `[unit, nutrition_core]`.
- AC2. Días en meta: con meta 2.000 y días de 1.900, 2.300 y 1.500 → "1 de 3 días en meta"
  `[unit, nutrition_core]`.
- AC3. Semana con 6 días con registros: gráfico con 7 posiciones (el día sin registros vacío),
  "Promedio diario", "N de 6 días en meta" y "meta 2.000" `[widget]`.
- AC4. "Mes" agrupa por semanas (lunes a domingo) con el promedio diario de cada una `[unit + widget]`.
- AC5. Sin registros → mensaje de R6; sin meta → sin días en meta ni línea `[widget]`.
- AC6. Cada barra tiene su valor como etiqueta semántica `[widget]`.

## Technical Constraints
- Invariante 3: sumas y promedios en `nutrition_core`, redondeo solo al presentar.
- Gráfico dibujado con widgets propios o `CustomPainter`, sin dependencias nuevas (si hiciera falta
  una, se verifica su versión al añadirla).

## Components / Files Affected
- `packages/nutrition_core/lib/src/period_summary.dart` y su test.
- `app/lib/features/progress/` (reemplaza el provisional de SPEC-010).

## Dependencies
- SPEC-010, SPEC-011 (regla de estado y `mealsBetween`).

## Edge Cases
- Periodo que empieza antes del primer registro: solo cuentan los días con registros.
- Cambio de hora o de zona horaria: los días se agrupan por la fecha local de `eaten_at`.
- 90 días de datos: la lectura es una sola consulta por periodo.

## Security & Privacy
- No sale ningún dato nuevo del dispositivo.

## Tests Required
- Unit: AC1, AC2, AC4 (`nutrition_core`). Widget: AC3–AC6. Manual: recorrido en el teléfono.

## Out of Scope
- Peso (SPEC-015), exportar el resumen (SPEC-016), comparaciones entre periodos, metas históricas.

## Open Questions
- Ninguna. La regla de R2 (solo días con registros) se puede cambiar al aprobar.

## Definition of Done
- AC1–AC6 con evidencia; analyze y tests verdes (`nutrition_core` y app); reviewer PASS; recorrido
  manual; aprobación de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-03: creación a partir de T-015 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.

## Review
Informe del reviewer: pendiente.
