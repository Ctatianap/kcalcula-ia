# SPEC-013: Historial (calendario)

## Status
Draft
Path: Standard (lectura y presentación; usa la regla de estado de SPEC-011 sin cambiarla)

## Objective
Que la pestaña Historial muestre un calendario del mes con el estado de cada día frente a la meta y
el detalle del día que se elija.

## Context
Backlog T-014. Diseño: artboard "Historial (calendario)" del lienzo
https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD. Reemplaza el estado provisional de SPEC-010 R5.
Estados sin alarma (decisión 3) con la regla de SPEC-011 R3.

## User Story
Como persona que registra lo que come, quiero ver mis días anteriores en un calendario y revisar
qué comí cada día.

## Requirements
- R1. **Calendario mensual** (lunes a domingo), con el mes y el año en es-CO ("septiembre 2026") y
  botones "Mes anterior" y "Mes siguiente". No se navega más allá del mes actual.
- R2. Cada día con registros muestra el color de su estado (SPEC-011 R3) frente a la meta vigente;
  los días sin registros, sin color; los días futuros, atenuados y sin acción. Leyenda: "En tu meta",
  "Por debajo", "Por encima".
- R3. **Día seleccionado** (por defecto hoy, o el día que llega desde la semana de "Hoy"): tarjeta con
  la fecha ("sábado 26 de septiembre"), "% de tu meta", "1.538 de 1.640 kcal" y el total por tipo de
  comida (Desayuno, Almuerzo, Cena, Snack), con la lista de comidas del día (como las tarjetas de
  SPEC-011 R6).
- R4. Sin meta: el calendario marca los días con registros con un solo color neutro y la tarjeta
  muestra las kcal sin "% de tu meta".
- R5. Lectura con `mealsBetween` (SPEC-011) por mes, sin cargar todo el diario.

## Acceptance Criteria
- AC1. Con comidas el 26 (1.538 de 1.640, en tu meta) y el 28 (1.900, por encima), esos días llevan
  sus colores; el 27, sin registros, va sin color; los días futuros no se pueden tocar `[widget]`.
- AC2. Tocar el 26 muestra "sábado 26 de septiembre", "94 % de tu meta", "1.538 de 1.640 kcal" y los
  totales por tipo de comida `[widget]`.
- AC3. "Mes anterior" muestra agosto con sus registros; "Mes siguiente" está deshabilitado en el mes
  actual `[widget]`.
- AC4. Sin meta → un solo color neutro y sin porcentaje `[widget]`.
- AC5. Desde la semana de "Hoy", tocar un día abre el Historial en ese día `[integration]`.

## Technical Constraints
- Invariante 3: el estado sale de `nutrition_core` (SPEC-011); la pantalla solo presenta.
- Sistema visual de SPEC-010; estados sin rojo ni verde.

## Components / Files Affected
- `app/lib/features/history/` (reemplaza el provisional de SPEC-010).
- `app/lib/features/diary/` (enlace desde la semana).

## Dependencies
- SPEC-010, SPEC-011.

## Edge Cases
- Meses con 28 a 31 días y semanas que empiezan en domingo: la grilla siempre empieza en lunes.
- La meta cambió con el tiempo: todos los días se comparan con la meta vigente (limitación de
  SPEC-008, sin historial de metas), con una nota pequeña "Comparado con tu meta actual".
- Error de lectura: mensaje y "Reintentar" (SPEC-009).

## Security & Privacy
- No sale ningún dato nuevo del dispositivo.

## Tests Required
- Widget: AC1–AC4. Integration: AC5. Manual: recorrido en el teléfono.

## Out of Scope
- Editar o borrar comidas desde el Historial, historial de metas, búsqueda en el historial.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC5 con evidencia; analyze y tests verdes; reviewer PASS; recorrido manual.

## Change Log
- 2026-10-03: creación a partir de T-014 y del diseño "kcalcula ia UI".

## Review
Informe del reviewer: pendiente.
