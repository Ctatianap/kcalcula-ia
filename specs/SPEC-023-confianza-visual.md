# SPEC-023: Confianza visual

## Status
Implementing
Path: Standard (presentación de la confianza ya calculada por reglas; no cambia la regla ni el
cálculo)

## Objective
Que la persona entienda de un vistazo qué tan precisa es cada cifra y qué puede hacer para mejorarla,
sin colores de alarma.

## Context
Fase F2 de `docs/backlog.md` ("confianza visual"). La confianza se calcula por reglas
(`docs/architecture.md`, sección Confianza; invariante 4) y hoy se muestra como texto ("Buena
estimación") en la tarjeta de kcal del detalle (SPEC-012) y como "~" en Hoy, Historial y Progreso.
Cada ingrediente del detalle ya dice cómo se obtuvo su cantidad ("Cantidad dicha por ti", "Tamaño
estimado · ajústalo", "De tu etiqueta"), y su menú ⋮ ofrece "Usar etiqueta" y "Elegir de mis
productos" (SPEC-033). Principio del producto: "sin inventar precisión".

## User Story
Como persona que registra, quiero ver qué parte de mi comida es estimada y cómo afinarla, para confiar
en los números.

## Requirements
- R1. **Indicador de 3 niveles** (componente de `ui/components/`): Alta precisión (círculo lleno),
  Buena estimación (círculo a medias) y Estimación (círculo en contorno), con ícono y texto (nunca solo
  color), en tonos del sistema visual (SPEC-010, sin rojo ni verde de alarma).
- R2. **Detalle de comida:** el indicador en la tarjeta de kcal y un indicador pequeño por ingrediente.
- R3. **"¿Por qué?":** tocar el indicador abre una hoja con la explicación en español de la regla que
  aplicó (p. ej. "Tamaño estimado: la porción viene de una medida típica, no de un peso") y una acción
  para mejorarla cuando exista: "Escribe los gramos" (lleva al ajuste de cantidad del ingrediente) y
  "Usa la etiqueta" (abre el mismo flujo de "Usar etiqueta" de SPEC-033: foto, galería o escribir los
  valores). En la tarjeta de kcal, la hoja explica la regla del 15 % y nombra los ingredientes que
  tienen el nivel de la comida.
- R4. **Hoy e Historial:** las tarjetas de comida muestran el indicador de la comida (mismo
  componente); el "~" se mantiene en los totales.
- R5. Lectura accesible: cada indicador tiene etiqueta semántica ("Confianza: buena estimación").

## Acceptance Criteria
- AC1. Para cada nivel, el indicador muestra su ícono y su texto, y su etiqueta semántica `[widget]`.
- AC2. En el detalle de "dos huevos (unidad) y una arepa pequeña", la arepa muestra "Estimación", el
  huevo "Buena estimación" y la tarjeta el nivel de la comida según la regla del 15 % `[widget]`.
- AC3. Tocar el indicador de la arepa abre la explicación de `size_descriptor` y la acción "Escribe
  los gramos", que pide la cantidad exacta en g (o ml); al escribirla, la cantidad pasa por las reglas
  de `nutrition_core` y el ingrediente queda como "Peso dicho por ti" (Buena estimación) `[widget]`.
- AC4. Las explicaciones cubren las 6 bases de `QuantityBasis`, el uso de densidad por defecto, la
  porción curada y la cantidad vaga; un test recorre todas `[unit]`.
- AC5. Ningún color del indicador es rojo ni verde de alarma; contraste ≥ 3:1 para el ícono `[unit]`.
- AC6. Las tarjetas de comida de Hoy y del Historial muestran el indicador del nivel guardado de la
  comida, y los totales conservan el "~" `[widget]`.

## Technical Constraints
- Invariante 4: el nivel siempre sale de `nutrition_core`; la UI solo lo presenta. Las explicaciones
  describen la regla, no inventan cifras.

## Components / Files Affected
- `app/lib/ui/components/` (indicador y hoja), `app/lib/features/review/`, `app/lib/features/diary/`,
  `app/lib/features/history/`.

## Dependencies
- SPEC-010, SPEC-011, SPEC-012, SPEC-013.

## Edge Cases
- Ítem sin resolver (no encontrado o ambiguo): sin indicador.
- Comida guardada antes de esta SPEC: usa la confianza guardada.
- Texto grande ×2 en 360 px sin desbordes.

## Security & Privacy
- No sale ningún dato del dispositivo.

## Tests Required
- Unit: AC4, AC5. Widget: AC1–AC3, AC6. Manual: recorrido en el teléfono con TalkBack.

## Out of Scope
- Cambiar la regla de confianza, porcentajes de error, confianza de la IA.

## Open Questions
- Ninguna. Resueltas con la opción recomendada (2026-10-08): íconos de círculo lleno / a medias /
  contorno (no hay artboard de este componente); "Usa la etiqueta" abre el flujo de SPEC-033 (foto,
  galería o escribir valores) en vez de la cámara directa, para no gastar IA cuando la persona
  prefiere escribir.

## Definition of Done
- AC1–AC6 con evidencia · analyze y tests verdes · reviewer PASS enlazado · arquitectura actualizada
  (componente de confianza).

## Change Log
- 2026-10-04: creación a partir de F2 ("confianza visual").
- 2026-10-08: actualizada antes de pedir aprobación: contexto con lo que ya muestra el detalle
  (SPEC-033), íconos y acción de etiqueta decididos con la opción recomendada, explicación en la
  tarjeta de kcal.
- 2026-10-08: **Approved por la usuaria** ("aprobado"). Status → Implementing.
- 2026-10-08: implementada. La implementación pidió dos cambios de texto (aprobados después, ver abajo):
  1. R3: la hoja de la comida nombra "los ingredientes que tienen el nivel de la comida", no "los que
     bajan el nivel": saber cuáles lo bajan exige repetir en la app la regla del 15 % (invariante 4 y
     3; eso sería Strict, en `nutrition_core`). Lo que se muestra es exacto sin recalcular la regla.
  2. AC3: "Escribe los gramos" abre un campo para escribir la cantidad exacta en vez de solo enfocar
     los botones −/+ (que no permiten escribir). La cantidad escrita pasa por `resolveGrams` e
     `itemConfidence` (`ReviewController.setWrittenQuantity`), así que el nivel mejora por la regla, no
     por la UI.
  Otros detalles: los nombres de los niveles viven con el indicador (`confidenceLevelLabels`); la razón
  de cada ingrediente se deduce de su base, si era vaga y su nivel (`confidenceReasonFor`, sin cálculo);
  "Usa la etiqueta" abre el flujo de SPEC-033 del ingrediente. `label_to_review_flow_test.dart` ahora
  espera "Alta precisión" dos veces (comida e ingrediente, R2). app 477/477.
- 2026-10-08: **la usuaria aprobó los dos cambios** (R3 y AC3) ("si").
- 2026-10-08: reviewer PASS (manual con TalkBack pendiente). MINOR corregidos: test cruzado que recorre
  las combinaciones de `itemConfidence` que produce `resolveGrams` y comprueba la razón deducida; AC3
  comprueba "Cantidad dicha por ti" y la razón "Peso dicho por ti" después de escribir; la medida
  casera menciona la densidad; Historial comprueba el "~"; área táctil de 48 dp en el indicador.
  Al backlog: T-041 (gramos de respaldo con "Buena estimación", Strict), T-042 (helper repetido) y
  T-043 (test inestable de exportar). app 479/479.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/review/confidence_visual_test.dart` › "AC1…" |
| AC2 | ✅ | mismo archivo › "AC2…" |
| AC3 | ✅ | mismo archivo › "AC3…" |
| AC4 | ✅ | mismo archivo › "AC4…" |
| AC5 | ✅ | mismo archivo › "AC5…" (`KColors.accent`, contraste contra blanco y tarjeta) |
| AC6 | ✅ | mismo archivo › "AC6: Hoy e Historial…" |
| Manual | ⏳ | Recorrido en el teléfono con TalkBack, pendiente |

## Review
Revisión (2026-10-08, subagente `reviewer`, sobre `bb3e0e7`): **PASS** con MINOR (corregidos o al
backlog, ver Change Log). AC1–AC6 con evidencia; invariante 4: el nivel sale de `itemConfidence` y
`mealConfidence`, la UI solo lo presenta; invariante 3 en `setWrittenQuantity`; un solo tono azul, sin
rojo ni verde; fronteras respetadas; nada sale del dispositivo. Falta la prueba manual con TalkBack.
