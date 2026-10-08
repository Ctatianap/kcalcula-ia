# SPEC-032: Cantidad en porciones y vista previa en "Confirmar etiqueta"

## Status
Implementing
Path: Standard (cambia cómo se indica la cantidad y muestra un cálculo que ya existe en
`nutrition_core`; no cambia reglas de cálculo, la IA ni el catálogo)

## Objective
Que en "Confirmar etiqueta" la persona pueda decir cuánto comió en **porciones** ("3 porciones")
además de en gramos, y vea, antes de seguir, cuántas calorías, proteína, carbohidratos y grasa va a
registrar.

## Context
Backlog T-032. Pedido de la usuaria al probar SPEC-031 en el teléfono (2026-10-07):
- "a veces no sé cuántos gramos son, por ejemplo de ese pan […] comí 3 porciones".
- Escribió 45 en "¿Cuánto comiste?" y "los valores no actualizan". Está bien que los campos por
  porción no cambien, pero "abajo, después de cuánto comiste, sería bueno mostrar la proteína,
  carbos y grasas que va a registrar", parecido a las tarjetas de proteína, carbohidratos y grasa
  de "Hoy".
- "No me deja revisar, solo me dice guardar y continuar": no queda claro que el botón lleva a
  Revisar, donde se guarda la comida en el diario.

Hoy "¿Cuánto comiste?" solo acepta g o ml (SPEC-004 R5) y la cantidad por defecto es la porción
(SPEC-031). El cálculo de lo que se registra lo hace Revisar con `calculateItemNutrients`
(SPEC-004 R6).

## User Story
Como persona que no sabe cuántos gramos comió, quiero decir "3 porciones" y ver qué voy a
registrar antes de seguir, para no adivinar.

## Requirements
- R1. **Unidad de "¿Cuánto comiste?":** un selector con **porciones** y la unidad de la etiqueta
  (g o ml). Arranca en **porciones con "1"**. Acepta decimales como en SPEC-030 ("1,5").
- R2. **Porciones → g/ml:** con porciones, la cantidad que se registra es número de porciones ×
  porción de la etiqueta. Si la persona cambia la porción, la cantidad registrada cambia con ella
  (3 porciones siguen siendo 3 porciones). Con g/ml, se comporta como en SPEC-031.
- R3. **Cambiar de unidad conserva la cantidad:** pasar de "3 porciones" (porción de 27 g) a g
  muestra "81"; pasar de "81 g" a porciones muestra "3".
- R4. **Vista previa "Vas a registrar":** debajo de "¿Cuánto comiste?" se muestra:
  - la equivalencia ("3 porciones = 81 g"), solo con porciones;
  - las kcal (~210 kcal);
  - tres tarjetas de proteína, carbohidratos y grasa, con el mismo estilo de "Hoy" (`ProgressRing`):
    los gramos de esta comida y, si hay meta, el anillo como parte de la meta del día ("de 123 g").
    Sin meta, solo los gramos.

  Se actualiza al cambiar cualquier campo. Los valores salen de `calculateItemNutrients` de
  `nutrition_core`, con el mismo producto equivalente que usa Revisar, así que coinciden con lo que
  Revisar mostrará. Se redondea solo para mostrar.
- R5. **Sin vista previa si faltan datos:** si "Falta: …" no está vacío, la vista previa no se
  muestra (no hay números que mostrar).
- R6. **El botón dice lo que hace:** "Guardar y continuar" pasa a **"Revisar comida"**, con una
  línea debajo: "Guardamos el producto en tus productos y revisas la comida antes de añadirla a tu
  diario." Lo que pasa al tocarlo no cambia (guarda el producto personal y abre Revisar).

## Acceptance Criteria
- AC1. Etiqueta con porción de 27 g → "¿Cuánto comiste?" arranca en "1" con porciones; escribir "3"
  → la vista previa dice "3 porciones = 81 g" y, al tocar "Revisar comida", llega a Revisar
  `quantity` 81 y `unit` "g" `[widget]`.
- AC2. Con "3" porciones, cambiar la porción a "30" → "3 porciones = 90 g" y se registra 90
  `[widget]`.
- AC3. "3" porciones → cambiar a g muestra "81"; escribir "54" y volver a porciones muestra "2"
  `[widget]`.
- AC4. Etiqueta de 27 g con 70 kcal, P 2,8, C 15 y G 0,2 por porción, y "3" porciones → la vista
  previa muestra ~210 kcal y 8,4 g, 45 g y 0,6 g, los mismos valores que da
  `calculateItemNutrients` para 81 g del producto equivalente `[widget + unit]`.
- AC5. Con meta (P 123 g, C 184 g, G 46 g), las tarjetas dicen "de 123 g", "de 184 g" y "de 46 g";
  sin meta, solo los gramos `[widget]`.
- AC6. Con proteína vacía → aparece "Falta: proteína." y no aparece la vista previa `[widget]`.
- AC7. El botón dice "Revisar comida", tiene la línea de R6 debajo y abre Revisar como antes
  `[widget]`.
- AC8. Los tests existentes siguen verdes. Cambian las expectativas que dependen del texto del
  botón y de la cantidad por defecto en g, y se listan en la Verificación `[widget + unit]`.

## Technical Constraints
- Invariante 3: el cálculo de la vista previa vive en `nutrition_core` (`calculateItemNutrients`);
  la pantalla solo lo muestra. Sumar sin redondear y redondear al presentar.
- Las features no se importan entre sí: las tarjetas reutilizan `app/lib/ui/components/` (mover
  ahí la tarjeta de macro de "Hoy" si hace falta), no `features/diary`.
- La meta del día se lee por `infra/` (como "Hoy"), no directamente de Drift.

## Components / Files Affected
- `app/lib/features/capture/label_confirmation_screen.dart` y `label_confirmation_controller.dart`.
- `app/lib/ui/components/` (tarjeta de macro compartida, si se extrae de "Hoy").
- `app/lib/features/diary/diary_screen.dart` (solo si se extrae la tarjeta; sin cambio visual).
- Tests: `app/test/features/capture/label_confirmation_*_test.dart`.

## Dependencies
- SPEC-004 (R5, R6), SPEC-008 (meta), SPEC-011 (tarjetas de "Hoy"), SPEC-030, SPEC-031.

## Edge Cases
- Porción vacía o no válida: con porciones no hay cantidad; "Falta: porción, cuánto comiste." y
  sin vista previa.
- "0" porciones: no válido ("Falta: cuánto comiste.").
- Etiqueta en ml: el selector dice porciones / ml y la equivalencia "2 porciones = 400 ml".
- Valores muy pequeños: la vista previa redondea igual que "Hoy" (`formatMacroEs`).

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No.

## Tests Required
- Unit: AC4 (paridad con `calculateItemNutrients`).
- Widget: AC1–AC8.
- Manual: en el teléfono, decir "3 porciones" del pan y ver la vista previa.

## Out of Scope
- Porciones en el registro por texto o voz ("3 porciones de pan"): ya las maneja la IA y el
  catálogo por separado.
- Cambiar los campos "por porción" de arriba.
- Guardar directamente en el diario sin pasar por Revisar.

## Open Questions
- Ninguna. Decisiones tomadas: arranca en porciones con 1 (equivale a la porción, como hoy) y el
  botón cambia de texto, no de comportamiento.

## Definition of Done
- AC1–AC8 con evidencia · analyze y tests verdes en `app` · prueba manual · reviewer PASS enlazado.

## Change Log
- 2026-10-07: creación a partir del pedido de la usuaria al probar SPEC-031. Backlog T-032.
- 2026-10-07: **Approved por la usuaria** ("sí, apruebo"; antes: "si me gusta el selector de porciones
  o los g/ml"). SPEC-031 ya fusionada. Status → Implementing.
- 2026-10-07: implementada. Controlador: `ConsumedUnit`, `portionsCount`, `registeredQuantity`,
  `setConsumedUnit` (cambiar de unidad no cuenta como editar la cantidad, para no romper SPEC-031),
  `_per100()` compartido por `save()` y `preview` (`resolveGrams` + `calculateItemNutrients`).
  Pantalla: `SegmentedButton`, `_Preview`, botón "Revisar comida". Tarjetas de macros extraídas de
  "Hoy" a `app/lib/ui/components/macro_cards.dart` (sin cambio visual).

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/capture/label_confirmation_screen_test.dart` › "SPEC-032 AC1…": arranca en "1"; "3" → "3 porciones = 81 g"; Revisar recibe `cantidad=81.0` y `unidad=g` |
| AC2 | ✅ | mismo archivo › "SPEC-032 AC2…": porción 30 → "3 porciones = 90 g", el campo sigue en "3" y se registran 90 |
| AC3 | ✅ | mismo archivo › "SPEC-032 AC3…": "3" porciones → g "81"; "54" → porciones "2" |
| AC4 | ✅ | widget: "SPEC-032 AC4…" (~210 kcal; 8,4 / 45,0 / 0,6). Unit: `label_confirmation_controller_test.dart` › "SPEC-032 AC4: la vista previa da lo mismo que Revisar…" (igual a `calculateItemNutrients` sobre el producto guardado por 100 g) |
| AC5 | ✅ | "SPEC-032 AC5: con meta…" y "…sin meta, solo los gramos". Nota: las tarjetas muestran "de 123,0 g" (un decimal, `formatMacroEs`), igual que "Hoy", porque usan el mismo componente (`app/lib/ui/components/macro_cards.dart`) |
| AC6 | ✅ | "SPEC-032 AC6: sin proteína no hay vista previa" |
| AC7 | ✅ | "SPEC-032 AC7…": botón "Revisar comida", la línea de R6 y navega a Revisar |
| AC8 | ✅ | app: analyze sin avisos, 354/354. Expectativas cambiadas: el texto del botón (`reviewMealButtonLabel`) en `label_confirmation_screen_test.dart`, `integration/label_to_review_flow_test.dart` y `integration/storage_errors_test.dart`; "AC2/AC4: muestra los valores transcritos" (antes "30" dos veces; ahora "30" en la porción y "1" en porciones); los tests de SPEC-004 AC5 y de SPEC-031 y el flujo "comí 45 g" pasan primero a g (`_toGrams`); el helper `_tapSave` cierra el teclado antes de tocar el botón. Tests de "Hoy" sin cambios tras extraer las tarjetas |
| Manual | ⏳ | "3 porciones" del pan en el teléfono |

## Review
Informe del reviewer:
