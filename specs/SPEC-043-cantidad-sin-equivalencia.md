# SPEC-043: Cantidad sin equivalencia en el catálogo

## Status
Implementing
Path: Strict (toca `nutrition_core`: unidades y confianza)

## Objective
Que una cantidad que el catálogo no sabe convertir (p. ej. "2 unidades" de un alimento sin porción
"unidad") quede como **Estimación**, destacada para corregir y con una explicación cierta, en vez de
"Buena estimación".

## Context
Backlog T-041, hallazgo del reviewer de SPEC-023. Hoy, si `resolveGrams` no puede resolver la cantidad
(unidad, tamaño o medida casera sin porción ni densidad en el catálogo), `ReviewController` usa unos
gramos de respaldo (la primera porción del alimento o 100 g) calculados en la app, pero la confianza
sale de la base que se intentó: con "unidad" queda **Buena estimación**, y "¿Por qué?" dice que la
unidad se convierte "con el peso típico que trae la base", lo cual es falso. Además ignora el número
dicho ("2 unidades" = una porción). Invariante 3 (cálculo en `nutrition_core`) e invariante 4
(confianza por reglas). Principio: "sin inventar precisión".

## User Story
Como persona que registra, quiero que la app me diga cuándo no pudo convertir mi cantidad, para
corregirla en vez de confiar en un número inventado.

## Requirements
- R1. `nutrition_core` resuelve el respaldo: cuando la cantidad no se puede convertir, una función
  pura devuelve los gramos de una porción típica del alimento (la porción "porcion" si existe; si no,
  la primera porción del catálogo; si no tiene porciones, 100 g, como hoy) con base `defaultPortion` y
  una marca de "cantidad sin equivalencia". La app deja de calcular ese respaldo.
- R2. Regla de confianza: una cantidad sin equivalencia es siempre **Estimación**
  (`docs/architecture.md`, sección Confianza, se actualiza).
- R3. El ingrediente sigue destacado para editar (como hoy) y su texto de origen dice "Sin
  equivalencia · ajústala".
- R4. "¿Por qué?" (SPEC-023) muestra una razón nueva: "Sin equivalencia: no tenemos cuánto pesa
  «unidad» (o «pequeño», «taza»…) de este alimento, así que usamos una porción típica.", con "Escribe
  los gramos" y "Usa la etiqueta".
- R5. Lo que ya está guardado no cambia (las comidas guardadas conservan su confianza).
- R6. Sin IA y sin datos nuevos que salgan del dispositivo.

## Acceptance Criteria
- AC1. `nutrition_core`: un alimento sin porción "unidad" con "2 unidad" → no resoluble; el respaldo
  da la porción típica del alimento, base `defaultPortion`, marcado sin equivalencia; `itemConfidence`
  con esa marca → Estimación `[unit, casos de referencia]`.
- AC2. Respaldo sin porciones → 100 g; con porción "porcion" → esa; sin "porcion" pero con otras → la
  primera `[unit]`.
- AC3. Detalle de "2 unidades de pechuga de pollo" (el catálogo de prueba no tiene "unidad" para la
  pechuga): el ingrediente dice "Sin equivalencia · ajústala", indicador **Estimación**, y la comida
  queda en Estimación si aporta ≥ 15 % `[widget]`.
- AC4. "¿Por qué?" de ese ingrediente muestra la razón de R4; "Escribe los gramos" 150 → "Peso dicho
  por ti", Buena estimación `[widget]`.
- AC5. Las cantidades que sí se convierten no cambian: tests existentes de `nutrition_core`
  (quantity_resolution, confidence) y de la app verdes sin cambiar expectativas `[unit + widget]`.
- AC6. Guardar esa comida guarda `confidence = estimacion` y `quantity_basis = defaultPortion` en el
  ítem `[integration]`.

## Technical Constraints
- Invariantes 3 y 4. Sin valores nutricionales nuevos: la porción del respaldo viene del catálogo
  (con su fuente) o es el 100 g de referencia de los valores por 100 g.

## Components / Files Affected
- `packages/nutrition_core/lib/src/quantity_resolution.dart`, `confidence.dart` y sus tests.
- `app/lib/features/review/review_controller.dart`, `meal_detail_view.dart` (texto de origen),
  `app/lib/ui/confidence_texts.dart` (razón nueva).
- `docs/architecture.md` (Confianza).

## Dependencies
- SPEC-023.

## Edge Cases
- Cantidad vaga sin equivalencia: sigue siendo Estimación (ya lo era).
- Producto personal (etiqueta): siempre tiene porción "porcion", así que el respaldo es su porción.
- Cambiar el alimento ("¿Cuál de estos?", "Elegir de mis productos") vuelve a resolver con las reglas.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No.

## Tests Required
- Unit (`nutrition_core`): AC1, AC2 con casos de referencia. Widget: AC3, AC4. Integration: AC6.
  Regresión: AC5. Manual: un ingrediente sin equivalencia en el teléfono.

## Out of Scope
- Añadir porciones al catálogo (eso es `nutrition-data`).
- Pedir a la IA otra unidad.
- Recalcular comidas ya guardadas.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC6 con evidencia · analyze y tests verdes en `nutrition_core` y `app` · reviewer PASS enlazado ·
  `docs/architecture.md` actualizado · aprobación explícita de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-08: creación (backlog T-041) a pedido de la usuaria ("dale").
- 2026-10-08: **Approved por la usuaria** ("apruebo"). Status → Implementing.
- 2026-10-08: implementada. `fallbackResolution` y `fallbackReferenceGrams` en
  `quantity_resolution.dart`; `itemConfidence(..., withoutEquivalence)`; `ReviewItem.withoutEquivalence`;
  razón `withoutEquivalence` en `confidence_texts.dart`. Detalles menores:
  - Si después se usa una etiqueta para ese ingrediente (SPEC-033) y lo dicho no tenía equivalencia, la
    cantidad elegida en "Confirmar etiqueta" pasa con su base y su confianza (antes solo cambiaban los
    gramos y quedaba "Buena estimación" de `unit_portion`). Por eso `ingredient_actions_test.dart` ›
    "AC3: 1 scoop…" ahora espera "De tu etiqueta" (destacado) en vez de "Cantidad dicha por ti": es
    justo el caso de T-041. El resto de tests no cambió.
  - `confidence_visual_test.dart` (SPEC-023 AC4) incluye la razón nueva en el conjunto que recorre.
  - nutrition_core 112/112, app 505/505.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `packages/nutrition_core/test/fallback_resolution_test.dart` › grupo "AC1…" |
| AC2 | ✅ | mismo archivo › grupo "AC2…" |
| AC3 | ✅ | `app/test/features/review/without_equivalence_test.dart` › "AC3…" |
| AC4 | ✅ | mismo archivo › "AC4…" |
| AC5 | ✅ | `quantity_resolution_test.dart` y `confidence_test.dart` sin cambios; app 505/505 (un test de SPEC-033 cambia a propósito, ver Change Log) |
| AC6 | ✅ | `without_equivalence_test.dart` › "AC6…" |
| Manual | ⏳ | Un ingrediente sin equivalencia en el teléfono, pendiente |

## Review
Informe del reviewer:
