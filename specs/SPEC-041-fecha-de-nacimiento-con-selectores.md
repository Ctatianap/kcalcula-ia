# SPEC-041: Fecha de nacimiento con selectores de día, mes y año

## Status
Implementing
Path: Standard (solo cambia cómo se ingresa la fecha en "Mi perfil"; la edad y los cálculos siguen igual)

## Objective
Que la fecha de nacimiento se elija sin teclado, con tres selectores (día, mes y año), en cualquier
teléfono.

## Context
Hallazgo de la usuaria en su Samsung (2026-10-08): el campo "Fecha de nacimiento (dd/mm/aaaa)" de
"Mi perfil" (SPEC-008 R1) es de texto con `TextInputType.datetime`. En Samsung abre un teclado numérico
sin "/", así que no se puede escribir la fecha. Propuso un calendario o tres selectores; para no buscar
entre muchos años en un calendario, se eligen tres selectores.

## User Story
Como persona que configura su perfil, quiero escoger mi fecha de nacimiento tocando día, mes y año, para
no pelear con el teclado.

## Requirements
- R1. En "Mi perfil", la fecha de nacimiento son tres selectores en una fila: **Día** (1–31), **Mes**
  (enero…diciembre, por nombre) y **Año**. No hay campo de texto ni teclado.
- R2. Los años van del más reciente al más antiguo: desde el año actual − 18 hasta el año actual − 100
  (el rango de edad de SPEC-008 R1).
- R3. El selector de día solo ofrece los días que existen en el mes y año elegidos (29 de febrero solo en
  años bisiestos). Si al cambiar el mes o el año el día elegido deja de existir, el día queda sin
  elegir y se pide de nuevo; nunca se cambia por otro en silencio.
- R4. Con un perfil guardado, los tres selectores aparecen con su fecha. Debajo se sigue viendo la edad
  calculada ("35 años") cuando la fecha está completa.
- R5. Se mantienen las reglas de SPEC-008 R1: edad entre 18 y 100 años; si falta alguno de los tres o la
  edad queda fuera de rango, mensaje en español y no se guarda. Mensaje si falta algo: "Elige día, mes
  y año de nacimiento." El de rango no cambia.
- R6. El dato guardado no cambia (misma columna `birth_date`); sin migración.

## Acceptance Criteria
- AC1. Perfil vacío → elegir 15, marzo, 1990 → se ve "N años" (calculado con la fecha de hoy) y se
  guarda con `birthDate` = 1990-03-15 `[widget]`.
- AC2. Perfil guardado con 1990-03-15 → al abrir, los selectores muestran 15, marzo, 1990 `[widget]`.
- AC3. Elegir 31, marzo → cambiar a febrero → el día queda sin elegir y aparece el mensaje de R5 al
  intentar guardar; no se guarda `[widget]`.
- AC4. Febrero de 2000 ofrece el día 29; febrero de 1999, no `[unit o widget]`.
- AC5. La lista de años empieza en (año actual − 18) y termina en (año actual − 100) `[widget]`.
- AC6. No hay campo de texto para la fecha en "Mi perfil" `[widget]`.
- AC7. Los tests de SPEC-008/015 siguen verdes; los que escribían la fecha como texto pasan a usar los
  selectores sin cambiar lo que verifican `[widget]`.
- AC8. En el teléfono Samsung de la usuaria, elegir la fecha y guardar sin usar el teclado `[manual]`.

## Technical Constraints
- La edad sigue saliendo de `ageInYears` (`nutrition_core`).
- Nombres de los meses en español (es-CO), en minúscula como en el resto de la app.

## Components / Files Affected
- `app/lib/features/goals/profile_screen.dart` (selectores).
- `app/lib/features/goals/profile_controller.dart` (día, mes y año en vez del texto; validación).
- Tests: `app/test/features/goals/goals_flow_test.dart` y los que llenen el perfil.

## Dependencies
- SPEC-008, SPEC-015.

## Edge Cases
- Perfil guardado con una fecha cuyo año quedó fuera de la lista (la persona cumplió más de 100 años):
  el año se muestra igual y aparece el mensaje de rango al guardar.
- Texto grande (×2) en pantallas de 360 px: los tres selectores caben sin desbordar (pueden pasar a dos
  filas).
- Lector de pantalla: cada selector se anuncia como "Día", "Mes" y "Año".

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No.

## Tests Required
- Widget: AC1–AC3, AC5–AC7. Unit o widget: AC4. Manual: AC8.

## Out of Scope
- Calendario.
- Cambiar los rangos de edad, estatura o peso.
- Otros campos de "Mi perfil".

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC8 con evidencia · analyze y tests verdes en `app` · prueba manual · reviewer PASS enlazado.

## Change Log
- 2026-10-08: creación a partir del hallazgo de la usuaria en su Samsung.
- 2026-10-08: **Approved por la usuaria** ("aprobada"). Status → Implementing.
- 2026-10-08: implementada. Detalles menores: selectores `DropdownButton` dentro de `InputDecorator`
  (etiqueta "Día", "Mes", "Año"; menú de 320 px de alto); el botón "Guardar perfil" sigue
  desactivado mientras haya un error, como el resto del formulario (SPEC-008), y el mensaje de R5 se
  ve en cuanto falta uno de los tres. Sin fecha elegida no hay mensaje (como antes con el campo
  vacío). `goals_flow_test.dart` usa los selectores; el caso "17 años" elige el 31 de diciembre del
  año más reciente. 460/460.
- 2026-10-08: reviewer PASS condicionado solo a AC8 (manual). MINOR corregidos: `Semantics(label:)` en
  cada selector y test de "Día/Mes/Año" para el lector de pantalla; test de AC2 con 1990-03-15 dentro
  de cada selector; caso de 17 años en el controlador con fecha fija. 463/463.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/goals/profile_birth_date_test.dart` › "AC1…" |
| AC2 | ✅ | `profile_birth_date_test.dart` › "AC2: un perfil con 1990-03-15 abre con 15, marzo, 1990" |
| AC3 | ✅ | `profile_birth_date_test.dart` › "AC3…" y "R3: 31 de marzo → febrero…" |
| AC4 | ✅ | mismo archivo › "AC4…" |
| AC5 | ✅ | mismo archivo › "AC5: años…" (controlador) y "AC5 + AC6…" (pantalla) |
| AC6 | ✅ | mismo archivo › "AC5 + AC6…" |
| AC7 | ✅ | `goals_flow_test.dart` 23/23 con los selectores; app 463/463 |
| AC8 | ⏳ | Prueba manual en el Samsung de la usuaria, pendiente |

## Review
Revisión (2026-10-08, subagente `reviewer`, sobre `0a681fa`): **PASS condicionado a AC8** (manual); el
código no requiere cambios. AC1–AC7 con evidencia; la edad sale de `ageInYears` (`nutrition_core`);
sin migración; no quedan usos de las funciones quitadas. MINOR corregidos (ver Change Log).
