# Fuentes usadas en el catálogo (versionado)

## USDA FoodData Central (`usda_fdc_foundation`, `usda_fdc_sr_legacy`, `usda_fdc_fndds`)

La API pública de búsqueda (`DEMO_KEY`) resultó impráctica: su cuota es
mucho más baja de lo documentado (`x-ratelimit-limit: 10`, `retry-after`
de ~6.5 horas tras agotarla). En vez de esa vía, se usaron las
**descargas completas en CSV** que ya recomendaba `data/sources/README.md`
— sin API key, sin límite de tasa, totalmente reproducible.

| source_id | Dataset | Versión | Descargado | Licencia |
|---|---|---|---|---|
| `usda_fdc_foundation` | Foundation Foods | 2025-12-18 | 2026-09-27 | CC0 1.0 |
| `usda_fdc_sr_legacy` | SR Legacy | 2018-04 (publicado 2019-04-01) | 2026-09-27 | CC0 1.0 |
| `usda_fdc_fndds` | Survey (FNDDS 2021-2023) | 2024-10-31 | 2026-09-27 | CC0 1.0 |

URLs de descarga (zip, `data/sources/*.zip`, no versionados en git):
- https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_csv_2025-12-18.zip
- https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip
- https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_survey_food_csv_2024-10-31.zip

Cada fila de `data/curated/foods.csv`/`portions.csv` cita `FDC ID <id>
(<dataset>) — <descripción> — <url de food-details> — fecha de consulta`
en su `source_ref`.

### Notas de curación

- **`nutrient_id` no significa lo mismo en todos los datasets.** Foundation
  y SR Legacy usan el `id` de `nutrient.csv` (1008 = Energy KCAL, 1003 =
  Protein, ...). El dataset Survey (FNDDS) usa en cambio `nutrient_nbr` (la
  numeración USDA clásica: 208 = kcal, 203 = proteína, ...) como valor de
  `nutrient_id` en `food_nutrient.csv`. Si se vuelve a consultar este
  dataset a mano, verificar cuál de las dos columnas aplica antes de leer
  un valor.
- **`platano_maduro`** (Foundation, fdc_id 2710817): el export no incluye
  una fila de Energy (nutrient_id 1008) para este alimento. `energy_kcal`
  se calculó con los factores de Atwater generales (4/4/9) sobre
  protein_g/carbs_g/fat_g ya sacados de FDC — no es un valor medido
  directamente, está anotado así en su `source_ref`.
- **`arepa`** (fndds 2707828, "Arepa Dominicana") y **`queso_campesino`**
  (fndds 2705745, "Queso Fresco") son proxies razonables, no coincidencias
  exactas de la arepa/queso colombianos: FDC no tiene entradas específicas
  para esos alimentos. Anotado en su `source_ref`.
- **`cafe`** queda fuera de ±20% Atwater en términos relativos (0.7 vs. 1
  kcal/100g) solo por tratarse de un alimento de kcal casi nula, donde la
  tolerancia porcentual es numéricamente inestable; la diferencia absoluta
  (0.3 kcal/100g) es irrelevante. Aceptado con `atwater_review = true`.
- Alimento considerado y **descartado** por no tener una coincidencia
  razonable en ninguno de los tres datasets: "ensalada" (plato compuesto,
  sin un ingrediente único representativo; fuera de alcance por definición,
  no es un alimento base). No es parte de la lista R7 de
  `specs/SPEC-001-registro-por-texto.md` (era una adición propia para
  ampliar cobertura); se documenta el hueco en vez de forzar un dato.
- SPEC-003 amplió el catálogo de 28 a 152 alimentos (~166 propuestos, 12
  sin cobertura razonable en FDC + 1 hueco de esquema con "cerveza"). Ver
  `data/curated/COBERTURA.md` para el detalle completo por categoría,
  proxies usados y exclusiones documentadas. Nota corregida: "chocolate de
  mesa" (descartado en SPEC-001 por no tener match) sí se cubrió en
  SPEC-003 con un proxy razonable ("Baking chocolate, mexican, squares",
  FDC ID 167999).

## Unidades domésticas (`data/curated/household_units.csv`)

`cucharada`/`cucharadita`/`taza` son medidas estándar de etiquetado
nutricional de la FDA (21 CFR 101.9(b)(5)(viii): 15 mL / 5 mL / 240 mL), no
dependen de FDC. `vaso` no tiene un estándar oficial — queda una convención
culinaria colombiana (250 mL) marcada explícitamente como tal.

## Catálogo generado

`app/assets/catalog/catalog.db` (generado, no versionado): 152 alimentos,
`catalog_version` con fecha + contador. Regenerar con
`cd data/build_catalog && dart run bin/build_catalog.dart` tras editar
cualquier CSV curado.
