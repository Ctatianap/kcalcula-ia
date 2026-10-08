# SPEC-040: Añadir un ingrediente nuevo con su etiqueta

## Status
Done
Path: Standard (reutiliza el flujo de etiqueta de SPEC-033; no cambia prompts, esquemas, `nutrition_core`
ni lo que sale del dispositivo)

## Objective
Que "Añadir ingrediente" sirva también para un producto que no está en el catálogo ni en "Mis productos":
la persona lo agrega con la foto de su etiqueta o escribiendo sus valores.

## Context
Hallazgo de la usuaria en el S25 (2026-10-08): escanea una tabla nutricional, la comida queda con ese
producto y, al tocar "Añadir ingrediente" para sumar otro producto empacado, solo aparece "Buscar
alimento" (SPEC-018), que busca en el catálogo y en "Mis productos". Si no tiene nada guardado y el
producto no está en el catálogo, ve "No encontré ese alimento" y no tiene cómo seguir.

"Usar etiqueta" y "Escribir los valores" (SPEC-033 R2/R8) ya existen, pero solo para **reemplazar** un
ingrediente que ya está en la comida, no para añadir uno nuevo.

## User Story
Como persona que arma un snack con varios productos empacados, quiero añadir cada uno con su etiqueta,
aunque no lo haya guardado antes, para registrar la comida completa.

## Requirements
- R1. En "Buscar alimento", abierto desde "Añadir ingrediente", hay siempre un botón **"Añadir con
  etiqueta"** debajo del campo de búsqueda. Cuando no hay resultados, el mensaje dice:
  "No encontré ese alimento. Prueba con otro nombre o añádelo con su etiqueta."
- R2. "Añadir con etiqueta" abre el mismo flujo de SPEC-033 ("Etiqueta del ingrediente": tomar foto,
  elegir de la galería o "Escribir los valores"). El nombre sugerido es lo que la persona escribió en la
  búsqueda (vacío si no escribió nada).
- R3. Al guardar en "Confirmar etiqueta", el producto queda en "Mis productos" (como en SPEC-033) y se
  **añade** a la comida como un ingrediente nuevo, con la cantidad que la persona eligió allí. Los
  ingredientes que ya estaban no cambian.
- R4. Si la persona sale sin guardar, vuelve a "Buscar alimento" sin cambios.
- R5. La foto usa `extractLabel` igual que hoy (invariante 2: la IA transcribe, la persona confirma).
  "Escribir los valores" no usa IA.
- R6. Esta SPEC reemplaza SPEC-018 R5 ("sin sugerir crear uno") **solo** en "Buscar alimento" abierto
  desde "Añadir ingrediente". Desde el error de análisis (SPEC-018 R4) el mensaje y la pantalla no
  cambian: sin botón.

## Acceptance Criteria
- AC1. Sin productos guardados, buscar "galletas xyz" → se ve el mensaje de R1 y el botón "Añadir con
  etiqueta" `[widget]`.
- AC2. Comida con 1 ingrediente → "Añadir ingrediente" → "Añadir con etiqueta" → "Escribir los
  valores" → completar y guardar → la comida tiene 2 ingredientes; el primero no cambió y el nuevo
  tiene el nombre y la cantidad confirmados `[widget]`.
- AC3. El producto nuevo aparece en "Mis productos" `[widget o unit]`.
- AC4. Salir de "Etiqueta del ingrediente" sin guardar → se vuelve a "Buscar alimento" y la comida no
  cambia `[widget]`.
- AC5. "Usar etiqueta" sobre un ingrediente existente (SPEC-033) sigue reemplazándolo; tests existentes
  verdes sin cambiar expectativas, salvo el de SPEC-018 AC5 desde el Detalle, que pasa a esperar el
  mensaje de R1 (R6) `[unit + widget]`.
- AC6. En el teléfono: snack con una etiqueta escaneada + un segundo producto añadido con "Escribir los
  valores" → se guarda con ambos `[manual]`.

## Technical Constraints
- Invariantes 2 y 3: los valores de la etiqueta los confirma la persona; los cálculos, en `nutrition_core`.
- Las features no se importan entre sí: `review` abre la etiqueta por la ruta `AppRoutes.ingredientLabel`
  (como hoy en "Usar etiqueta").

## Components / Files Affected
- `app/lib/features/review/food_search_screen.dart` (botón y mensaje).
- `app/lib/features/review/meal_detail_view.dart` (`_addIngredient`: añadir el producto devuelto).
- `app/lib/features/review/review_controller.dart` (añadir un ítem desde un producto personal, si hace falta).
- Tests de widget de "Buscar alimento" y del Detalle.

## Dependencies
- SPEC-018, SPEC-033.

## Edge Cases
- Sin red al tomar la foto: el error actual de SPEC-033; "Escribir los valores" sigue disponible.
- Nombre igual a un producto ya guardado: se comporta como en SPEC-033 (se guarda otro producto).
- Búsqueda de menos de 2 letras: el botón igual se ve; el nombre sugerido queda vacío o con esa letra.
- "Buscar alimento" abierto desde otro lugar distinto de "Añadir ingrediente": hoy no existe; si se
  añade después, decide esa SPEC.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No. La foto de etiqueta ya sale por `extractLabel`
  (SPEC-003/033, `docs/privacy.md`); no cambia qué se envía.

## Tests Required
- Widget: AC1, AC2, AC4. Unit o widget: AC3. Regresión: AC5. Manual: AC6.

## Out of Scope
- Cambiar "Buscar alimento" fuera de este botón.
- Añadir varios productos de una sola foto.
- Cambios a prompts, esquemas o `nutrition_core`.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC6 con evidencia · analyze y tests verdes en `app` · prueba manual · reviewer PASS enlazado.

## Change Log
- 2026-10-08: creación a partir del hallazgo de la usuaria en el S25.
- 2026-10-08: **Approved por la usuaria** ("aprobada"). Status → Implementing.
- 2026-10-08: la implementación reveló que R1 contradice SPEC-018 R5 ("sin sugerir crear uno"), que
  tiene un test (`food_search_flow_test.dart` › AC5) desde el Detalle. Se añade R6 y se ajusta AC5.
  Status → Draft hasta nueva aprobación.
- 2026-10-08: **Approved por la usuaria** el cambio (R6, AC5) ("si"). Status → Implementing.
- 2026-10-08: implementada (`FoodSearchPick`, `pickIngredient`, `addLabelProduct`). 455/455. Instalada en
  el S25 de la usuaria para la prueba manual.
- 2026-10-08: reviewer CHANGES_REQUESTED solo por AC6 manual pendiente; MINOR corregidos: mensaje propio
  al fallar el añadido ("Búscalo en «Añadir ingrediente»"), `addLabelProduct` devuelve `bool` y ya no
  falla en silencio, lectura del producto compartida con "Usar etiqueta", test del caso sin cantidad.
  456/456.
- 2026-10-08: la usuaria pidió fusionar a `develop` ("fusiona todo") antes de la prueba manual. Status →
  Review: AC6 sigue pendiente; pasa a Done cuando la usuaria lo pruebe en su S25.
- 2026-10-08: prueba manual (AC6) hecha por la usuaria en su S25: "quedó perfecto". Con el reviewer sin
  BLOCKER ni MAJOR y los MINOR corregidos, el único motivo de CHANGES_REQUESTED queda resuelto.
  Status → Done.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/review/add_ingredient_with_label_test.dart` › "AC1…" |
| AC2 | ✅ | mismo archivo › "AC2 + AC3…" (el primero sin cambios; el nuevo "1 porción · 30 g") |
| AC3 | ✅ | mismo test (una fila en `personal_products` con el nombre buscado) |
| AC4 | ✅ | mismo archivo › "AC4…" |
| AC5 | ✅ | `ingredient_actions_test.dart` sin cambios; `food_search_flow_test.dart` › AC5 según R6; "desde el error de análisis no muestra el botón" |
| AC6 | ✅ | 2026-10-08, en el S25 de la usuaria (versión de prueba con SPEC-040 + SPEC-041, `6c4a469`): etiqueta escaneada + segundo producto con "Añadir con etiqueta", guardado con ambos ("quedó perfecto") |

## Review
Revisión (2026-10-08, subagente `reviewer`, sobre `91f160c`): **CHANGES_REQUESTED** solo por AC6 manual
pendiente; sin BLOCKER ni MAJOR. AC1–AC5 con evidencia; invariantes 1–4, fronteras entre features y
privacidad correctas. MINOR corregidos (ver Change Log).
