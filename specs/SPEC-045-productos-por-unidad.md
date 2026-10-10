# SPEC-045: Mis productos medidos por unidad

## Status
Implementing
Path: Strict (unidades y resolución de cantidades; esquema de `user.db`)

## Objective
Que un producto personal pueda tener "peso de una unidad" (por ejemplo, un huevo = 60 g), para que
"dos huevos" se convierta en 2 × 60 g en vez de quedar "Sin equivalencia".

## Context
Hallazgo en la prueba de SPEC-024 (2026-10-09): la usuaria tiene el producto personal "huevo" con
porción de etiqueta de 60 g. "dos huevos" lo encuentra por nombre exacto (SPEC-034 R4), pero un producto
personal solo tiene la porción "porcion" (`personalProductToFoodCatalogEntry`), así que "unidad" no
tiene equivalencia y queda en 1 porción · 60 g, Estimación (SPEC-043). La regla de `resolveGrams` para
"unidad" ya existe en `nutrition_core` (porción "unidad" × cantidad); solo falta que el producto
personal tenga esa porción.

## User Story
Como persona que guardó un producto que se come por unidades (huevo, pan tajado, galleta), quiero
decir cuánto pesa una unidad, para registrar "dos huevos" sin hacer cuentas.

## Requirements
- R1. **Campo nuevo** en "Editar producto" (SPEC-034): "Peso de una unidad" en la unidad del producto
  (g o ml), opcional, número mayor que 0 y hasta 5.000, con coma decimal (SPEC-030). Ayuda: "Ej: un
  huevo pesa 60 g. Así «dos huevos» se calcula solo."
- R2. **Columna** `unit_grams` (nula) en `personal_products`, migración v10 → v11. Se incluye en
  "Exportar" y se borra con "Borrar todos mis datos".
- R3. **Resolución:** si el producto tiene peso de unidad, su `FoodCatalogEntry` lleva además la porción
  "unidad" con ese peso (no curada). "2 unidad" → `resolveGrams` (ya existente) → 2 × peso, base
  `unit_portion`, confianza por regla (Buena estimación). Sin peso de unidad: como hoy (Sin
  equivalencia, SPEC-043).
- R4. La regla de confianza y `nutrition_core` no cambian; el peso de unidad lo escribe la persona
  (como los valores de la etiqueta, invariante 8: fuente = la persona, con `source_ref` del producto).
- R5. Lo ya guardado no cambia.
- R6. Si la cantidad se dijo en unidades ("dos huevos") y el producto tiene peso de unidad, el detalle
  muestra "2 unidades · 140 g" y los botones − / + cambian de a una unidad; "Ver en g" funciona igual
  ("Ver en unidades" para volver). Si se dijo en porciones o en g, se muestra como hoy (porciones de la
  etiqueta).

## Acceptance Criteria
- AC1. Producto "huevo" (porción 60 g) con peso de unidad 60 → "dos huevos" (2 unidad) → 120 g, "Cantidad
  dicha por ti", Buena estimación `[unit + widget]`.
- AC2. Sin peso de unidad → igual que hoy: "Sin equivalencia · ajústala", 60 g, Estimación `[unit]`.
- AC3. "Editar producto" guarda "55,5" como 55,5; vacío = sin peso; 0, negativo o más de 5.000 →
  mensaje en español y no se guarda `[widget]`.
- AC4. Migración v10 → v11 conserva todo con `unit_grams` nulo; exportar lo incluye; borrar todo lo
  borra `[integration]`.
- AC6. Producto con porción de 60 g y peso de unidad 70: "dos huevos" → "2 unidades · 140 g"; + → "3
  unidades · 210 g"; − dos veces → "1 unidad · 70 g"; "Ver en g" → "70 g". "2 porciones de huevo" →
  "2 porciones · 120 g" `[widget]`.
- AC5. Tests existentes (resolución, SPEC-033/034/043, migraciones) verdes; los de migración que
  comparan la versión pasan a esperar 11 `[unit + widget]`.

## Technical Constraints
- Invariantes 3, 4 y 8. `nutrition_core` sin cambios. Normalización de números con
  `parseDecimal` (SPEC-030).

## Components / Files Affected
- `app/lib/infra/storage/` (columna, migración, `updatePersonalProduct`, exportación),
  `app/lib/infra/food_resolution/food_query_resolver.dart` (`personalProductToFoodCatalogEntry`),
  `app/lib/features/settings/my_products_screen.dart`, `docs/privacy.md`, `docs/architecture.md`.

## Dependencies
- SPEC-030, SPEC-033, SPEC-034, SPEC-043.

## Edge Cases
- Producto en ml (leche): "Peso de una unidad" se escribe en ml ("un vaso = 200 ml").
- Peso de unidad igual a la porción: válido.
- En "Buscar alimento" (SPEC-018), un producto con peso de unidad ofrece "Unidad" primero (preseleccionada).
- "1 porción" sigue usando la porción de la etiqueta.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No. Dato nuevo local → `docs/privacy.md` (inventario).

## Tests Required
- Unit: AC1, AC2. Widget: AC1, AC3. Integration: AC4. Regresión: AC5. Manual: "dos huevos" con el
  producto "huevo" en el teléfono.

## Out of Scope
- Pedir el peso de la unidad al confirmar una etiqueta nueva (se puede añadir después).
- Varias unidades distintas por producto (tajada, paquete…).

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC6 con evidencia · analyze y tests verdes en `app` · reviewer PASS enlazado · docs actualizados ·
  aprobación explícita de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-10: creación a partir del hallazgo en la prueba de SPEC-024 ("con qué seguimos").
- 2026-10-10: **Approved por la usuaria** ("aprobada la SPEC-045"). Status → Implementing.
- 2026-10-10: implementada. Detalles menores: `isValidUnitGrams` en el repositorio (también rechaza un
  valor inválido); el campo muestra la unidad del producto (g o ml); el helper `_tapButton` de
  `my_products_screen_test.dart` ahora desplaza la lista hasta el botón (el campo nuevo lo dejó fuera
  de la pantalla), sin cambiar lo que verifica; los tests de migración esperan la versión 11. Con peso
  de unidad, la búsqueda manual (SPEC-018) también ofrece "Unidad" para ese producto. app 549/549.
- 2026-10-10: reviewer PASS con MINOR. Corregidos o documentados: en "Buscar alimento", con peso de
  unidad, "Unidad" aparece primero y queda preseleccionada (antes "Porción"), con test; AC2 comprueba
  también el respaldo de 60 g y Estimación; el campo acepta un decimal como máximo y el mensaje lo dice
  ("55,55" → mensaje), así lo guardado y lo mostrado coinciden. Al backlog: T-046 (en "Buscar alimento"
  la opción dice "g" aunque el producto sea en ml). app 552/552.
- 2026-10-10: prueba de la usuaria en su S25: con peso de unidad 70 g, "dos huevos" mostró "2,3
  porciones" (140 g ÷ porción de etiqueta de 60 g): el cálculo era correcto pero la presentación
  confundía. **R6 y AC6 aprobados por la usuaria** ("sí, apruebo el R6"). Implementado
  (`ReviewController.showsUnits`; −/+ de a una unidad; `setPortions` usa la regla de unidades). app
  554/554.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/review/products_by_unit_test.dart` › "AC1: con peso de unidad 60…" (unidad) y "AC1: "dos huevos" en el detalle…" (pantalla) |
| AC2 | ✅ | mismo archivo › "AC2…" |
| AC3 | ✅ | mismo archivo › grupo "AC3: "Editar producto"" ("55,5", vacío, 0, -3, 5001, abc) |
| AC4 | ✅ | mismo archivo › "AC4: migrar desde la v10…" |
| AC5 | ✅ | app 554/554; tests de resolución sin cambios; migraciones esperan 11 |
| AC6 | ✅ | `products_by_unit_test.dart` › "R6: dicho en unidades…" y "R6: dicho en porciones…" |
| Manual | ⏳ | "dos huevos" con el producto "huevo" en el teléfono, pendiente |

## Review
Revisión (2026-10-10, subagente `reviewer`, sobre `6c9698e`): **PASS** con MINOR (ver Change Log).
AC1–AC5 con evidencia; `nutrition_core`, prompts y catálogo sin cambios; el peso lo escribe la persona
(invariante 8); "porcion" sigue mandando en SPEC-033 y SPEC-043; migración, exportar y borrar todo;
privacidad al día. Falta la prueba manual.
