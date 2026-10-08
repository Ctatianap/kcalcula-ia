# SPEC-042: Conversiones de porciones y "por 100 g" en nutrition_core

## Status
Implementing
Path: Strict (toca `nutrition_core`: cálculo y unidades)

## Objective
Que las conversiones entre gramos (o ml), porciones y valores "por 100 g" que hoy hace la app vivan en
`nutrition_core`, con casos de referencia, sin cambiar ningún resultado visible.

## Context
Backlog T-035, hallazgos de los reviewers de SPEC-026 y SPEC-033. La invariante 3 dice que todo cálculo
nutricional vive en `packages/nutrition_core`, pero hoy la app hace estas cuentas por su cuenta:
- `label_confirmation_controller.dart` (SPEC-004/032):
  - `_derivePerServing`: por 100 g → por porción (`× porción / 100`), cuando la etiqueta solo trae la
    columna "por 100 g".
  - `_per100`: por porción → por 100 g (`× 100 / porción`), para guardar el producto y la vista previa.
  - `consumedQuantity`: porciones × porción.
  - `setConsumedUnit`: g/ml ÷ porción → porciones.
- `review_controller.dart`:
  - `portionsOf` (SPEC-033 R5): gramos ÷ porción → porciones.
  - `_snapshotFood` (SPEC-026): instantánea guardada → por 100 g (`× 100 / gramos`; 0 si los gramos son 0).

## User Story
Como responsable del producto, quiero que todo cálculo nutricional esté en un solo lugar probado, para
que un cambio de reglas no deje cuentas distintas en distintas pantallas.

## Requirements
- R1. `nutrition_core` expone funciones puras, documentadas en español:
  - `portionsForAmount(amount, portionAmount)` → porciones (`amount / portionAmount`); `null` si
    `portionAmount ≤ 0`.
  - `amountForPortions(portions, portionAmount)` → g/ml (`portions × portionAmount`); `null` si
    `portionAmount ≤ 0`.
  - `per100FromAmount(value, amount)` → valor por 100 g/ml (`value × (100 / amount)`); `null` si
    `amount ≤ 0`.
  - `amountFromPer100(valuePer100, amount)` → valor para esa cantidad (`valuePer100 × (amount / 100)`);
    `null` si `amount ≤ 0`.
  Misma aritmética y mismo orden de operaciones que el código actual, para que los resultados sean
  idénticos. Sin redondeo (invariante 3: se redondea solo al presentar).
- R2. La app usa esas funciones en los seis lugares del Context y deja de hacer esas cuentas por su
  cuenta. Donde hoy hay un valor por defecto para entradas inválidas (por ejemplo 0 en
  `_snapshotFood` o en `consumedQuantity` sin porción válida), la app lo conserva a partir del `null`.
- R3. Ningún resultado visible cambia: porciones, gramos, kcal, macros, vista previa y lo que se guarda
  en `user.db` quedan iguales.

## Acceptance Criteria
- AC1. Casos de referencia en `packages/nutrition_core/test/portion_conversion_test.dart` `[unit]`:
  - `portionsForAmount(45, 30)` = 1,5 · `portionsForAmount(30, 30)` = 1 · `portionsForAmount(10, 0)` = null.
  - `amountForPortions(3, 27)` = 81 · `amountForPortions(0.5, 200)` = 100 · `amountForPortions(2, 0)` = null.
  - `per100FromAmount(150, 30)` = 500 · `per100FromAmount(1.5, 30)` = 5 · `per100FromAmount(5, 0)` = null.
  - `amountFromPer100(500, 30)` = 150 · `amountFromPer100(48, 27)` = 12,96 · `amountFromPer100(10, 0)` = null.
  - Ida y vuelta: `amountFromPer100(per100FromAmount(v, a), a)` = v (±1e-9) para varios v y a.
  - Negativos: `portionAmount` o `amount` negativos → null.
- AC2. `git grep` en `app/lib` no encuentra las fórmulas movidas (`100 / servingQuantity`,
  `servingQty / 100`, `100 / item.grams`, `item.grams / portionGrams`, `consumedQuantity / servingQuantity`,
  `portionsCount * servingQuantity`) `[manual + reviewer]`.
- AC3. Todos los tests existentes de `app` y `nutrition_core` siguen verdes **sin cambiar expectativas**
  (incluidos los de SPEC-026, SPEC-032 y SPEC-033) `[unit + widget]`.
- AC4. `dart analyze` y `flutter analyze` sin avisos `[manual]`.

## Technical Constraints
- `nutrition_core` sin Flutter ni red (invariante 3). Funciones nuevas exportadas desde
  `nutrition_core.dart`.
- No se escribe ningún valor nutricional de fuentes: los números de AC1 son entradas de prueba de la
  aritmética, no datos del catálogo (invariante 8 no aplica).

## Components / Files Affected
- Nuevo: `packages/nutrition_core/lib/src/portion_conversion.dart` y su test.
- `packages/nutrition_core/lib/nutrition_core.dart` (export).
- `app/lib/features/capture/label_confirmation_controller.dart`.
- `app/lib/features/review/review_controller.dart`.

## Dependencies
- SPEC-026, SPEC-032, SPEC-033.

## Edge Cases
- Porción 0 o negativa: las funciones devuelven `null`; la app mantiene su comportamiento actual.
- Instantánea con 0 g (SPEC-026): por 100 g queda en 0, como hoy.
- Nutrientes opcionales (fibra, azúcar, sodio) ausentes: siguen ausentes (la app no llama la función).

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No.

## Tests Required
- Unit (`nutrition_core`): AC1. Regresión: AC3. Manual/reviewer: AC2, AC4.

## Out of Scope
- Cambiar reglas de porciones, redondeo o confianza.
- `resolveGrams` (ya está en `nutrition_core`).
- Cambios visibles en la app.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC4 con evidencia · analyze y tests verdes en `nutrition_core` y `app` · reviewer PASS enlazado ·
  aprobación explícita de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-08: creación (backlog T-035) a pedido de la usuaria ("continua con la 035").
- 2026-10-08: **Approved por la usuaria** ("si"). Status → Implementing.
- 2026-10-08: implementada. `portion_conversion.dart` (4 funciones) y 18 casos de referencia;
  la app las usa en los seis lugares. Detalle: `portionsOf` con una porción de 0 g daba infinito y
  ahora da `null` (no ocurre: la porción guardada siempre es > 0 por `isValidServingGrams`).
  nutrition_core 105/105, app 451/451 sin cambiar expectativas.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `packages/nutrition_core/test/portion_conversion_test.dart` (incluye ida y vuelta y negativos) |
| AC2 | ✅ | `git grep` de las seis fórmulas (y de `* factor`) en `app/lib`: sin resultados |
| AC3 | ✅ | nutrition_core 105/105; app 451/451; ningún test existente cambió |
| AC4 | ✅ | `dart analyze` y `flutter analyze`: sin avisos |

## Review
Informe del reviewer:
