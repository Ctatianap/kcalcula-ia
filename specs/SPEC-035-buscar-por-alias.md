# SPEC-035: Buscar mis productos también por sus nombres alternativos

## Status
Draft
Path: Standard (búsqueda manual de solo lectura; no cambia `resolve`, el catálogo ni `nutrition_core`)

## Objective
Que "Buscar alimento" y "Elegir de mis productos" encuentren un producto personal también por los
nombres con que la persona lo llama ("mi pan"), igual que al registrar por texto.

## Context
Backlog T-036, hallazgo del reviewer de SPEC-034. SPEC-034 R4 hace que "mi pan" se reconozca al
registrar por texto o voz, pero:
- "Buscar alimento" (SPEC-018, `FoodQueryResolver.search`) solo compara el **nombre** del producto;
- "Elegir de mis productos" (SPEC-033 R4) filtra solo por nombre.

La pantalla "Editar producto" dice "Si escribes o dices uno de estos nombres, usamos este producto",
así que buscar "mi pan" y no encontrarlo es incoherente.

## User Story
Como persona que llama a su pan "mi pan", quiero encontrarlo al buscarlo así, para no recordar el
nombre exacto que le puse.

## Requirements
- R1. `FoodQueryResolver.search` incluye un producto personal si la consulta (normalizada) está
  contenida en su nombre **o en alguno de sus nombres alternativos**. Cada producto aparece una sola
  vez, con su nombre (no el alias). El orden y el límite de SPEC-018 no cambian (productos personales
  primero, hasta 20).
- R2. "Buscar alimento" construye el resolver con los alias (`getPersonalProductAliases`).
- R3. "Elegir de mis productos" filtra también por los alias, y muestra debajo del nombre "También:
  mi pan, …" cuando el producto tiene alias.
- R4. Todo local, sin IA.

## Acceptance Criteria
- AC1. Producto "Pan tajado integral" con alias "mi pan": `search("mi pan")` lo devuelve una vez, con
  el nombre "Pan tajado integral" `[unit]`.
- AC2. Un producto que coincide por nombre y por alias a la vez aparece una sola vez `[unit]`.
- AC3. En "Buscar alimento", escribir "mi pan" muestra "Pan tajado integral" `[widget]`.
- AC4. En "Elegir de mis productos", escribir "mi pan" deja solo ese producto y se ve "También: mi
  pan" `[widget]`.
- AC5. Los tests existentes de búsqueda (SPEC-018), resolución y "Elegir de mis productos" siguen
  verdes sin cambiar expectativas `[unit + widget]`.

## Technical Constraints
- Normalización con `normalizeFoodText` (SPEC-020/028).
- La UI pasa por `infra/` para leer los alias.

## Components / Files Affected
- `app/lib/infra/food_resolution/food_query_resolver.dart` (`search`).
- `app/lib/features/review/food_search_screen.dart`, `personal_product_picker_screen.dart`.
- Tests: `app/test/infra/catalog/catalog_search_test.dart` o uno nuevo, y tests de pantalla.

## Dependencies
- SPEC-018, SPEC-033, SPEC-034.

## Edge Cases
- Consulta de menos de 2 letras: igual que hoy (no busca).
- Alias que también coincide con alimentos del catálogo: el producto sale primero y los del catálogo
  después, como hoy.
- Producto sin alias: igual que hoy.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No.

## Tests Required
- Unit: AC1, AC2. Widget: AC3, AC4. Regresión: AC5.
- Manual: buscar "mi pan" en "Buscar alimento" en el teléfono.

## Out of Scope
- Mostrar el alias como resultado separado.
- Cambiar `resolve` (SPEC-034).

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC5 con evidencia · analyze y tests verdes en `app` · prueba manual · reviewer PASS enlazado.

## Change Log
- 2026-10-07: creación a pedido de la usuaria ("sigamos con eso"). Backlog T-036.

## Review
Informe del reviewer:
