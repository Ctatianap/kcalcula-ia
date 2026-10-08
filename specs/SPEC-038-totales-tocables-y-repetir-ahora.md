# SPEC-038: Totales por tipo que se pueden tocar y "Repetir ahora"

## Status
Done
Path: Standard (navegación y una acción más sobre comidas guardadas; reutiliza SPEC-026/037; no sale
ningún dato)

## Objective
Que en el Historial los totales por tipo de comida lleven a esas comidas, y que una comida de hoy se
pueda repetir (registrar otra vez) a la hora actual.

## Context
Pedido de la usuaria (2026-10-08) al probar SPEC-036 en el teléfono: "me sale en el historial pero no
puedo hacer nada con esos valores", "qué tal que quisiera repetirla". Las filas "Desayuno 345 kcal /
Almuerzo 0 kcal…" del detalle del día (SPEC-013) no hacen nada, y las tarjetas de las comidas quedan
más abajo, a veces tapadas por la barra inferior. "Repetir hoy" (SPEC-026 R4, SPEC-037) solo existe
para comidas de otros días.

## User Story
Como persona que mira su día en el Historial, quiero tocar "Desayuno 345 kcal" para llegar a ese
desayuno y poder repetirlo, aunque sea de hoy.

## Requirements
- R1. **Totales tocables (Historial, detalle del día):** una fila de tipo con comidas ("Desayuno 345
  kcal") se puede tocar:
  - con **una** comida de ese tipo → abre "Editar comida" con esa comida;
  - con **varias** → una hoja con esas comidas (hora, alimentos, kcal); tocar una abre "Editar comida".
  Las filas en 0 kcal no se pueden tocar. Las filas tocables muestran un ícono ">" para que se note.
- R2. **"Repetir ahora" para comidas de hoy:** en el menú del toque largo (SPEC-037) y en "Editar
  comida" (SPEC-026), una comida de **hoy** ofrece **"Repetir ahora"**: abre el Detalle con los mismos
  alimentos y cantidades (sin IA, como Recientes) y al guardar crea una comida nueva a la hora
  actual. Las de otros días siguen con "Repetir hoy".
- R3. Mismas reglas que "Repetir hoy": solo si todos los alimentos siguen existiendo, y en "Editar
  comida" se desactiva si hay cambios sin guardar.
- R4. Accesibilidad: las filas tocables se anuncian como botón ("Desayuno, 345 kcal. Toca para ver la
  comida").

## Acceptance Criteria
- AC1. Historial de un día con un desayuno → tocar "Desayuno" abre "Editar comida" con ese desayuno
  `[widget]`.
- AC2. Día con dos snacks → tocar "Snack" abre una hoja con los dos; tocar uno abre "Editar comida" con
  ese `[widget]`.
- AC3. "Almuerzo 0 kcal" no hace nada al tocarlo y no muestra ">" `[widget]`.
- AC4. En Hoy, toque largo en una comida de hoy → el menú tiene "Repetir ahora"; elegirlo y guardar
  crea una comida nueva a la hora actual con los mismos gramos; la original sigue igual `[widget +
  integration]`.
- AC5. "Editar comida" de una comida de hoy muestra "Repetir ahora" (desactivado si hay cambios sin
  guardar); la de otro día sigue mostrando "Repetir hoy" `[widget]`.
- AC6. Una comida de hoy con un alimento que ya no existe no ofrece "Repetir ahora" `[widget]`.
- AC7. Los tests existentes de Historial, SPEC-026 y SPEC-037 siguen verdes; los que cambien de
  expectativa (por ejemplo, "una comida de hoy no ofrece «Repetir hoy»") se listan en la Verificación
  `[widget + integration]`.

## Technical Constraints
- Sin imports entre features; la lógica compartida en `app/lib/ui/` (como SPEC-037) e `infra/`.
- Errores como SPEC-009.

## Components / Files Affected
- `app/lib/features/history/history_screen.dart` (filas tocables y hoja).
- `app/lib/ui/meal_actions_flow.dart`, `app/lib/ui/components/meal_actions.dart` (acción "Repetir
  ahora").
- `app/lib/features/review/review_screen.dart`, `meal_detail_view.dart` (botón en "Editar comida").
- `app/lib/features/diary/diary_screen.dart` (menú en Hoy).
- Tests de esas carpetas.

## Dependencies
- SPEC-013, SPEC-017, SPEC-026, SPEC-037.

## Edge Cases
- Repetir varias veces seguidas: cada vez crea una comida nueva (no se agrupan).
- Una comida de hoy registrada a las 23:59 y repetida pasada la medianoche: queda en el día nuevo
  (hora actual).
- La hoja de R1 con muchas comidas del mismo tipo: se desplaza.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No.

## Tests Required
- Widget: AC1–AC3, AC5, AC6. Integration: AC4, AC7.
- Manual: tocar los totales y repetir una comida de hoy en el teléfono.

## Out of Scope
- Hacer tocables los totales de Hoy (allí las tarjetas ya están a la vista).
- Repetir varias comidas a la vez.

## Open Questions
- Ninguna. Decisiones tomadas: "Repetir ahora" para hoy y "Repetir hoy" para otros días (para que el
  texto diga lo que pasa); con varias comidas del mismo tipo, una hoja para elegir.

## Definition of Done
- AC1–AC7 con evidencia · analyze y tests verdes en `app` · prueba manual · reviewer PASS enlazado.

## Change Log
- 2026-10-08: creación a pedido de la usuaria ("sí, redacta la SPEC con las dos").
- 2026-10-08: **Approved por la usuaria** ("aprobada la SPEC-038"). Status → Implementing.
- 2026-10-08: implementada. `_MealTypeRow` en el detalle del día de Historial (una comida → la abre;
  varias → hoja; 0 kcal → nada); `repeatLabelFor` ("Repetir ahora"/"Repetir hoy") en el menú de
  SPEC-037 y en "Editar comida"; `ReviewScreen` arma el borrador también para comidas de hoy.
- 2026-10-08: reviewer PASS; MINOR corregidos (ver Review). 451/451. Prueba manual hecha. Status →
  Review.
- 2026-10-08: **la usuaria aprueba fusionar y hacer push** ("sí, fusiona la 038 y haz push"). Status →
  Done.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/history/history_type_rows_test.dart` › "AC1…" |
| AC2 | ✅ | mismo archivo › "AC2: con dos snacks, una hoja para elegir" |
| AC3 | ✅ | mismo archivo › "AC3…" (sin fila tocable ni ">") |
| R4 | ✅ | mismo archivo › "R4: la fila se anuncia como botón" ("Desayuno, 300 kcal. Toca para ver la comida") |
| AC4 | ✅ | `app/test/features/diary/meal_long_press_test.dart` › "AC1 + SPEC-038 AC4…" (menú de Hoy con "Repetir ahora" → Detalle). Integración con `MyApp`: `app/test/integration/edit_meal_flow_test.dart` › "SPEC-038 AC4…" (guardar crea una comida nueva a las 12:00 con 100 g; la de las 8:30 sigue) |
| AC5 | ✅ | `app/test/features/review/edit_meal_test.dart` › "R4 + SPEC-038 AC5…" (hoy: "Repetir ahora", no "Repetir hoy") y "SPEC-038 AC5: \"Repetir ahora\" se desactiva con cambios sin guardar"; otro día sigue con "Repetir hoy" (tests de SPEC-026) |
| AC6 | ✅ | `meal_long_press_test.dart` › "SPEC-038 AC6…" |
| AC7 | ✅ | app: analyze sin avisos, 451/451. Expectativas cambiadas: `meal_long_press_test.dart` "AC1…" (antes: Hoy sin "Repetir"; ahora con "Repetir ahora") y `edit_meal_test.dart` "R4…" (antes: una comida de hoy sin repetir; ahora con "Repetir ahora"). Parámetro `canRepeatToday` → `canRepeat` + `mealIsToday` en el flujo compartido |
| Manual | ✅ | 2026-10-08, hecha por Claude en el Motorola de la usuaria (versión de `64b3483`), sin crear ni borrar datos: en Hoy, el toque largo del desayuno muestra "Editar comida · Repetir ahora · Eliminar comida" (se cerró sin elegir); en Historial (8 oct), "Desayuno 345 kcal" muestra ">", las filas en 0 kcal no; tocarla abre "Editar comida" con ese desayuno (se salió sin guardar) |

## Review
Revisión (2026-10-08, subagente `reviewer`, sobre `64b3483`): **PASS**. AC1–AC7 y R4 con evidencia;
la agrupación por tipo usa la misma regla que `byMealType`; ninguna comida de hoy muestra "Repetir
hoy"; sin imports entre features. 6 MINOR, corregidos salvo el último:
- Comentarios desactualizados sobre "Repetir hoy" (Historial, `MealDetailView`, flujo compartido,
  `ReviewScreen`): actualizados. Los identificadores `MealAction.repeatToday`/`onRepeatToday` se dejan.
- Historial con el día de hoy sin test de "Repetir ahora": test nuevo.
- Recarga del Historial al volver de "Editar comida" sin test: test nuevo.
- La integración no comprobaba los gramos de la comida original: agregado.
- `_today` fijo en `initState` (venía de antes): anotado, sin cambio.
