# SPEC-034: Mis productos

## Status
Done
Path: Strict (cambia la resolución de alimentos: los productos personales y sus nombres
alternativos tienen prioridad al reconocer el texto; skill `nutrition-data`). Migración de `user.db`.

## Objective
Que la persona pueda ver, renombrar y borrar sus productos guardados, darles los nombres con que los
llama ("mi pan", "pan tajado") y que la app los reconozca solos al escribir o dictar, sin preguntar.

## Context
Backlog T-034. La usuaria (2026-10-07), después de SPEC-033: "solo me falta poder editar […] sobre
todo nombres" → opción 1: el nombre de sus productos guardados.

Hoy (SPEC-004, SPEC-018, SPEC-033):
- Los productos personales viven en `user.db` (`personal_products`) y no se pueden editar ni borrar.
- El nombre lo pone la IA al leer la etiqueta o, si no lo leyó, el ingrediente (por ejemplo "caldo de
  costilla").
- Al reconocer el texto, `FoodQueryResolver.resolve` busca productos cuyo nombre **contiene** la
  consulta. Si además el catálogo tiene una coincidencia exacta, pregunta cuál (ambiguo). Por eso
  "pan" no lleva directo al pan de la persona.
- No se guarda si la porción es en g o en ml: la leche se muestra en g (limitación conocida de
  SPEC-033).
- Cada comida guardada conserva una copia del nombre y de los valores de cada ingrediente
  (`meal_items.name_snapshot`, kcal y macros): renombrar o borrar un producto no cambia lo ya
  registrado.

## User Story
Como persona que siempre usa el mismo pan y la misma leche, quiero ponerles el nombre con que los
llamo y que la app los reconozca cuando digo "mi pan" o "mi leche", para no elegirlos cada vez.

## Requirements
- R1. **Pantalla "Mis productos"** desde Ajustes: la lista de productos (nombre, porción con su
  unidad, kcal por porción), ordenada por nombre, con buscador. Tocar uno abre "Editar producto".
  Sin productos: el mensaje de SPEC-033 R4.
- R2. **Editar producto:**
  - **Nombre** (obligatorio, no vacío).
  - **Unidad de la porción:** g o ml.
  - **Nombres alternativos** ("Así lo llamas"): agregar y quitar, hasta 10, por ejemplo "mi pan",
    "pan tajado". Sin vacíos ni repetidos (comparados con `normalizeFoodText`).
  - Guardar aplica los cambios. Los valores nutricionales y la porción no se editan aquí.
- R3. **Borrar producto** con confirmación ("¿Borrar «Pan tajado»? Las comidas que ya registraste no
  cambian."). Borra también sus nombres alternativos. Las comidas guardadas no cambian; las Recientes
  que lo usaban dejan de mostrarse (SPEC-017 R4).
- R4. **Prioridad al reconocer** (`FoodQueryResolver.resolve`): si la consulta, normalizada, es
  **igual** al nombre o a un nombre alternativo de **un solo** producto personal → `matched` con ese
  producto, aunque el catálogo también tenga coincidencia. Si es igual en dos o más productos →
  `ambiguous` entre ellos. Si no hay igualdad exacta, la regla de hoy no cambia (contiene y
  desambiguación con el catálogo).
- R5. **Unidad guardada:** columna nueva `serving_unit` ("g" o "ml") en `personal_products`. Al guardar
  desde "Confirmar etiqueta" se guarda la unidad de la etiqueta. Los productos que ya existen quedan en
  "g". El Detalle (SPEC-033 R5), "Mis productos" y "Elegir de mis productos" muestran la unidad
  guardada ("200 ml").
- R6. **Migración** de `user.db` a la versión 8: tabla `personal_product_aliases` (producto, término) y
  la columna de R5, sin perder datos. "Borrar todos mis datos" borra los alias; "Exportar" (JSON)
  incluye la unidad y los alias de cada producto.
- R7. Todo es local: ninguna acción de esta SPEC llama a la IA ni sale del dispositivo.

## Acceptance Criteria
- AC1. Con "Pan" guardado: en "Mis productos", cambiar el nombre a "Pan tajado integral" y guardar → la
  lista y "Elegir de mis productos" muestran el nuevo nombre; una comida registrada antes con "Pan"
  sigue mostrando "Pan" `[widget + integration]`.
- AC2. Agregar el alias "mi pan" a "Pan tajado integral" → registrar "mi pan y un café" (parseMeal
  fake con `food_query` "mi pan") → el ingrediente queda `matched` con el producto, sin pedir elegir
  `[unit + widget]`.
- AC3. El catálogo tiene "Pan" (coincidencia exacta) y la persona tiene un producto llamado "Pan" →
  `resolve("pan")` da `matched` con el producto personal (antes: ambiguo) `[unit]`.
- AC4. Dos productos con el alias "pan" → `resolve("pan")` da `ambiguous` con los dos `[unit]`.
- AC5. Sin igualdad exacta ("pan integral" con un producto "Pan tajado"): el resultado es el mismo que
  antes de esta SPEC (tests de resolución existentes sin cambios) `[unit]`.
- AC6. Borrar un producto con confirmación → desaparece de la lista y de "Elegir de mis productos"; sus
  alias se borran; la comida registrada con él sigue igual `[widget + integration]`.
- AC7. Una etiqueta de 200 ml guardada desde "Confirmar etiqueta" → `serving_unit` "ml"; el Detalle
  muestra "1 porción · 200 ml" y "Mis productos" "1 porción = 200 ml" `[widget]`.
- AC8. Migrar una base v7 con productos → v8 conserva todo, `serving_unit` = "g" y sin alias; "Borrar
  todos mis datos" vacía los alias; "Exportar" incluye unidad y alias `[integration]`.
- AC9. Validación: nombre vacío, alias vacío, repetido o número 11 → mensaje en español y no se guarda
  `[widget]`.
- AC10. Los tests existentes de resolución, búsqueda, revisión, etiquetas, exportar y borrar siguen
  verdes; los que cambian de expectativa (el caso de AC3) se listan en la Verificación `[unit + widget
  + integration]`.

## Technical Constraints
- Invariante 8: no se tocan `catalog.db` ni `data/`; los alias son de la persona, en `user.db`.
- Invariante 1: no cambia `parse_meal.v1` (la IA no conoce los alias; se aplican al resolver
  `food_query` en el dispositivo).
- Invariante 3: los cálculos siguen en `nutrition_core`.
- La UI no llama a Drift directamente: pasa por `infra/storage`.
- Normalización de nombres y alias con `normalizeFoodText` (SPEC-020/028).

## Components / Files Affected
- `app/lib/infra/storage/` (`app_database.dart` v8, `storage_repository.dart`: renombrar, unidad,
  alias, borrar, exportar, borrar todo).
- `app/lib/infra/food_resolution/food_query_resolver.dart` (R4) y `personalProductToFoodCatalogEntry`.
- `app/lib/features/settings/` (entrada "Mis productos") y una pantalla nueva para la lista y la
  edición.
- `app/lib/features/review/` (unidad en el Detalle y en "Elegir de mis productos").
- `app/lib/features/capture/label_confirmation_controller.dart` (guardar la unidad).
- `docs/privacy.md` (inventario: alias de productos en `user.db`, se exportan y se borran).
- Tests de esas carpetas.

## Dependencies
- SPEC-004, SPEC-006 (exportar y borrar), SPEC-017 (Recientes), SPEC-018, SPEC-020/028
  (normalización), SPEC-033.

## Edge Cases
- Un alias igual al nombre de otro producto: R4 lo trata como dos coincidencias exactas → ambiguo.
- Un alias igual a un alimento del catálogo ("arroz"): gana el producto personal (R4). Es lo que la
  persona eligió; se avisa al guardar el alias: "Cuando digas «arroz» usaremos este producto."
- Renombrar a un nombre que ya tiene otro producto: se permite (como hoy al guardar), y R4 los
  desambigua.
- Borrar un producto que está en el Detalle abierto en otra pantalla: no aplica (se edita desde
  Ajustes, fuera de un registro en curso).
- Mayúsculas, tildes y espacios: se comparan normalizados.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No. Se guarda un dato nuevo en el dispositivo (los alias y
  la unidad): se actualiza `docs/privacy.md` (inventario, exportar y borrar).

## Tests Required
- Unit: AC2–AC5 (resolver), AC8 (migración y repositorio).
- Widget: AC1, AC6, AC7, AC9.
- Integration: AC1, AC6, AC8, AC10.
- Manual: renombrar el pan, darle "mi pan" y registrar "mi pan" en el teléfono.

## Out of Scope
- Editar los valores nutricionales o la porción de un producto (se borra y se vuelve a guardar).
- Unir productos duplicados.
- Que la IA conozca los alias (no cambia el prompt).
- Editar comidas ya registradas (SPEC-026).

## Open Questions
- Ninguna. Decisiones tomadas: el nombre exacto o el alias gana sobre el catálogo (R4); hasta 10
  alias por producto; los valores no se editan aquí.

## Definition of Done
- AC1–AC10 con evidencia · analyze y tests verdes en `app` · `docs/privacy.md` actualizado · prueba
  manual · reviewer PASS enlazado · aprobación de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-07: creación a pedido de la usuaria ("sí, la opción 1 […] redacta la SPEC-034"). Backlog
  T-034.
- 2026-10-07: **Approved por la usuaria** ("aprobada la SPEC-034"). Status → Implementing.
- 2026-10-07: reviewer PASS; 7 MINOR corregidos y 1 al backlog (T-036). 395/395. Falta la prueba manual
  y la aprobación de la usuaria para fusionar (Strict).
- 2026-10-07: prueba manual de la usuaria y **aprobación para fusionar** ("ya lo probé, funciona, fusiona la
  034"). Status → Done.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | Widget: `app/test/features/settings/my_products_screen_test.dart` › "AC1: renombrar…" (lista) y "AC1: \"Elegir de mis productos\" muestra el nombre nuevo". Integración: `app/test/infra/storage/personal_products_storage_test.dart` › "SPEC-034 AC1/AC6 (integración)…" (la comida registrada sigue con "Pan") |
| AC2 | ✅ | Unit: `app/test/infra/food_resolution/personal_product_priority_test.dart` › "AC2…" ("Mi Pan" → matched). Widget: `app/test/features/review/ingredient_actions_test.dart` › "SPEC-034 AC2…" (el Detalle muestra el producto, sin "¿Cuál de estos?") |
| AC3 | ✅ | `personal_product_priority_test.dart` › "AC3…". Usa "Arepa" (el catálogo de fixtures no tiene "Pan"): mismo caso, coincidencia exacta en catálogo y producto con el mismo nombre → matched con el producto |
| AC4 | ✅ | mismo archivo › "AC4…" |
| AC5 | ✅ | mismo archivo › "AC5…" (mismo resultado con y sin alias para consultas sin igualdad exacta) y la suite de resolución existente sin cambios |
| AC6 | ✅ | Widget: `my_products_screen_test.dart` › "AC6: borrar con confirmación…" y "AC6: \"Cancelar\" no borra". Integración: "SPEC-034 AC1/AC6 (integración)…" (alias borrados, la comida sigue igual) |
| AC7 | ✅ | `ingredient_actions_test.dart` › "SPEC-034 AC7…": `serving_unit` "ml", Detalle "1 porción · 200 ml", "Ver en ml" y "Elegir de mis productos" "1 porción = 200,0 ml · 90 kcal". "Mis productos": `my_products_screen_test.dart` › "AC7…" ("1 porción = 200,0 ml · 90 kcal"; la porción se muestra con un decimal, `formatMacroEs`) |
| AC8 | ✅ | `personal_products_storage_test.dart` › "SPEC-034 AC8…": base v7 simulada (sin columna ni tabla) → v8 conserva el producto, "g", sin alias; exportar incluye unidad y alias; "Borrar todos mis datos" vacía los alias |
| AC9 | ✅ | `my_products_screen_test.dart` › "AC9: nombre vacío…", "AC9: alias vacío, repetido o número 11" (unit) y "AC9: alias repetido muestra el mensaje…" |
| AC10 | ✅ | app: analyze sin avisos, 395/395 (tras los MINOR del reviewer). Expectativas cambiadas: `weight_log_storage_test.dart` y `nutrition_goal_storage_test.dart` esperan `user_version` 8 (antes 7). `integration/storage_errors_test.dart` añade `servingUnit` a su `savePersonalProduct` falso (firma, no expectativa). Ningún test de resolución cambió |
| Manual | ✅ | 2026-10-07, la usuaria en su Motorola con la versión de `472214b` (migración v8 sobre sus datos reales sin pérdidas): "ya lo probé, funciona" |
- 2026-10-07: implementada.
  - `user.db` v8: `personal_products.serving_unit` y `personal_product_aliases`. La migración solo agrega
    lo que falte (comprueba la columna y la tabla), para no fallar con bases simuladas o ya creadas.
  - Repositorio: `getPersonalProductAliases`, `updatePersonalProduct`, `deletePersonalProduct`; "Borrar
    todo" y "Exportar" con alias y unidad.
  - `FoodQueryResolver`: igualdad exacta con nombre o alias gana (R4); `servingUnitOf`.
  - Pantallas "Mis productos" y "Editar producto" en Ajustes (`AppRoutes.myProducts`); unidad en el
    Detalle y en "Elegir de mis productos"; la etiqueta guarda su unidad.
  - `docs/privacy.md` actualizado (inventario).

## Review
Revisión (2026-10-07, subagente `reviewer`, sobre `b00b452`): **PASS**. AC1–AC10 con evidencia;
resolución, migración v8 (desde v1, v2–v7 y nueva), repositorio, privacidad y pantallas correctos;
invariantes 1, 3 y 8 respetadas. 8 MINOR:
- Aviso de alias que tapa el catálogo solo con `FoodMatched`: ahora con cualquier resultado distinto de
  `FoodNotFound`.
- Alias escrito sin tocar "+" se perdía al guardar: se agrega (o se avisa); test.
- "Buscar alimento" no busca por alias: fuera de R4; T-036 en el backlog.
- Mensaje de error al borrar: propio ("No pude borrar el producto…").
- AC7 sin test en "Mis productos": test con un producto en ml.
- Texto de "sin productos" duplicado entre features: `app/lib/ui/personal_products_texts.dart`.
- Comentario de versión desactualizado en `nutrition_goal_storage_test.dart`: corregido.
- Sin test de migración desde v1: test nuevo en `personal_products_storage_test.dart`.
