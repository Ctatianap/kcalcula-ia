# SPEC-018: Búsqueda manual en el catálogo

## Status
Review
Path: Standard (búsqueda de solo lectura en el catálogo existente; la cantidad se resuelve con las
reglas actuales de `nutrition_core`, sin cambiarlas)

## Objective
Que la persona pueda buscar alimentos en la base verificada y añadirlos a su comida sin pasar por la
IA, cuando la IA falla o le falta un ingrediente.

## Context
Backlog T-019. Diseño: botón "Buscar en la base manualmente" del artboard "Error de la IA" y enlace
"Añadir" de "Detalle de comida" (lienzo https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD). El catálogo
ya tiene búsqueda de texto completo (FTS5) usada por `CatalogRepository.resolve`, que devuelve hasta 3
candidatos.

## User Story
Como persona que registra lo que come, quiero buscar un alimento por su nombre y añadirlo con su
cantidad, aunque la IA no me entienda.

## Requirements
- R1. **Pantalla "Buscar alimento"**: campo de búsqueda con resultados mientras se escribe (desde 2
  letras), hasta 20, con el nombre y "kcal por 100 g". Incluye los productos personales (SPEC-004).
  Usa los sinónimos del catálogo (por ejemplo, "tinto" encuentra café).
- R2. **Elegir cantidad**: al tocar un alimento, se elige la cantidad con sus porciones del catálogo
  (unidad, taza, cucharada…) o en gramos, con la vista previa de kcal y P/C/G calculada en
  `nutrition_core`.
- R3. **Desde "Añadir"** (Detalle de comida): el alimento se agrega a la lista de ingredientes de la
  comida que se está revisando.
- R4. **Desde el error de la IA** ("Buscar en la base manualmente"): se abre el Detalle de comida con
  ese primer alimento y se pueden añadir más.
- R5. Sin resultados: "No encontré ese alimento. Prueba con otro nombre." (sin sugerir crear uno).

## Acceptance Criteria
- AC1. Buscar "arep" muestra las arepas del catálogo de prueba con sus kcal por 100 g; "tinto"
  encuentra el café por sinónimo `[unit + widget]`.
- AC2. Elegir "Huevo" con 2 unidades muestra la vista previa con los valores que da
  `nutrition_core` para 100 g (2 × 50 g) `[widget]`.
- AC3. "Añadir" desde el detalle agrega el ítem y recalcula los totales `[widget]`.
- AC4. Desde el error de la IA, buscar y elegir abre el detalle con ese alimento; se puede guardar sin
  llamar a la IA `[integration]`.
- AC5. Sin resultados → mensaje de R5 `[widget]`.
- AC6. Los productos personales aparecen en la búsqueda `[unit]`.

## Technical Constraints
- Invariantes 1, 3 y 8. Sin cambios en el catálogo ni en su esquema; solo una consulta nueva de
  búsqueda en `infra/catalog`.

## Components / Files Affected
- `app/lib/infra/catalog/catalog_repository.dart` (`search(query, limit)`).
- `app/lib/features/review/` (búsqueda, cantidad, "Añadir"), `app/lib/features/capture/` (botón del
  error).

## Dependencies
- SPEC-012.

## Edge Cases
- Texto con tildes o sin ellas: se normaliza como en `resolve`.
- Caracteres especiales de FTS (comillas, asteriscos): se escapan.
- Alimento sin porciones definidas: solo gramos.

## Security & Privacy
- No sale ningún dato del dispositivo: la búsqueda es local.

## Tests Required
- Unit: AC1, AC6. Widget: AC2, AC3, AC5. Integration: AC4.

## Out of Scope
- Crear alimentos nuevos a mano, buscar en internet, códigos de barras.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC6 con evidencia; analyze y tests verdes; reviewer PASS.

## Evidencia
| AC | Evidencia |
|----|-----------|
| AC1 | `app/test/infra/catalog/catalog_search_test.dart` › "AC1: \"arep\" encuentra las arepas…" y "AC1: \"tinto\" encuentra el café por sinónimo…" (unit); `app/test/features/review/food_search_flow_test.dart` › "AC1: \"arep\" muestra las arepas con kcal por 100 g; \"tinto\" encuentra el café" (widget) |
| AC2 | `food_search_flow_test.dart` › "AC2: Huevo con 2 unidades: vista previa con los valores de nutrition_core para 100 g"; `app/test/features/review/manual_quantity_test.dart` › "AC2: huevo con 2 unidades → 100 g, como nutrition_core" |
| AC3 | `food_search_flow_test.dart` › "AC3: \"Añadir\" desde el detalle agrega el ítem y recalcula los totales" |
| AC4 | `food_search_flow_test.dart` › "AC4: desde el error de la IA, buscar y elegir abre el detalle con ese alimento y se guarda sin volver a llamar a la IA" (app completa) |
| AC5 | `food_search_flow_test.dart` › "AC5: sin resultados → mensaje (sin sugerir crear uno)" |
| AC6 | `catalog_search_test.dart` › "AC6: los productos personales aparecen en la búsqueda" |

Edge cases: tildes y mayúsculas, caracteres de FTS, desde 2 letras y con límite
(`catalog_search_test.dart`); alimento sin porciones → solo gramos (`manual_quantity_test.dart`);
"Corregir" vuelve al texto; texto ×2 en 360 px. Manual: recorrido en el teléfono (usuaria).

## Change Log
- 2026-10-03: creación a partir de T-019 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.
- 2026-10-03: implementada (autorización única de la usuaria para el lote). Detalles menores:
  - `CatalogRepository.search`: FTS5 por prefijo en cada palabra (`"arep"*`), términos citados para
    que el texto no se lea como sintaxis de FTS, orden por nombre, hasta 20. `FoodQueryResolver.search`
    pone primero los productos personales que contienen el texto.
  - Opciones de cantidad: "Unidad", "Tamaño pequeño/mediano/grande" y "Porción" si el alimento tiene
    esa porción; "Cucharadita/Cucharada/Taza/Vaso" solo si tiene densidad o una porción con ese
    nombre (no se ofrece "taza" para un huevo); siempre "Gramos". Porciones como "tajada" o "lata"
    no tienen regla en `nutrition_core`: para esas, gramos. Todo pasa por `resolveGrams` y la
    confianza por `itemConfidence` (mismas reglas del texto, sin regla nueva).
  - Se guarda la cantidad tal como se eligió ("2" "unidad") además de los gramos.
  - Desde el error de la IA, el detalle reemplaza la pantalla del análisis: "Corregir" vuelve a
    "¿Qué comiste?" con el texto. El botón solo aparece cuando falló la IA (no en un error de lectura
    de `user.db`).
  - El catálogo de prueba (`test/support/fixture_catalog.dart`) ganó "Arepa de queso" y "Café" con el
    sinónimo "tinto" (valores de prueba, no del catálogo real); el catálogo real no cambia.
  - La pantalla de error pasó a desplazamiento no perezoso (con el botón nuevo, "Volver" quedaba
    fuera de la vista en pantallas bajas).
  Status → Review.

## Review
Informe del reviewer: pendiente.
