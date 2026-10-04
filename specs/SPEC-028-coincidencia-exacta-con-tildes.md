# SPEC-028: Coincidencia exacta con tildes

## Status
Draft
Path: Strict (cambia qué alimento se resuelve contra el catálogo; skill `nutrition-data`)

## Objective
Que un alimento cuyo nombre o sinónimo lleva tilde, "ñ" o "ü" ("Café", "Plátano maduro", "Ñame
cocido") se reconozca directamente (`matched`) cuando la IA o la persona lo escriben completo, con o
sin tildes, en lugar de pedir elegir entre un solo candidato.

## Context
Backlog T-025 (hallazgo del reviewer de SPEC-020) y T-026. `CatalogRepository.resolve`
(`app/lib/infra/catalog/catalog_repository.dart`) busca la coincidencia exacta comparando la consulta
normalizada (`normalizeFoodText`, SPEC-020) con `lower(name_es)` / `lower(term)` de SQLite, que no
quitan tildes. Resultado: "café" se normaliza a "cafe", no es igual a "café" y cae a la búsqueda FTS,
que devuelve `ambiguous` con un solo candidato.

Medición en el `catalog.db` actual (consulta de solo lectura, 2026-10-03): 152 alimentos y 68
sinónimos; **32** nombres o sinónimos llevan tilde, "ñ" o "ü". Al normalizar todos los términos no
aparece **ninguna** colisión nueva entre alimentos distintos.

`data/build_catalog/lib/validators.dart` tiene su propia copia del normalizador (sin "ü"), que valida
duplicados al construir el catálogo (T-026).

## User Story
Como persona que registra "un tinto y un plátano maduro", quiero que la app reconozca esos alimentos
sin hacerme elegir de una lista de una sola opción.

## Requirements
- R1. La coincidencia exacta de `resolve` compara la consulta normalizada con el nombre y los
  sinónimos **también normalizados** con `normalizeFoodText` (minúsculas, sin tildes, "ñ" → "n",
  "ü" → "u"). El índice normalizado se arma una vez por catálogo abierto, en Dart; el esquema de
  `catalog.db` no cambia.
- R2. Si la consulta normalizada coincide con términos de **dos o más** alimentos distintos, no hay
  `matched`: se sigue la regla actual (FTS5 → `ambiguous` o `not_found`).
- R3. El validador de `data/build_catalog` usa la misma normalización (con "ü") y **falla el build**
  si dos alimentos distintos quedan con el mismo nombre o sinónimo normalizado (hoy: 0 casos), para
  que R1 nunca elija en silencio entre dos alimentos.
- R4. No cambia nada más: umbrales, FTS5, productos personales (la regla de SPEC-004 de desambiguar
  cuando coinciden catálogo y producto personal se mantiene), valores nutricionales y porciones.

## Acceptance Criteria
- AC1. Con el catálogo de fixtures: `resolve("café")`, `resolve("cafe")` y `resolve("CAFÉ")` dan
  `matched` con `cafe`; `resolve("ñame cocido")` y `resolve("name cocido")` dan `matched` con
  `name_cocido` `[unit]`.
- AC2. Con el `catalog.db` real: los 32 nombres y sinónimos con marcas, escritos tal cual y sin
  marcas, dan `matched` con su alimento `[unit]`.
- AC3. Dos alimentos de fixture cuyos términos normalizados coinciden ("Papá de prueba" y "Papa de
  prueba" como sinónimo de otro) → `resolve("papa de prueba")` no da `matched` `[unit]`.
- AC4. `build_catalog` falla con un mensaje que nombra el término y los dos alimentos cuando hay
  una colisión normalizada; el catálogo real construye sin errores `[unit]`.
- AC5. Los tests existentes de resolución, búsqueda, captura y evals de fixtures siguen verdes sin
  cambiar sus expectativas, salvo las que hoy esperan `ambiguous` con un solo candidato para un
  nombre con tilde (se listan en la Verificación) `[unit + integration]`.

## Technical Constraints
- Invariante 8: no se añaden ni cambian filas del catálogo real.
- `normalizeFoodText` es la única regla en la app; `build_catalog` (otro paquete) mantiene una copia
  idéntica, enlazada por comentario y cubierta por un test con los mismos casos.

## Components / Files Affected
- `app/lib/infra/catalog/catalog_repository.dart` (índice normalizado y `resolve`).
- `data/build_catalog/lib/validators.dart` (normalizador con "ü" y regla de colisión).
- Tests: `app/test/infra/catalog/`, `app/test/support/fixture_catalog.dart`, `data/build_catalog/test/`.

## Dependencies
- SPEC-020 (`normalizeFoodText`).

## Edge Cases
- Consulta con espacios de más o mayúsculas: se normaliza igual que hoy.
- Nombre con paréntesis ("Maíz tierno (choclo)"): la coincidencia exacta exige el texto completo,
  como hoy; "maiz tierno" sigue por FTS.
- Catálogo vacío o sin sinónimos: el índice queda vacío y todo sigue por FTS.

## Security & Privacy
- No sale ningún dato del dispositivo.

## Tests Required
- Unit: AC1–AC4. Integration: AC5 (suite existente).

## Out of Scope
- Coincidencias aproximadas (errores de tipeo, plurales), sinónimos nuevos, cambios de esquema.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC5 con evidencia · analyze y tests verdes en `app` y `data/build_catalog` · reviewer PASS
  enlazado · aprobación de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-03: creación a partir de T-025 (incluye T-026).

## Review
Informe del reviewer: pendiente.
