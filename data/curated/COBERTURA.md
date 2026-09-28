# Cobertura del catálogo (SPEC-003)

Generado a partir del build de `catalog_version: 2026-09-27-3`. Ampliación del catálogo semilla
(28 alimentos, SPEC-001) a **152 alimentos** — cerca de la meta de ~200 propuesta en el backlog,
por debajo de la lista de ~166 presentada al usuario porque 12 alimentos no tuvieron cobertura
razonable en USDA FDC (documentados abajo, no forzados) y 1 (cerveza) quedó fuera por un hueco de
esquema, no de dato.

## Resumen

| Métrica | Valor |
|---|---|
| Alimentos totales en `foods.csv` | 152 (28 semilla + 124 nuevos de SPEC-003) |
| Coincidencia directa de FDC | 132 (87 %) |
| Proxy documentado (no es el alimento colombiano exacto) | 20 (13 %) |
| `atwater_review = true` (excepción numérica aceptada, no error de dato) | 15 |
| Sin cobertura razonable en FDC (documentado, no forzado) | 12 alimentos propuestos |
| Fuentes usadas | Solo USDA FDC (Foundation, SR Legacy, FNDDS) — TCAC/ICBF sigue bloqueada (PV-01) |

## Cobertura por categoría

| Categoría | Alimentos en catálogo |
|---|---|
| `frutas` | 29 |
| `verduras` | 23 |
| `carnes` | 22 |
| `cereales_y_tuberculos` | 18 |
| `huevos_lacteos` | 16 |
| `bebidas` | 9 |
| `condimentos_y_otros` | 9 |
| `grasas_y_aceites` | 9 |
| `leguminosas` | 8 |
| `azucares` | 5 |
| `snacks_procesados` | 4 |

`condimentos_y_otros` y `snacks_procesados` son categorías nuevas de SPEC-003 (no existían en el
catálogo semilla).

## Proxies documentados (no es el alimento colombiano exacto)

Cada fila cita la explicación completa en su `source_ref`; resumen aquí para revisión rápida:

| Alimento | Proxy usado |
|---|---|
| `papa_criolla` | Papa "gold potato" cruda (FDC no tiene la variedad colombiana ni versión cocida) |
| `platano_verde_cocido` | Plátano verde crudo (FDC no tiene versión cocida) |
| `masarepa` | Harina de maíz tipo "masa" genérica |
| `costilla_de_res` | "Beef shortribs" (corte más cercano) |
| `chorizo` | Chorizo de cerdo crudo (FDC no tiene versión cocida citable) |
| `longaniza` | Salchicha de cerdo genérica cocida |
| `mortadela` | "Bologna" (equivalente directo en nomenclatura FDC) |
| `bagre` | "Catfish" (bagre de canal, no distingue especie sudamericana) |
| `queso_doble_crema` | Queso asadero mexicano |
| `queso_costeno` | Queso cotija mexicano |
| `queso_paipa` | Queso gouda |
| `kumis` | Buttermilk cultivado |
| `maracuya` / `granadilla` | Misma entrada FDC ("Passion-fruit, purple"); FDC no distingue especies de Passiflora |
| `mora` | Blackberry (especie distinta, composición similar) |
| `lulo` | Pulpa de lulo congelada sin azúcar (no la fruta fresca entera) |
| `zapote` | Zapote mamey (Pouteria sapota), variedad más común en Colombia |
| `ahuyama` | "Winter squash" cocido |
| `habichuela` | Judía verde ("green beans") cocida |
| `panela` | Azúcar morena sin refinar ("brown sugar") |
| `gaseosa` | Gaseosa tipo cola genérica |
| `malta` | "Malt beverage" genérico (FDC no tiene la bebida dulce colombiana específica) |
| `jugo_de_mora` | Jugo de blackberry enlatado |
| `chocolate_de_mesa` | "Baking chocolate, mexican, squares" |

## `atwater_review = true` (excepciones numéricas aceptadas)

Mismo criterio ya aceptado para `cafe` en el catálogo semilla: el Atwater general (4/4/9) no
coincide ±20% con el `energy_kcal` real de FDC, pero no es un error de dato — es una divergencia
numérica conocida en dos escenarios:

1. **Alimentos de kcal casi nula** (`lechuga`, `espinaca`, `pepino_cohombro`, `brocoli`,
   `coliflor`, `cilantro`, `perejil`, `champinones`, `alcachofa`, `esparragos`, `limon`): la
   diferencia relativa es grande pero la diferencia absoluta es mínima (1-9 kcal/100g).
2. **Alimentos muy fibrosos** (`pimienta`, `oregano`, `vinagre`): gran parte de los carbohidratos
   declarados es fibra no metabolizable o ácido acético; FDC usa factores específicos (no el 4/4/9
   general) para calcular la energía real, que ya descuenta eso.

## Alimentos sin cobertura razonable en FDC (no forzados)

De la lista de ~166 alimentos presentada al usuario, estos 12 no tienen ningún dato real y
verificable en USDA FDC (Foundation, SR Legacy, FNDDS) — se documenta el hueco en vez de inventar
un valor o forzar un proxy sin sentido nutricional, por invariante 8 de `CLAUDE.md`:

| Alimento | Categoría propuesta | Razón |
|---|---|---|
| Arracacha cocida | cereales_y_tuberculos | Arracacha xanthorrhiza no tiene entrada en ningún dataset |
| Bocachico | carnes | Pez de río sudamericano sin equivalente en FDC |
| Tomate de árbol (tamarillo) | frutas | Fruta andina no representada en FDC |
| Curuba | frutas | Fruta andina no representada en FDC |
| Uchuva | frutas | No está en FDC (probado: uchuva, physalis, goldenberry, cape gooseberry) |
| Chontaduro | frutas | Fruto de palma específico de Colombia/Perú, ausente de FDC |
| Borojó | frutas | Fruta endémica del Chocó, no representada en FDC |
| Mamoncillo | frutas | No está en FDC (probado: mamoncillo, spanish lime, genip) |
| Agua de panela | bebidas | Sin producto ni preparación equivalente en FDC |
| Jugo de lulo | bebidas | FDC solo tiene pulpa cruda concentrada, no el jugo diluido que se consume |

Todas son frutas/bebidas amazónicas o andinas específicas de Colombia — esperado dado que FDC es
una base de datos estadounidense. Quedan como oportunidad futura si aparece una fuente con
licencia abierta que las cubra (p. ej. si se resuelve la licencia de la TCAC/ICBF, PV-01).

## Hueco de esquema (distinto de falta de dato): cerveza

FDC sí tiene un dato real para cerveza (SR Legacy FDC ID 168746, "Alcoholic beverage, beer,
regular, all" — 43 kcal/100g), pero el esquema de `catalog.db` no tiene columna `alcohol_g`. El
etanol aporta ~7 kcal/g que no está en `protein_g`/`carbs_g`/`fat_g`, así que el Atwater 4/4/9 da
~16 kcal/100g — subestimaría las calorías reales en ~63% si se agregara tal cual, sin ser un caso
de `atwater_review` (esa excepción es para inestabilidad numérica en valores casi cero, no para un
hueco estructural real). Por la regla de CLAUDE.md de detenerse y proponer en vez de improvisar
cuando algo no encaja en el esquema, **no se agregó `cerveza` en este build**. El usuario decidió
(2026-09-27) dejar las bebidas alcohólicas fuera de alcance por ahora; cubrirlas en el futuro
requiere una SPEC/ADR propia que agregue `alcohol_g` al esquema y su fórmula de energía asociada.

## Reproducibilidad

Todos los datos vienen de las descargas bulk CSV de USDA FDC ya documentadas en `data/SOURCES.md`
(sin llamadas de red nuevas). Cada fila de `foods.csv`/`portions.csv` cita su `fdc_id`, dataset y
URL exactos en `source_ref`; se verificaron manualmente varias filas contra el CSV crudo antes de
fusionar (no solo se confió en la extracción automática).
