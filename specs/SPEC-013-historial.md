# SPEC-013: Historial (calendario)

## Status
Review
Path: Standard → tratada como Strict al implementar: añade a `nutrition_core` el "% de tu meta"
(`GoalProgress.ratio` y `presentPercent`, con casos de referencia). La regla de estado de SPEC-011 no cambia.

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

## Evidencia
| AC | Evidencia |
|----|-----------|
| AC1 | `app/test/features/history/history_screen_test.dart` › "AC1: días con su color de estado, sin color sin registros y futuros sin acción" |
| AC2 | mismo archivo › "AC2: tocar el 26 muestra fecha, % de la meta, kcal y totales por tipo de comida" (también 116 % el 28); `packages/nutrition_core/test/goal_progress_test.dart` › "ratio y presentPercent (SPEC-013 R3)" |
| AC3 | mismo archivo › "AC3: \"Mes anterior\" muestra agosto con sus registros; \"Mes siguiente\" deshabilitado en el mes actual" |
| AC4 | mismo archivo › "AC4: sin meta, un solo color neutro y sin porcentaje" |
| AC5 | mismo archivo › "AC5: desde la semana de \"Hoy\", tocar un día abre el Historial en ese día" (app completa con `MyApp`) |

Edge cases: grilla desde el lunes, error de lectura con Reintentar, texto ×2 en 360 px; la nota
"Comparado con tu meta actual" en AC1. Manual: recorrido en el teléfono pendiente (usuaria).

## Change Log
- 2026-10-03: creación a partir de T-014 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.
- 2026-10-03: implementada (autorización única de la usuaria para el lote). Detalles menores:
  - "% de tu meta" en `nutrition_core` (`GoalProgress.ratio` sin tope + `presentPercent`, half-up),
    para no calcular en la pantalla (invariante 3); por eso se trató como Strict.
  - Celdas: anillo de 2 px en el color del estado con relleno suave del mismo color (16 %); sin meta,
    relleno `surface` y borde gris; el día elegido lleva un fondo `navSelected`.
  - Al cambiar de mes se deselecciona el día ("Toca un día para ver qué comiste."), salvo al volver
    al mes actual, que selecciona hoy. Un día sin registros muestra "Sin registros este día.".
  - Totales por tipo de comida: siempre los cuatro, con "0 kcal" si no hubo; "~" en las kcal con la
    misma regla de Hoy (alguna comida que no es "Alta precisión").
  - Tocar un día de la semana de Hoy (también hoy) abre el Historial como pestaña, con ese día.
  - La tarjeta de comida de Hoy pasó a `ui/components/meal_card.dart` para compartirla.
  - T-021 (Fast Path) resuelto aquí: la barra inferior se desbordaba con texto grande en el
    Historial; la pastilla ahora cede espacio y la etiqueta activa se reduce.
  Status → Review.
- 2026-10-03: reviewer CHANGES_REQUESTED (commit 038c9c9). Corregido:
  - [MAJOR] Los días del calendario y de la semana de Hoy se anunciaban como botón sin acción de
    tocar para TalkBack/VoiceOver: la acción va ahora en el propio nodo semántico del día. Tests:
    "accesibilidad: cada día del calendario expone la acción de tocar…" y "accesibilidad: un día de
    la semana de Hoy expone la acción y abre el Historial".
  - MINOR:
    - celda del calendario de 48 px de alto tocable (antes 42), con test;
    - la tarjeta del día muestra el estado en texto ("En tu meta"), así un "90 %" redondeado no
      se confunde con el color "Por debajo";
    - una comida sin tipo cuenta como snack en los totales, como en su tarjeta (test);
    - la suma por comida pasó a `MealWithItems.totals` y el texto de ítems a `MealCard`, compartidos
      por Hoy e Historial.
  - Aceptado sin cambio: si la pantalla queda abierta pasada la medianoche, "hoy" se actualiza al
    volver a abrir la pestaña.
- 2026-10-03: re-revisión del reviewer: **PASS** (commit 25efa94; nutrition_core 75/75, app 219/219).
  Fusionada en `develop` por la autorización única de la usuaria. Sigue en Review hasta el
  recorrido manual en el teléfono.

## Review
Re-revisión (2026-10-03, commit 25efa94): **PASS**. AC1–AC5 con evidencia en
`history_screen_test.dart` y `goal_progress_test.dart`; el MAJOR de accesibilidad (acción de tocar
en los días) y los MINOR quedaron resueltos (ver Change Log). Sin hallazgos nuevos; invariantes y
privacidad sin cambios.
