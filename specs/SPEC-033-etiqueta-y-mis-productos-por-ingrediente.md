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
- R4. **Elegir de mis productos.** Abre la búsqueda de SPEC-018 mostrando **solo productos
  personales** (todos, ordenados por nombre, sin escribir nada; filtra al escribir). Al elegir uno,
  el ingrediente cambia a ese producto con la cantidad de R3. Sin productos guardados: "Aún no tienes
  productos guardados. Usa la etiqueta de un ingrediente para guardar el primero."
- R5. **Cantidad en porciones por ingrediente.** Un ingrediente con producto personal muestra su
  cantidad con el selector **porciones / g (ml)** de SPEC-032 en lugar de solo −/+ en gramos. Cambiarla
  recalcula ese ingrediente y el total localmente.
- R6. **Sin IA de más.** "Elegir de mis productos" no llama a ninguna función de IA. "Usar etiqueta"
  hace exactamente una llamada a `extractLabel` por foto. Ninguna acción vuelve a llamar a
  `parseMeal`.
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

## Review
Informe del reviewer:
