# SPEC-011: Rediseño de "Hoy"

## Status
Done
Path: Strict (agrega a `packages/nutrition_core` la regla del estado del día frente a la meta)

## Objective
Que "Hoy" muestre de un vistazo cómo va el día y la semana, como en el diseño: saludo, semana con
un anillo por día, anillo grande de kcal, anillos de macros y tarjetas por comida.

## Context
Backlog T-012. Diseño: artboards "Hoy · vacío" y "Hoy · con registros" del lienzo
https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD. Decisiones del rediseño en `docs/backlog.md`:
(3) estados sin rojo ni verde de alarma, (5) sin sugerencias de alimentos ("Un par de huevos…").
Reutiliza el progreso de SPEC-008 (`GoalProgress`) y el sistema visual de SPEC-010.

## User Story
Como persona que registra lo que come, quiero abrir la app y ver cuánto llevo hoy, cuánto me queda,
cómo voy en macros y cómo me fue los días anteriores de la semana.

## Requirements
- R1. **Encabezado:** saludo según la hora local ("Buenos días" de 5:00 a 11:59, "Buenas tardes" de
  12:00 a 18:59, "Buenas noches" el resto) y la fecha en es-CO ("sábado 3 de octubre"). A la
  derecha, el botón de Ajustes. La racha es SPEC-019.
- R2. **Semana:** fila de lunes a domingo de la semana actual. Cada día pasado con registros muestra
  un anillo con la fracción de kcal consumidas frente a la meta vigente, en el color de su estado
  (R3). Hoy va resaltado con el acento; los días futuros y los días sin registros, sin anillo. Tocar
  un día abre el Historial en ese día (SPEC-013); mientras no exista, no hace nada.
- R3. **Estado del día** (`nutrition_core`): con meta, "por debajo" si las kcal consumidas son menos
  del 90 % de la meta, "en tu meta" del 90 % al 110 % y "por encima" si superan el 110 %. **El 10 %
  de tolerancia es una decisión de producto**, documentada como tal. Los colores son los tokens
  `DayGoalStatus` de SPEC-010, nunca rojo o verde.
- R4. **Tarjeta de kcal:** número grande con lo consumido, "/meta" al lado y "kcal consumidas ·
  quedan N" o "· N por encima de la meta" (textos de SPEC-008). Anillo grande con la fracción. Lleva
  "~" si alguna comida del día es estimada (SPEC-008 R6).
- R5. **Macros:** tres tarjetas (Proteína, Carbohidratos, Grasa) con un anillo en el color de cada
  macro, los gramos consumidos al centro y "de X g" debajo.
- R6. **Comidas de hoy:** sección "Agregado hoy" con una tarjeta por comida: tipo de comida
  (Desayuno, Almuerzo, Cena o Snack), hora, resumen de ítems (nombre y cantidad), kcal y P/C/G. En
  orden por hora.
- R7. **Sin meta:** se muestran lo consumido y el enlace "Calcular mi meta" (SPEC-008 R11), sin
  anillos de meta.
- R8. **Vacío:** sin comidas hoy, ilustración y "Todavía no registras nada hoy" + "Toca + y cuéntame
  qué comiste: con una foto, por texto o con tu voz.".
- R9. Sin consejos ni sugerencias de alimentos (decisión 5).

## Acceptance Criteria
- AC1. Estado del día: con meta 2.000, consumo 1.799 → por debajo; 1.800 y 2.200 → en tu meta;
  2.201 → por encima; sin meta → sin estado `[unit, nutrition_core]`.
- AC2. Saludo: 05:00 → "Buenos días"; 12:00 → "Buenas tardes"; 19:00 y 04:59 → "Buenas noches".
  Fecha "sábado 3 de octubre" para el 2026-10-03 `[unit]`.
- AC3. Semana: con comidas el lunes (1.500 de 2.000) y el martes (2.300), el lunes muestra un anillo
  al 75 % con el color "por debajo", el martes uno lleno con "por encima", hoy va resaltado y los
  días futuros sin anillo `[widget]`.
- AC4. Tarjeta de kcal y macros con meta (2.000 kcal; 100/275/55,6 g) y 893 kcal consumidas: "893",
  "/2.000", "quedan 1.107"; los anillos de macros muestran los gramos y "de 100 g", etc. `[widget]`.
- AC5. Dos comidas (8:15 y 13:02) aparecen como tarjetas en ese orden, con tipo, hora, resumen, kcal
  y P/C/G `[widget]`.
- AC6. Sin meta → enlace "Calcular mi meta" y sin anillos de meta; sin comidas → estado vacío de R8
  `[widget]`.
- AC7. Ningún color de estado es rojo ni verde; cada estado lleva texto o etiqueta semántica
  `[revisión + widget]`.

## Technical Constraints
- Invariantes 3 (cálculo en `nutrition_core`, redondeo al presentar) y 4 de `CLAUDE.md`.
- Sistema visual de SPEC-010; sin colores sueltos en la pantalla.

## Components / Files Affected
- `packages/nutrition_core/lib/src/day_status.dart` (R3) y su test.
- `app/lib/features/diary/` (pantalla y controlador; lectura de la semana).
- `app/lib/infra/storage/storage_repository.dart`: `mealsBetween(start, end)`.

## Dependencies
- SPEC-010 (sistema visual y navegación), SPEC-008 (meta y progreso).

## Edge Cases
- La meta cambia durante la semana: todos los días se comparan con la meta **vigente** (no hay
  historial de metas, SPEC-008). Se documenta como limitación.
- Semana que cruza de mes: los números de día son los del calendario real.
- Muchas comidas en un día: la lista crece y la pantalla se desplaza; la barra inferior no tapa
  contenido.
- Texto grande del sistema: las etiquetas de macros pasan a dos líneas y el número del anillo se
  reduce para caber, sin cortarse (test con texto ×2).
- Sin meta, los días pasados con registros no llevan anillo (R7): un fondo suave indica que hubo
  registros y la etiqueta semántica dice "con registros".

## Security & Privacy
- No sale ningún dato nuevo del dispositivo.

## Tests Required
- Unit: AC1 (`nutrition_core`), AC2.
- Widget: AC3–AC7.
- Manual: recorrido en el teléfono con comidas reales.

## Out of Scope
- Racha (SPEC-019), Historial (SPEC-013), detalle o edición de una comida ya registrada,
  sugerencias de alimentos.

## Open Questions
- Ninguna. La tolerancia del 10 % (R3) es una decisión de producto y se puede ajustar al aprobar.

## Evidencia de Acceptance Criteria
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `packages/nutrition_core/test/day_status_test.dart` (1.799 / 1.800 / 2.200 / 2.201, sin meta, límites sin redondear) |
| AC2 | ✅ | `app/test/features/diary/diary_format_test.dart` |
| AC3 | ✅ | `app/test/features/diary/diary_screen_test.dart` ("AC3…": anillo del lunes al 75 % con color "por debajo", martes lleno "por encima", sin anillo en días sin registros y futuros, etiquetas semánticas por día) |
| AC4 | ✅ | `diary_screen_test.dart` ("AC4…" con meta —macros con 1 decimal: "de 55,6 g"— y "por encima de la meta", anillo lleno con el acento) |
| AC5 | ✅ | `diary_screen_test.dart` ("AC5…") |
| AC6 | ✅ | `diary_screen_test.dart` ("AC6…" sin meta —muestra "500"— y sin comidas; "sin meta: los días con registros no llevan anillo de meta") |
| AC7 | ✅ | Colores de estado = `DayGoalStatus` (sin rojo ni verde, test de SPEC-010); cada día lleva etiqueta semántica con su estado (AC3) |

Verificado (2026-10-03): `dart analyze` y `flutter analyze` sin issues; `nutrition_core` 71/71; app
184/184 (tras la revisión). Recorrido manual: al final del lote.

Decisiones de implementación:
- `clockProvider` (`app/lib/infra/clock.dart`) hace inyectable la hora actual para probar la semana.
- `mealsBetween` usa un intervalo semiabierto [inicio, fin) y ordena por hora; `mealsForDay` lo
  reutiliza. Antes, `isBetweenValues` incluía la medianoche del día siguiente.
- El diseño no tiene barra superior "Hoy": los tests que detectaban el diario por ese título ahora
  buscan `DiaryScreen`.
- Cada día de la semana es su propio nodo semántico (`container: true`): sin eso, el lector de
  pantalla fusionaba los siete.

## Definition of Done
- AC1–AC7 con evidencia; analyze y tests verdes (`nutrition_core` y app); reviewer PASS;
  recorrido manual; aprobación de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-03: creación a partir de T-012 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.

- 2026-10-03: implementada. Status → Review.

- 2026-10-03: reviewer CHANGES_REQUESTED. Corregido:
  - [BLOCKER] La evidencia de AC2 citaba un test que no existía (no se creó por un comando
    fallido): `diary_format_test.dart` creado con los límites del saludo.
  - [MAJOR] Los macros se presentaban en gramos enteros con `presentKcal`: ahora usan
    `formatMacroEs`, con 1 decimal, como dice `docs/architecture.md`.
  - [MAJOR] Con texto grande el número del anillo se salía: ahora usa `FittedBox` y la etiqueta
    admite dos líneas, con test ×2.
  - MINOR:
    - `Colors.white` → `KColors.background`;
    - evidencia de SPEC-008 actualizada; asserts de "500" sin meta y del anillo lleno por encima
      de la meta;
    - test de `mealsBetween` [inicio, fin) y del orden;
    - el lunes se calcula por fecha de calendario, con tests de hoy lunes, hoy domingo y cruce de
      mes;
    - sin meta, sin anillo (Edge Cases);
    - margen de coma flotante en `dayStatus`, con caso de meta no redonda.
- 2026-10-03: re-revisión del reviewer: **PASS** (commit a3aa3d7; nutrition_core 72/72, app
  184/184). Fusionada en `develop` por la autorización única de la usuaria ("todo está aprobado solo
  por esta vez", ver `docs/cloud-handoff.md`). Sigue en Review hasta el recorrido manual del lote.
- 2026-10-07: recorrido manual en el teléfono (Motorola edge 50 pro, Android 16, build debug de
  `develop` en `dc92f55`). La usuaria lo dio por bueno ("si ya creo que el resto esta bien").
  Status Review → Done.

## Review
Re-revisión (2026-10-03, commit a3aa3d7): **PASS**. AC1–AC7 cumplidos con evidencia en tests.
Hallazgos MINOR pendientes (no bloquean):
- `diary_screen.dart` (tarjetas de macros): "Carbohidratos" se parte a mitad de palabra con texto
  grande en 360 px; envolver la etiqueta en `FittedBox(scaleDown)`.
- `diary_screen_test.dart` "texto grande (×2)": fijar la vista en 360×800 para reproducir un teléfono
  angosto.
- `SPEC-008` AC8: la evidencia aún describe "0 / 1.456 kcal" y "4 barras"; actualizar a "/1.456" y
  4 `ProgressRing`.
- Fuera de alcance (SPEC-010): `main_nav_bar.dart` se desborda 29 px con escala de texto 3,0 en
  360 px; registrado en `docs/backlog.md`.
