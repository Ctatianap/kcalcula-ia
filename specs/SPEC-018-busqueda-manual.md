# SPEC-018: Búsqueda manual en el catálogo

## Status
Approved
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

## Change Log
- 2026-10-03: creación a partir de T-019 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.

## Review
Informe del reviewer: pendiente.
