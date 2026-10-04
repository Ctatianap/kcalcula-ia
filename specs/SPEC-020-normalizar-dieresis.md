# SPEC-020: Búsqueda y resolución con "ü"

## Status
Draft
Path: Strict (toca la lógica de resolución de alimentos contra el catálogo; skill `nutrition-data`)

## Objective
Que un texto con "ü" (por ejemplo "pingüino" o "agüita") se busque y se resuelva igual que si se
escribiera sin diéresis, como ya pasa con las tildes y la "ñ".

## Context
Backlog T-024 (hallazgo MINOR del reviewer de SPEC-018). `_normalize` de
`app/lib/infra/catalog/catalog_repository.dart` y de `app/lib/infra/food_resolution/food_query_resolver.dart`
convierte `áéíóúñ` (y mayúsculas) pero no `ü`/`Ü`. Como la consulta de FTS se parte por
`[^a-z0-9]+`, "pingüino" queda en dos términos ("ping" y "ino"). El catálogo actual no tiene
alimentos con "ü" en `data/curated/`, así que hoy el efecto está en lo que escribe la persona (y lo
que devuelve la IA en `food_query`). Se anotó primero como Fast Path; se corrige a Strict porque
cambia qué alimento se resuelve.

## User Story
Como persona que escribe con ortografía completa, quiero que "agüita de panela" encuentre lo mismo que
"aguita de panela".

## Requirements
- R1. `ü` y `Ü` se normalizan a `u` en la búsqueda manual (SPEC-018), en la resolución de `food_query`
  (SPEC-001) y en la coincidencia con productos personales (SPEC-004).
- R2. Una sola función de normalización compartida por el catálogo y el resolver (hoy hay dos copias
  iguales), para que no vuelvan a separarse.
- R3. No cambia nada más: las demás reglas de `matched`/`ambiguous`/`not_found`, los umbrales y el
  catálogo quedan igual.

## Acceptance Criteria
- AC1. Con un alimento de prueba "Pingüino de prueba" en el catálogo de fixtures: buscar "pingüino",
  "pinguino" y "PINGÜINO" devuelve ese alimento `[unit]`.
- AC2. `resolve("agüita")` y `resolve("aguita")` dan el mismo resultado (mismo estado y mismo
  alimento o candidatos) `[unit]`.
- AC3. Un producto personal "Yogur de agüita" aparece al buscar "aguita" `[unit]`.
- AC4. Los tests de resolución y búsqueda existentes (`catalog_repository_test.dart`,
  `catalog_search_test.dart`, flujos de captura) siguen verdes sin cambios en sus expectativas
  `[unit + integration]`.

## Technical Constraints
- Invariante 8: no se añaden filas al catálogo real; el alimento con "ü" vive solo en el fixture de
  tests.
- `isSearchableQuery` (SPEC-018) usa la misma normalización.

## Components / Files Affected
- `app/lib/infra/catalog/catalog_repository.dart`, `app/lib/infra/food_resolution/food_query_resolver.dart`
  (y un archivo compartido para `normalizeFoodText`, p. ej. en `app/lib/format/`).
- `app/test/support/fixture_catalog.dart` y tests de catálogo y resolver.

## Dependencies
- SPEC-018 (búsqueda manual).

## Edge Cases
- "ü" al inicio, en medio y al final de la palabra; mayúscula `Ü`.
- Texto solo con "ü" ("ü"): sigue sin ser buscable (menos de 2 letras).

## Security & Privacy
- No sale ningún dato del dispositivo.

## Tests Required
- Unit: AC1–AC3. Integration: AC4 (suite existente).

## Out of Scope
- Otros diacríticos poco usados en es-CO (`ç`, `à`…), sinónimos nuevos, cambios en `build_catalog`.

## Open Questions
- ¿El tokenizador FTS5 del `catalog.db` real (`unicode61`) ya quita la diéresis del índice? Se
  verifica en la implementación con una consulta de solo lectura; si no la quita, el alcance pasaría
  a incluir `data/build_catalog` y se volvería a pedir aprobación.

## Definition of Done
- AC1–AC4 con evidencia · analyze y tests verdes · reviewer PASS enlazado · aprobación de la usuaria
  antes de fusionar (Strict).

## Change Log
- 2026-10-04: creación a partir de T-024 (antes Fast Path; corregido a Strict).

## Review
Informe del reviewer: pendiente.
