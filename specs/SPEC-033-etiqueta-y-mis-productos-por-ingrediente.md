# SPEC-033: Etiqueta y mis productos por ingrediente

## Status
Implementing
Path: Standard (la persona elige a mano el alimento de un ingrediente, como en SPEC-018; reutiliza
`extractLabel` y las reglas de `nutrition_core` sin cambiarlas; no cambia prompts, esquemas ni
`catalog.db`)

## Objective
Que una comida completa dicha o escrita de una vez ("3 huevos fritos con 5 spray de esta mantequilla,
pan y medio, 3 lonchas de queso y un scoop de proteína en 250 ml de leche") pueda completarse en el
Detalle de comida usando, **por ingrediente**, la foto de su etiqueta o un producto ya guardado, y
con la cantidad en porciones o en g/ml.

## Context
Backlog T-033. Pedido de la usuaria (2026-10-07): registrar comidas más completas, con la etiqueta de
cada producto, y poder elegir un alimento guardado "para no consumir tanto token con análisis de las
mismas imágenes", porque "la leche que uso siempre es la misma, los panes los mismos".

Enfoque acordado con la usuaria ("sí, me sirve"): no se manda texto + varias fotos juntas a la IA.
Se analiza el texto como hoy (`parseMeal`) y, en el Detalle, cada ingrediente puede:
- **usar una etiqueta**: una foto → `extractLabel` → "Confirmar etiqueta" (SPEC-004, 030–032) → se
  guarda como producto personal y reemplaza el alimento de ese ingrediente;
- **elegir de mis productos**: un producto personal ya guardado, sin foto y sin IA.

Cada foto se lee una vez en la vida del producto; las siguientes veces se elige el producto. Lo que
ya existe: los productos personales en `user.db` (SPEC-004), la búsqueda manual que los incluye
(SPEC-018), `selectCandidate` en `ReviewController` (cambia el alimento de un ingrediente y recalcula
con la cantidad que dijo la persona), y la cantidad en porciones de SPEC-032.

SPEC-034 (después) cubrirá la pantalla "Mis productos", los nombres con que la persona llama a cada
producto y la prioridad de sus productos al reconocer el texto.

## User Story
Como persona que desayuna casi siempre con los mismos productos, quiero decir mi desayuno completo y
asignarle a cada ingrediente su etiqueta o mi producto guardado, para registrar valores exactos sin
volver a fotografiar todo cada día.

## Requirements
- R1. **Acciones por ingrediente.** En el Detalle de comida, cada ingrediente (encontrado, ambiguo o
  no encontrado) tiene un menú con **"Usar etiqueta"** y **"Elegir de mis productos"**, además de
  "Quitar".
- R2. **Usar etiqueta.** Abre la cámara o la galería (como la pestaña Foto), lee la etiqueta con
  `extractLabel` y abre "Confirmar etiqueta" con el nombre del ingrediente como nombre del producto si
  la IA no leyó uno. Al tocar el botón final ("Usar en este ingrediente"), se guarda el producto
  personal y la app **vuelve al mismo Detalle**, con ese ingrediente cambiado al producto nuevo. Los
  demás ingredientes, el tipo de comida y el texto no cambian.
- R3. **Cantidad del ingrediente.** Al cambiar a un producto personal, la cantidad se resuelve con las
  reglas de hoy (`resolveGrams` con la cantidad y unidad que dijo la persona). Si se pudo resolver
  (por ejemplo "250 ml", "2 porciones"), se usa. Si no (por ejemplo "1 scoop" sin porción "scoop"),
  se usa la cantidad elegida en "Confirmar etiqueta" (SPEC-032: porciones o g/ml) y el ingrediente
  queda destacado para revisar, como hoy.
- R4. **Elegir de mis productos.** Abre **"Mis productos"**, una pantalla con el estilo de "Buscar
  alimento" (SPEC-018) que muestra **solo productos personales** (todos, ordenados por nombre, sin
  escribir nada; filtra al escribir). La búsqueda de SPEC-018 no cambia. Al elegir uno,
  el ingrediente cambia a ese producto con la cantidad de R3. Sin productos guardados: "Aún no tienes
  productos guardados. Usa la etiqueta de un ingrediente para guardar el primero."
- R5. **Cantidad en porciones por ingrediente.** Un ingrediente con producto personal muestra su
  cantidad con el selector **porciones / g (ml)** de SPEC-032 en lugar de solo −/+ en gramos. Cambiarla
  recalcula ese ingrediente y el total localmente.
- R6. **Sin IA de más.** "Elegir de mis productos" no llama a ninguna función de IA. "Usar etiqueta"
  hace exactamente una llamada a `extractLabel` por foto. Ninguna acción vuelve a llamar a
  `parseMeal`.
- R8. **Escribir los valores a mano.** En "Usar etiqueta", además de "Tomar foto" y "Elegir de la
  galería", el botón **"Escribir los valores"** abre "Confirmar etiqueta" vacía (nombre = el del
  ingrediente) **sin llamar a la IA**. Se valida igual (porción obligatoria, Atwater ±20 %) y se
  guarda como producto personal con `source_ref` "Valores de la etiqueta escritos por el usuario el
  {fecha}".
- R7. **Navegación sin imports entre features.** El Detalle (feature `review`) abre la captura de
  etiqueta (feature `capture`) por ruta con nombre y recibe el resultado (el id del producto
  personal) al volver.

## Acceptance Criteria
- AC1. Detalle con "pan y medio" resuelto a un alimento del catálogo → "Usar etiqueta" → foto (fake)
  → "Confirmar etiqueta" → "Usar en este ingrediente" → vuelve al Detalle; ese ingrediente es el
  producto nuevo, los demás siguen igual y hay un producto personal más en `user.db` `[widget +
  integration]`.
- AC2. Con un producto guardado "Leche deslactosada" (porción 200 ml), "250 ml de leche" → "Elegir de
  mis productos" → "Leche deslactosada" → el ingrediente queda con 250 ml y sus kcal salen de
  `calculateItemNutrients` sobre ese producto; el `AiClient` falla el test si se llama `[widget]`.
- AC3. "1 scoop de proteína" → "Usar etiqueta" con porción 30 g y "1" porción en "Confirmar etiqueta"
  → el ingrediente queda con 30 g y destacado para revisar `[widget]`.
- AC4. Un ingrediente con producto personal: cambiar a "3" porciones (porción 27 g) → 81 g, y el total
  de la comida se recalcula `[widget]`.
- AC5. "Elegir de mis productos" sin productos guardados → el mensaje de R4 `[widget]`.
- AC6. Un ingrediente "No encontrado en la base" ("un caldo de costilla") también tiene las dos acciones
  y, al usar una etiqueta, pasa a encontrado `[widget]`.
- AC8. "Usar etiqueta" → "Escribir los valores" → completar porción 30 g, 120 kcal, P 24, C 3, G 1,5
  → "Usar en este ingrediente" → el ingrediente cambia al producto nuevo, `extractLabel` no se llama y
  el `source_ref` dice "escritos por el usuario" `[widget]`.
- AC7. Los tests existentes de revisión, búsqueda manual, captura y etiquetas siguen verdes; las
  expectativas que cambien (texto del botón final en "Confirmar etiqueta" cuando se abre desde un
  ingrediente) se listan en la Verificación `[widget + integration]`.

## Technical Constraints
- Invariante 1: la IA solo transcribe la etiqueta; no se cambia `parse_meal.v1` ni
  `label_extraction.v1`.
- Invariante 2: la etiqueta pasa por "Confirmar etiqueta" y la validación de `nutrition_core` antes de
  usarse; nada se guarda sin confirmación.
- Invariante 3: los cálculos (porciones → g, kcal y macros) los hace `nutrition_core`.
- Invariante 8: los productos se guardan como **productos personales** en `user.db`, no en
  `catalog.db`.
- Las features no se importan entre sí (R7). La UI pasa por `infra/` para Drift y Functions.

## Components / Files Affected
- `app/lib/features/review/` (`meal_detail_view.dart`, `review_controller.dart`, `food_search_screen.dart`).
- `app/lib/features/capture/` (captura y "Confirmar etiqueta" en modo "para un ingrediente").
- `app/lib/app_routes.dart` (ruta con resultado).
- `app/lib/infra/food_resolution/` (si hace falta exponer los productos personales a la búsqueda).
- Tests de esas carpetas e `app/test/integration/`.

## Dependencies
- SPEC-004 (etiquetas y productos personales), SPEC-012 (Detalle), SPEC-018 (búsqueda manual),
  SPEC-029 (Vertex), SPEC-030–032 ("Confirmar etiqueta").

## Edge Cases
- La persona cancela la cámara, la lectura falla o sale de "Confirmar etiqueta" sin guardar: vuelve
  al Detalle sin cambios.
- Sin red al usar una etiqueta: el mensaje de error de etiquetas que ya existe; el Detalle no cambia.
- El mismo producto se usa en dos ingredientes: cada uno con su cantidad.
- Ingrediente hijo de otro (`parentIndex`, por ejemplo "con queso"): las acciones funcionan igual.
- Un producto personal con el mismo nombre que uno ya guardado: se guarda otro (como hoy); SPEC-034
  verá cómo editarlos o borrarlos.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No: la foto va a `extractLabel` como en SPEC-004/029, y
  "Elegir de mis productos" no sale del teléfono. Menos fotos enviadas que hoy cuando se repiten
  productos.

## Tests Required
- Widget: AC1–AC6.
- Integration: AC1 (con `user.db` en memoria y `AiClient` fake), AC7.
- Manual: el desayuno del ejemplo en el teléfono, con dos etiquetas y un producto ya guardado.

## Known Limitations
- Los productos personales no guardan si son g o ml: un producto en ml (la leche) se muestra en g en
  el Detalle y en "Mis productos". Se resuelve en SPEC-034.
- Pasar de g a porciones para mostrar (`ReviewController.portionsOf`) es una división en la app, igual
  que en SPEC-032 (`label_confirmation_controller.dart`). Moverlas a `nutrition_core` es Strict: queda
  como T-035.

## Out of Scope
- Mandar texto y varias fotos juntas en una sola captura.
- Pantalla "Mis productos" para ver, editar o borrar; nombres alternativos; prioridad de los productos
  personales al reconocer el texto (SPEC-034).
- Comidas favoritas (SPEC-022).
- Porciones por ingrediente para alimentos del catálogo (aquí solo productos personales).

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC7 con evidencia · analyze y tests verdes en `app` · prueba manual · reviewer PASS enlazado.

## Change Log
- 2026-10-07: creación a pedido de la usuaria ("sí, me sirve, redacta la SPEC-033"). Backlog T-033.
- 2026-10-07: **Approved por la usuaria** ("aprobada la SPEC-033"). Status → Implementing.
- 2026-10-07: implementada.
  - Captura: `IngredientLabelScreen` con su propio controlador (autoDispose) y "Confirmar etiqueta" en
    modo ingrediente (`ingredientName`, botón "Usar en este ingrediente", devuelve
    `IngredientLabelResult` de `infra/food_resolution/`).
  - Revisión: `ReviewController.replaceFood` (R3: la cantidad dicha si se pudo resolver; si no, la de
    "Confirmar etiqueta"), `setPortions` vía `resolveGrams` con la unidad `porcion` (invariante 3),
    `setShowInGrams`; menú ⋮ por ingrediente; "Mis productos".
- 2026-10-07: la usuaria pide poder escribir los valores a mano en "Usar etiqueta" para ahorrar
  tokens ("quisiera también poder en 'usar etiqueta' agregar los valores manualmente"). Cambios
  propuestos: R8 y AC8 nuevos; R4 reescrito para la pantalla propia "Mis productos" (hallazgo del
  reviewer); sección Known Limitations (ml mostrados en g; g → porciones en la app, T-035). Status →
  Draft hasta que la usuaria apruebe.
- 2026-10-07: **la usuaria aprueba los cambios** ("aprobados los cambios de la SPEC-033"): R8, AC8, R4
  y Known Limitations. Status → Implementing.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/review/ingredient_actions_test.dart` › "AC1…": "Usar etiqueta" → "Tomar foto" (fake) → "Usar en este ingrediente" → vuelve al Detalle; "Arepa" pasa a "Pan de prueba", los huevos siguen en 100 g, hay 1 producto personal en `user.db`, 1 llamada a `extractLabel` y 0 a `parseMeal`. Integración: `app/test/integration/ingredient_label_route_test.dart` (la ruta `AppRoutes.ingredientLabel` de `MyApp` abre `IngredientLabelScreen`) |
| AC2 | ✅ | mismo archivo › "AC2…": "Leche deslactosada" (porción 200 ml) con "250 ml" → el ingrediente muestra 250 g (densidad desconocida = 1, como hoy) y 113 kcal (45 × 2,5); 0 llamadas a la IA |
| AC3 | ✅ | mismo archivo › "AC3…": "1 scoop" (unidad sin porción "unidad") con "2" porciones en "Confirmar etiqueta" → "2 porciones · 60 g" (no la porción por defecto), destacado. Además: "R3: sin cantidad dicha…" (3 porciones → 81 g) |
| AC4 | ✅ | mismo archivo › "AC4…": "Pan tajado" 27 g → 4 × "+" (media porción) → "3 porciones · 81 g" y 210 kcal; "Ver en g" → "81 g" |
| AC5 | ✅ | mismo archivo › "AC5…" |
| AC6 | ✅ | mismo archivo › "AC6…": "No encontrado en la base" → con etiqueta sin nombre leído, el producto se llama "caldo de costilla" (R2) y queda "1 porción · 300 g" |
| AC7 | ✅ | app: analyze sin avisos, 370/370 (tras los hallazgos del reviewer). Expectativa cambiada: `review_screen_test.dart` › "AC8: editar la cantidad con +/-…" ahora hace `ensureVisible` antes de tocar "+" (el menú hace la tarjeta más alta; mismos valores esperados). El botón "Revisar comida" no cambia fuera del modo ingrediente |
| Manual | ⏳ | El desayuno del ejemplo en el teléfono |

Nota de implementación (R4): "Elegir de mis productos" abre una pantalla propia, "Mis productos"
(`personal_product_picker_screen.dart`), con el mismo estilo que "Buscar alimento" (SPEC-018), en vez de
reutilizar esa búsqueda: así lista todos los productos sin escribir y no cambia el comportamiento de
SPEC-018.

## Review
Revisión (2026-10-07, subagente `reviewer`, sobre `e00c44e`): **CHANGES_REQUESTED**.
- [MAJOR] Salir de la etiqueta mientras se lee la foto: con el provider autoDispose, `state = …`
  lanzaba `UnmountedRefException`, que llegaría a Crashlytics como fatal. Corregido: `if
  (!ref.mounted) return;` tras cada `await` en `LabelCaptureController._capture`; test "caso borde:
  salir mientras se lee la etiqueta…" (falla sin el arreglo).
- MINOR corregidos: error propio `_ingredientError` que se limpia con la siguiente acción y apunta a
  "Elegir de mis productos"; `getPersonalProductById` en vez de cargar todos; "1 porción" comparando el
  texto mostrado; "+"/"−" a la media porción siguiente (test R5); tooltip "Más opciones de {nombre}";
  AC2 comprueba 250 g; AC3 usa 2 porciones para distinguir la cantidad de "Confirmar etiqueta" y hay un
  caso sin cantidad dicha.
- MINOR pendientes de la usuaria (propuestos en el Change Log): texto de R4 ("Mis productos" propia),
  productos en ml mostrados en g (limitación conocida), g → porciones fuera de `nutrition_core`.
