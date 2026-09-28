# SPEC-003: Catálogo nutricional completo (~200 alimentos)

## Status
Review
Path: Strict (toca el catálogo nutricional — skill `nutrition-data`, siempre Strict)

## Objective
Ampliar el catálogo semilla (28 alimentos de SPEC-001) a una cobertura de ~200 alimentos
frecuentes en la dieta colombiana, con el mismo pipeline `data/build_catalog/` ya construido y
sin transcribir ningún valor de la TCAC 2018 (bloqueada por licencia, PV-01).

## Context
Backlog T-004. Depende de T-001 (hecho) y T-002 (`Status: Review` — el usuario decidió avanzar
sin esperar a que quede `Done`). El objetivo original de T-004 en `docs/backlog.md` decía
"Pipeline TCAC + FDC"; esta SPEC lo ajusta a **solo USDA FDC** porque PV-01 ya se resolvió después
de escribirse el backlog: `docs/research/2026-09-27-tcac-licencia.md` confirma que el portal del
ICBF prohíbe la reproducción/uso comercial de sus contenidos sin autorización previa y escrita —
la TCAC sigue sin poder usarse hasta que esa autorización exista (o aparezca una versión con
licencia abierta en datos.gov.co, que quedó sin confirmar). El pipeline técnico
(`data/build_catalog/`), el esquema y los validadores de SPEC-001 no cambian: esta SPEC es
principalmente curación de datos (skill `nutrition-data`), no código nuevo.

## User Story
Como persona que registra comidas colombianas variadas, quiero que el catálogo reconozca la
mayoría de lo que como (no solo los ~28 alimentos del MVP), para no encontrarme constantemente
con "no encontrado" y tener que buscar cada ingrediente por separado.

## Requirements
- R1. El catálogo crece de 28 a ~200 alimentos, reutilizando el esquema y el build de
  `data/build_catalog/` sin cambios de código (solo datos en `data/curated/*.csv`), salvo el
  chequeo nuevo de R2.
- R2. Ninguna fila nueva usa `tcac2018`/ICBF como fuente. Se añade una validación en
  `data/build_catalog/lib/validators.dart` que falla el build si aparece ese `source_id` mientras
  PV-01 siga sin resolver (evita que alguien lo reintroduzca por error más adelante).
- R3. Cada alimento nuevo trae, como mínimo: `name_es`, `category`, `source_id`/`source_ref`
  citando FDC ID + descripción + URL + fecha de consulta, los 4 macronutrientes, y al menos una
  fila en `portions` (con su propia fuente, real o curada y marcada como tal).
- R4. Sinónimos en español colombiano donde el nombre coloquial difiera del nombre técnico (p.
  ej. "fríjol" y sus variantes regionales, "guineo" para banano — ya existe ese patrón en el
  catálogo semilla).
- R5. Se documenta la lista completa de alimentos cubiertos por categoría (no un listado plano
  suelto) en `data/curated/COBERTURA.md` (nuevo), incluyendo los que se dejaron fuera por no
  tener una fuente razonable en FDC y por qué.
- R6. `dart run bin/build_catalog.dart` sigue pasando todas sus validaciones existentes (Atwater
  ±20 % con excepción explícita, `source_id`/`source_ref` obligatorios, sin `name_es` ni
  sinónimos duplicados, `grams > 0`) para el catálogo completo de ~200 filas.
- R7. Reporte de cobertura: cuántos alimentos se cubrieron frente a la meta de ~200, agrupados
  por categoría, y qué proporción son coincidencia directa de FDC vs. proxy aproximado (mismo
  criterio que ya se usó y documentó para arepa/queso campesino en el catálogo semilla).

## Acceptance Criteria
- AC1. `cd data/build_catalog && dart run bin/build_catalog.dart` termina sin errores de
  validación con las filas nuevas incluidas `[manual]`.
- AC2. `data/build_catalog/test/validators_test.dart` sigue en verde sin cambios de código para
  las reglas ya existentes `[unit]`.
- AC3. Un test nuevo confirma que ninguna fila de `data/curated/foods.csv` ni `portions.csv`
  tiene `source_id` conteniendo `tcac` `[unit]`.
- AC4. `data/curated/COBERTURA.md` existe y enumera los alimentos cubiertos por categoría, con el
  conteo real (no una cifra inventada) `[manual]`.
- AC5. El reviewer compara 10 filas al azar (el doble que en SPEC-001, por el volumen) de
  `data/curated/foods.csv` contra su `source_ref` citado y coinciden `[manual]`.
- AC6. `app/assets/catalog/catalog.db` regenerado incluye las filas nuevas;
  `CatalogRepository.resolve(...)` (sin cambios de código) resuelve correctamente 5 `food_query`
  elegidos al azar entre los alimentos nuevos `[integration]`.

## Technical Constraints
- Invariante 8 de `CLAUDE.md`: todo valor nutricional con `source_id`/`source_ref` verificable;
  nunca de memoria.
- Sigue la skill `nutrition-data` completa (siempre Strict Path).
- El esquema de `catalog.db` no cambia; si algo no encaja en él, se detiene y se propone el
  cambio de esquema explícitamente, no se improvisa.

## Components / Files Affected
`data/curated/foods.csv`, `data/curated/portions.csv`, `data/curated/food_synonyms.csv` (crecen) ·
`data/curated/COBERTURA.md` (nuevo) · `data/SOURCES.md` (actualiza) ·
`data/build_catalog/lib/validators.dart` (nueva regla, R2) ·
`data/build_catalog/test/validators_test.dart` (test de la nueva regla) ·
`app/assets/catalog/catalog.db` (regenerado, no versionado).

## Dependencies
T-001 (hecho). T-002 (`Status: Review`, no bloquea por decisión explícita del usuario).

## Edge Cases
- Alimento sin ningún equivalente razonable en FDC: se documenta el hueco en `COBERTURA.md`, no
  se fuerza un dato (mismo criterio que "ensalada"/"chocolate de mesa" en el catálogo semilla).
- Nombres regionales distintos según la zona de Colombia para el mismo alimento: un solo alimento
  en el catálogo, sinónimos para las variantes más comunes (no una fila por región).
- Platos compuestos o preparados (sancocho, ajiaco, arroz con pollo): fuera de alcance — son
  recetas de varios ingredientes, no alimentos base. Ver Out of Scope.

## Security & Privacy
- Sin datos nuevos fuera del dispositivo: el catálogo se empaqueta en la app, igual que hoy.
- Strict Path aquí es por tocar el catálogo nutricional (regla explícita de `CLAUDE.md`), no por
  privacidad.

## Tests Required
- Unit: `data/build_catalog/test/validators_test.dart` (regla nueva de R2, AC3) +
  regresión de las reglas existentes (AC2).
- Integration: resolución de 5 `food_query` nuevos contra el `catalog.db` regenerado (AC6).
- Manual: build completo sin errores (AC1), reporte de cobertura (AC4), comparación de 10 filas
  por el reviewer (AC5).

## Out of Scope
Platos compuestos/recetas de varios ingredientes, sinónimos regionales exhaustivos (solo los más
comunes), TCAC (sigue bloqueada por licencia), fotos de etiqueta (T-005), traducción a otros
idiomas, ampliar `household_units`, bebidas alcohólicas (requieren agregar `alcohol_g` al
esquema — decisión explícita del usuario de dejarlas fuera por ahora, ver Change Log).

## Open Questions
- ~~Antes de curar los ~200 alimentos en bloque: ¿revisar la lista primero?~~ Resuelto: el usuario
  aprobó la SPEC y pidió ver la lista antes de curar datos. Lista de ~166 alimentos (28 existentes
  + ~138 nuevos, por categoría) presentada en el chat el 2026-09-27; el usuario respondió "sigue
  con la curación tal como está" — lista confirmada sin cambios.
- ~~Mecanismo exacto de curación en lote~~ Resuelto: 7 subagentes `fork` en paralelo (uno por grupo
  de categorías), todos usando el mismo script de lookup offline sobre los CSV bulk de FDC ya
  descargados (`data/sources/{sr_legacy,foundation,fndds}/`), sin llamadas de red nuevas.
- ~~Hueco de esquema revelado por "cerveza"~~ Resuelto por el usuario (2026-09-27): bebidas
  alcohólicas quedan fuera de alcance por ahora, no se agrega `alcohol_g` al esquema en esta SPEC.
  FDC tiene un valor real para cerveza (43 kcal/100g, SR Legacy FDC ID 168746) pero `catalog.db` no
  tiene columna `alcohol_g`, así que el Atwater 4/4/9 subestimaría sus calorías reales en ~63% (el
  etanol no está en ningún macronutriente del esquema actual) — por eso no se forzó el dato.
  Detalle en `data/curated/COBERTURA.md#hueco-de-esquema-distinto-de-falta-de-dato-cerveza`. Si en
  el futuro se quiere cubrir bebidas alcohólicas, hace falta una SPEC/ADR propia que agregue
  `alcohol_g` al esquema (`data/build_catalog/lib/schema.dart`) y su fórmula de energía asociada.

## Definition of Done
- AC1–AC6 con evidencia enlazada en esta SPEC.
- `dart analyze` y todos los tests de `data/build_catalog` verdes.
- Reviewer: PASS enlazado.
- `data/SOURCES.md` y `data/curated/COBERTURA.md` reflejan lo implementado.

## Evidencia de Acceptance Criteria
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `cd data/build_catalog && dart run bin/build_catalog.dart` → `catalog_version: 2026-09-27-3`, 124 alimentos añadidos, 0 errores, solo warnings esperados de `atwater_review` |
| AC2 | ✅ | `data/build_catalog/test/validators_test.dart` — 20/20 tests verdes (las reglas ya existentes, sin cambios) |
| AC3 | ✅ | Nuevo grupo `validateNoTcacSource` en `validators_test.dart` (3 tests): rechaza `source_id` con "tcac" en foods y portions, acepta `usda_fdc_*` |
| AC4 | ✅ | `data/curated/COBERTURA.md` — 152 alimentos por categoría, 20 proxies documentados, 15 `atwater_review`, 12 sin cobertura documentados, 1 hueco de esquema (cerveza) |
| AC5 | ⏳ pendiente | Reviewer aún no comparó las 10 filas al azar contra `source_ref` — se hace en el paso de reviewer, antes de `Done` |
| AC6 | ✅ | `app/test/integration/catalog_real_db_test.dart` (nuevo): resuelve 5 `food_query` nuevos (mango, guayaba, aceite de coco, queso mozzarella, avena cocida) contra el `catalog.db` real regenerado |

Verificado: `data/build_catalog` → `dart analyze` sin issues, `dart test` 17/17 verdes (14 antes +
3 nuevos de R2). `app` → `flutter analyze` sin issues, `flutter test` todos verdes (29 antes + 1
nuevo de AC6).

## Change Log
- 2026-09-28: creación, a partir de T-004 de `docs/backlog.md`. Ajusta el objetivo original
  ("TCAC + FDC") a solo USDA FDC, por PV-01 (resuelto después de escribirse el backlog).
- 2026-09-27: lista de ~166 alimentos presentada y confirmada por el usuario sin cambios.
  Implementación: R2 (validador anti-TCAC) agregado y probado; 124 alimentos curados vía 7
  subagentes `fork` en paralelo contra los CSV bulk de FDC ya descargados; fusionados a
  `data/curated/*.csv` (152 alimentos totales) tras verificar manualmente varias filas contra el
  CSV crudo; `catalog.db` regenerado; `COBERTURA.md` escrito; test de integración nuevo para AC6.
  Hueco revelado durante la implementación (no en la SPEC original): "cerveza" no se pudo incluir
  por falta de columna `alcohol_g` en el esquema — no se improvisó un cambio de esquema; se
  planteó al usuario, que decidió dejar bebidas alcohólicas fuera de alcance por ahora (ver Out of
  Scope).

## Review
Informe del reviewer:
