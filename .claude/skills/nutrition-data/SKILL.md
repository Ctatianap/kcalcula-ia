---
name: nutrition-data
description: Procedimiento para trabajar con el catálogo nutricional (catalog.db) - añadir alimentos, sinónimos en español colombiano, porciones domésticas y unidades con su fuente, y regenerar el catálogo. Úsala siempre que una tarea toque data/, el esquema del catálogo, porciones, unidades o la resolución de alimentos. Siempre es Strict Path.
---

# SKILL: nutrition-data

## Purpose
Mantener un catálogo nutricional trazable: cada número tiene una fuente citada y reproducible.

## When to use
Cambios en `data/curated/`, `data/build_catalog/`, el esquema de `catalog.db`, porciones,
unidades domésticas, sinónimos o la lógica de resolución de alimentos.

## Regla absoluta
**Nunca escribas un valor nutricional ni un peso de porción de memoria o estimado por IA.**
Cada valor se copia o importa de una fuente y lleva `source_id` + `source_ref`.
Si no hay fuente: el alimento no entra al catálogo (la app mostrará "no encontrado").

## Fuentes
| source_id | Fuente | Licencia | Uso |
|---|---|---|---|
| `tcac2018` | Tabla de Composición de Alimentos Colombianos, ICBF | POR VERIFICAR para distribución | Prioritaria para alimentos colombianos |
| `usda_fdc` | USDA FoodData Central (Foundation, SR Legacy, FNDDS) | CC0 1.0 | Resto de alimentos y pesos de porciones |
| `curated` | Medición o convención documentada por el equipo | Propia | Solo porciones (p. ej. tamaños de arepa), nunca nutrientes |

Mientras la licencia de la TCAC no esté confirmada, sus filas llevan `license_status = pending`
y el build de release las excluye.

## Modelo de datos (`catalog.db`)
- `meta(catalog_version, built_at)`
- `sources(id, name, license, url, version)`
- `foods(id, name_es, category, source_id, source_ref, energy_kcal, protein_g, carbs_g, fat_g,
  fiber_g, sugar_g, sodium_mg, density_g_per_ml NULL, license_status)`: valores **por 100 g de
  porción comestible**.
- `food_synonyms(food_id, term)` + tabla FTS5 para búsqueda.
- `portions(food_id, descriptor, grams, source_id, source_ref, is_curated_estimate)`.
  Descriptores: `unidad`, `pequeno`, `mediano`, `grande`, `tajada`, `rebanada`, `porcion`…
- `household_units(unit, ml, source_ref)`: cucharada, cucharadita, taza, vaso.

## Procedure
1. Crea o edita CSV en `data/curated/` (versionados). Las fuentes crudas van en `data/sources/`
   (no versionadas; su `README.md` indica cómo descargarlas).
2. Sinónimos: términos reales de Colombia ("tajada", "arepa de choclo", "tinto"). Puedes proponerlos
   con ayuda de IA, pero el usuario los revisa antes de fusionar.
3. Porciones `curated`: documenta en `source_ref` cómo se obtuvo el peso (medición, empaque, etc.)
   y marca `is_curated_estimate = 1`. Dan confianza "Estimación".
4. Regenera: `cd data/build_catalog && dart run`. Sube `catalog_version` (fecha + contador).
5. Ejecuta los tests del build y de `nutrition_core`.

## Validation (el build falla si no se cumple)
- Toda fila de `foods` y `portions` tiene `source_id` y `source_ref`.
- kcal presentes; Atwater (4P + 4C + 9G) dentro de ±20 % de las kcal, o la fila queda marcada para revisión.
- Sin `name_es` duplicados ni sinónimos que apunten a dos alimentos sin desambiguar.
- Gramos de porción > 0.
- Reporte del build: filas añadidas, cambiadas y eliminadas respecto a la versión anterior.

## Output
CSV actualizados, `catalog.db` regenerado y el reporte del build en la descripción del cambio.

## Failure conditions
- Sin fuente para un valor → no añadirlo; registrar el hueco en la SPEC.
- Conflicto entre TCAC y FDC para un alimento colombiano → usar TCAC y anotar el conflicto.
