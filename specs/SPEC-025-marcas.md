# SPEC-025: Marcas de mis productos

## Status
Done
Path: Strict (cambia la resolución de alimentos y el esquema de `user.db`; sin cambios de IA)

## Objective
Que "un yogur Alpina" o "una arepa Doñarepa" se resuelva a **mi producto de esa marca** (guardado con
su etiqueta) en vez del alimento genérico del catálogo.

## Context
Fase F3 de `docs/backlog.md` ("marcas"). Invariante 8: los valores solo vienen del catálogo (TCAC, USDA
FDC) o de una **etiqueta confirmada**; esta SPEC no añade fuentes. SPEC-034 dio a cada producto
personal nombres alternativos y prioridad al reconocer, pero solo con coincidencia exacta.

Prueba con la IA real (`parse_meal.v1`, presupuesto 0, 2026-10-09), cinco frases:
| Frase | `mention` | `food_query` |
|---|---|---|
| un yogur Alpina | un yogur Alpina | yogur Alpina |
| una arepa Doñarepa con queso | una arepa Doñarepa | arepa Doñarepa |
| un vaso de leche deslactosada Colanta | …leche deslactosada Colanta | leche deslactosada |
| 3 galletas saltín Noel | 3 galletas saltín Noel | galletas saltín Noel |
| un pan baguette D1 | un pan baguette | pan baguette |

La marca casi siempre llega en `mention` o en `food_query`, así que se puede resolver en la app **sin
cambiar el prompt ni el esquema** (a veces la IA la quita de los dos, como "D1": límite de este
enfoque, ver Out of Scope).

## User Story
Como persona que compra siempre las mismas marcas, quiero que la app use los valores de mi producto y
no los de un alimento genérico.

## Requirements
- R1. **Marca del producto:** campo opcional "Marca" en `personal_products` (migración v9 → v10, nulo
  por defecto), editable en "Editar producto" (SPEC-034), hasta 40 caracteres. Se incluye en
  "Exportar" y se borra con "Borrar todos mis datos".
- R2. **Reconocer por marca** (`FoodQueryResolver`, local, sin IA): si la marca (normalizada,
  `normalizeFoodText`) de algún producto personal aparece como palabra(s) en `mention` o `food_query`
  de un ítem:
  - se buscan los productos de esa marca cuyo nombre o nombre alternativo contiene, como comienzo de
    palabra, cada palabra del resto de la consulta (`matchesWordPrefixes`, SPEC-036);
  - uno → se usa ese producto; varios → "¿Cuál de estos?" entre ellos; ninguno → se resuelve como hoy
    (R3).
- R3. **Marca sin producto:** si se reconoció una marca de mis productos pero ningún producto de esa
  marca coincide, el ingrediente se resuelve como hoy y el detalle dice: "No tienes «{consulta}» de
  {Marca} en Mis productos: usé el genérico. Usa su etiqueta para guardarlo." (con la acción "Usar
  etiqueta" de SPEC-033). Si tampoco se encontró el genérico (el ingrediente queda "No encontrado"),
  dice: "No tienes «{consulta}» de {Marca} en Mis productos. Usa su etiqueta para guardarlo."
- R4. La prioridad de SPEC-034 R4 (nombre o alias exacto) se mantiene y va antes que R2.
- R5. Sin IA, sin fuentes nuevas y sin datos nuevos que salgan del dispositivo.

## Acceptance Criteria
- AC1. Producto "Yogur griego" marca "Alpina" (porción 150 g) y la IA devuelve
  `{mention: "un yogur Alpina", food_query: "yogur Alpina"}` → el ítem es ese producto `[unit + widget]`.
- AC2. Marca solo en `mention` (`food_query: "leche deslactosada"`, `mention: "…leche deslactosada
  Colanta"`) y producto "Leche deslactosada" marca "Colanta" → ese producto `[unit]`.
- AC3. Dos productos Alpina que coinciden ("Yogur griego", "Yogur de fresa") → "¿Cuál de estos?" con
  los dos `[unit]`.
- AC4. "kumis Alpina" con productos Alpina que no son kumis → genérico del catálogo (o no encontrado,
  como hoy) y el aviso de R3 `[widget]`.
- AC5. "Doña Arepa" / "Doñarepa" / "doñarepa": se reconoce si la marca guardada se escribe igual al
  normalizar; "Doña Arepa" con espacio y "Doñarepa" junta son distintas (se documenta) `[unit]`.
- AC6. Sin marca en la frase: la resolución no cambia; tests existentes de resolución (SPEC-018/020/
  028/034/035) verdes sin cambiar expectativas `[unit]`.
- AC7. Migración v9 → v10 conserva todo con `brand` nulo; "Editar producto" guarda la marca; exportar
  la incluye; borrar todo la borra `[integration + widget]`.

## Technical Constraints
- Invariantes 1, 3, 4, 8: la IA no cambia; los valores salen de la etiqueta confirmada; la confianza,
  de las reglas. Normalización con `normalizeFoodText`.

## Components / Files Affected
- `app/lib/infra/storage/` (columna y migración), `app/lib/infra/food_resolution/food_query_resolver.dart`
  (`resolve` recibe también `mention`), `app/lib/features/review/review_controller.dart`,
  `app/lib/features/settings/my_products_screen.dart` (campo Marca), `meal_detail_view.dart` (aviso),
  `docs/architecture.md`, `docs/privacy.md` (inventario: marca del producto).

## Dependencies
- SPEC-004, SPEC-033, SPEC-034, SPEC-036.

## Edge Cases
- Marca que también es una palabra del alimento ("Leche" como marca): solo cuenta si hay productos con
  esa marca; si el resto de la consulta queda vacío, no se usa R2.
- La marca aparece dentro de otra palabra ("alpinas"): solo cuenta como palabra completa.
- Producto con marca pero también nombre exacto: gana R4 (SPEC-034).
- Productos sin marca: se comportan como hoy.
- Dos marcas de mis productos en la misma frase: se prueba primero la más larga; si no tiene un producto
  que coincida, la siguiente.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No. Dato nuevo local (marca del producto) → `docs/privacy.md`
  (inventario) y exportación.

## Tests Required
- Unit: AC1–AC3, AC5, AC6. Widget: AC1, AC4, AC7. Integration: AC7. Manual: "un yogur Alpina" con un
  producto Alpina en el teléfono.

## Out of Scope
- Cambiar `parse_meal` (campo `brand` en un esquema v2): solo si este enfoque se queda corto (casos
  como "D1", que la IA quita). Iría en otra SPEC con evals.
- Que la IA de etiquetas lea la marca (`label_extraction.v2`).
- Productos de marca de fuentes externas (Open Food Facts u otra): POR VERIFICAR, otra SPEC y un ADR.
- Códigos de barras.

## Open Questions
- Ninguna. Decidido con la opción recomendada (2026-10-09): resolver en la app con la marca que ya
  llega en el texto, sin cambiar la IA; la marca se escribe en "Editar producto".

## Definition of Done
- AC1–AC7 con evidencia · analyze y tests verdes en `app` · reviewer PASS enlazado · `docs/privacy.md` y
  arquitectura actualizados · aprobación explícita de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-04: creación a partir de F3 ("marcas").
- 2026-10-09: reescrita antes de pedir aprobación: la prueba con la IA real muestra que la marca ya
  llega en el texto, así que se resuelve en la app con un campo "Marca" en Mis productos, sin cambiar
  el prompt ni el esquema (el borrador anterior pedía `parsed_meal.v2`, `label_extraction.v2` y evals).
  Preguntas abiertas resueltas con la opción recomendada.
- 2026-10-09: **Approved por la usuaria** ("aprobada la SPEC-025"). Status → Implementing.
- 2026-10-09: implementada. Detalles menores: `FoodQueryResolver.resolve` recibe `mention`;
  `brandWithoutProduct` da el aviso (marca y consulta sin la marca); la marca se recorta y vacía = sin
  marca; el aviso trae el botón "Usar etiqueta" del ingrediente. Los tests de migración de SPEC-008/015
  que comparaban con la versión 9 ahora esperan 10 (la vigente). app 518/518.
- 2026-10-09: reviewer PASS con MINOR. Corregidos: la marca se recorta a 40 caracteres también en el
  repositorio; con dos marcas en la frase se prueba la siguiente si la primera no tiene producto
  (edge case nuevo); comentario viejo de un test. Cambio de texto propuesto en R3 (aprobado después, ver abajo): si ni el genérico se encontró, el aviso no dice "usé el genérico". app
  520/520.
- 2026-10-09: prueba manual en el teléfono. **La usuaria aprobó el texto del aviso sin genérico y la
  fusión** ("sí a ambas, fusiona y haz push"). Status → Done.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/review/brand_resolution_test.dart` › "AC1: "yogur Alpina"…" (unidad) y "AC1: el detalle usa mi producto Alpina…" (pantalla) |
| AC2 | ✅ | mismo archivo › "AC2…" |
| AC3 | ✅ | mismo archivo › "AC3…" |
| AC4 | ✅ | mismo archivo › "AC4 (lógica)…" y "AC4: "kumis Alpina"…" |
| AC5 | ✅ | mismo archivo › "AC5…" |
| AC6 | ✅ | mismo archivo › "AC6…"; tests de resolución de SPEC-018/020/028/034/035 sin cambios |
| AC7 | ✅ | mismo archivo › "AC7: "Editar producto" guarda la marca" y "AC7: migrar desde la v9…" |
| Manual | ✅ | 2026-10-09, en el Motorola de la usuaria (versión de `1881203`, IA real): se puso la marca "Vita Latti" a "queso lonchas VITA LATTI" en "Editar producto"; "dos lonchas de queso Vita Latti" → ese producto (2 porciones · 60 g). "un yogur Vita Latti" (sin producto y sin yogur en el catálogo) → "No encontrado" y el aviso "No tienes «yogur» de Vita Latti en Mis productos. Usa su etiqueta para guardarlo." con "Usar etiqueta". No se guardó ninguna comida; después se quitó la marca del producto |

## Review
Revisión (2026-10-09, subagente `reviewer`, sobre `7422697`): **PASS** con MINOR (ver Change Log).
AC1–AC7 con evidencia; la prioridad de SPEC-034 R4 se conserva; sin marca nada cambia; migración desde
v9 y desde versiones viejas; sin IA, sin valores nutricionales nuevos; privacidad y arquitectura al día.
Prueba manual hecha después (Verificación).
