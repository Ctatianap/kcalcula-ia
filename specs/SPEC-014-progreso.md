# SPEC-014: Progreso

## Status
Review
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

## Evidencia
| AC | Evidencia |
|----|-----------|
| AC1 | `packages/nutrition_core/test/period_summary_test.dart` › "AC1: promedio diario solo sobre días con registros" (1.500 y 1.700 → 1.600 sobre 2 días; macros; suma sin redondear). Que el día sin comidas no cuente lo prueba el agrupado de la app: AC3 espera 1.917 sobre 6 días (con el día vacío como 0 serían 1.643 sobre 7) |
| AC2 | mismo archivo › "AC2: días en meta" › "meta 2.000 con 1.900, 2.300 y 1.500 → 1 de 3" (y límites 1.800/2.200, sin meta) |
| AC3 | `app/test/features/progress/progress_screen_test.dart` › "AC3: semana con 6 días: 7 posiciones, promedio, \"N de 6 días en meta\" y \"meta 2.000\"" |
| AC4 | `period_summary_test.dart` › "AC4: promedios por semana (lunes a domingo)" (unit) y `progress_screen_test.dart` › "AC4: \"Mes\" agrupa por semanas…" (widget, también "3 meses" con 13 semanas) |
| AC5 | `progress_screen_test.dart` › "AC5: sin registros en el periodo → mensaje…" y "AC5: sin meta → sin días en meta ni línea de meta" |
| AC6 | `progress_screen_test.dart` › "AC6: cada barra lleva su valor como etiqueta semántica" (y las de semana en AC4) |

Además: texto ×2 en 360 px sin desbordes. Manual: recorrido en el teléfono pendiente (usuaria).

## Change Log
- 2026-10-03: creación a partir de T-015 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.
- 2026-10-03: implementada (autorización única de la usuaria para el lote, incluidas las Strict).
  Detalles menores:
  - `nutrition_core`: `LoggedDay`, `dailyAverage`, `daysOnGoal`, `summarizePeriod`,
    `weeklyAverages` y `mondayOf` (por fecha de calendario).
  - "Mes" y "3 meses" muestran todas las semanas desde la que contiene el primer día del periodo
    hasta la de hoy (5 y 13 barras); una semana sin registros va como barra vacía, igual que un día
    sin registros en "Semana".
  - Color de cada barra: estado de SPEC-011 de su valor (día o promedio semanal) frente a la meta;
    sin meta, el acento. La altura es solo escala de dibujo (valor / máximo del gráfico).
  - "~" en el promedio con la regla de Hoy (alguna comida del periodo que no es "Alta precisión").
  - Debajo del promedio: "Sobre N días con registros", para que se entienda la regla de R2.
  - En "3 meses" las etiquetas de las barras se muestran una sí y una no (13 barras en 360 px).
  Status → Review.
- 2026-10-03: reviewer **PASS** (commit 6817352; nutrition_core 83/83, app 225/225), sin BLOCKER ni
  MAJOR. MINOR atendidos antes de fusionar:
  - `mealsBetween` ya no hace una consulta de ítems por comida: los carga en lote (tandas de 500),
    con test de que cada ítem queda en su comida y en orden;
  - "N de M días en meta" solo se muestra si hay número (no "null de…");
  - evidencia de AC1 aclarada (la exclusión del día vacío se prueba en la app);
  - línea en blanco antes de "Progreso" en `docs/architecture.md`.
  Fusionada en `develop` por la autorización única de la usuaria (incluidas las Strict). Sigue en
  Review hasta el recorrido manual en el teléfono.

## Review
Informe del reviewer (2026-10-03, commit 6817352): **PASS**. AC1–AC6 con evidencia
(`period_summary_test.dart`, `progress_screen_test.dart`); promedios y días en meta en
`nutrition_core`, suma sin redondear y redondeo al presentar; sin datos nuevos fuera del
dispositivo; accesibilidad del gráfico correcta. MINOR atendidos (ver Change Log).
