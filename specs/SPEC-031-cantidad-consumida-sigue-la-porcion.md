# SPEC-031: "¿Cuánto comiste?" sigue a la porción en pantalla

## Status
Implementing
Path: Standard (cambia la cantidad que ve la persona antes de registrar; no toca `nutrition_core`,
la IA ni el catálogo)

## Objective
Que en "Confirmar etiqueta" lo que se ve en "¿Cuánto comiste?" sea siempre lo que se va a
registrar.

## Context
Backlog T-031. El reviewer de SPEC-030 lo señaló y se confirmó en el teléfono el 2026-10-07: con la
porción en 27 g, al cambiarla a 30 el campo "¿Cuánto comiste?" siguió mostrando 27.

SPEC-004 R5 dice que, si la persona no da otra cantidad, se usa la porción. El controlador lo
cumple (`setServingQuantity` actualiza `consumedQuantity` mientras la persona no haya tocado ese
campo), pero la pantalla llena el texto de "¿Cuánto comiste?" una sola vez, en `initState`. Por eso
se registrarían 30 g mientras la persona ve 27.

## User Story
Como persona que corrige la porción de una etiqueta, quiero que "¿Cuánto comiste?" cambie con ella,
para registrar lo que veo.

## Requirements
- R1. Mientras la persona no haya editado "¿Cuánto comiste?", el campo muestra la porción vigente:
  cambia cada vez que cambia la porción, con el formato de SPEC-030 ("27", "27,5").
- R2. Si la porción queda vacía o no es válida, "¿Cuánto comiste?" queda vacío (hoy el controlador
  usa 0) y "Falta: …" incluye "cuánto comiste".
- R3. Cuando la persona edita "¿Cuánto comiste?", deja de seguir a la porción (como hoy en el
  controlador) y la pantalla no vuelve a reescribir ese campo.
- R4. Siempre se registra lo que muestra el campo: el valor de `consumedQuantity` al guardar
  coincide con el texto de "¿Cuánto comiste?" (interpretado como en SPEC-030).

## Acceptance Criteria
- AC1. Una etiqueta con porción de 27 g; cambiar la porción a "30" → "¿Cuánto comiste?" muestra
  "30" y, al guardar, el ítem que llega a Revisar tiene `quantity` 30 `[widget]`.
- AC2. Cambiar la porción a "27,5" → "¿Cuánto comiste?" muestra "27,5" `[widget]`.
- AC3. Borrar la porción → "¿Cuánto comiste?" queda vacío, aparece "Falta: porción, cuánto
  comiste." y Guardar está deshabilitado `[widget]`.
- AC4. Escribir "45" en "¿Cuánto comiste?" y luego cambiar la porción a "30" → el campo sigue en
  "45" y se registra 45 `[widget]`.
- AC5. Los tests existentes de `label_confirmation_*_test.dart` siguen verdes sin cambiar sus
  expectativas `[widget + unit]`.

## Technical Constraints
- La regla de qué cantidad usar sigue en el controlador (SPEC-004 R5); la pantalla solo refleja su
  valor.
- Invariante 3: el campo muestra el valor formateado; el controlador conserva el original.

## Components / Files Affected
- `app/lib/features/capture/label_confirmation_screen.dart` (actualizar el texto de "¿Cuánto
  comiste?").
- `app/lib/features/capture/label_confirmation_controller.dart` (exponer si la persona ya editó la
  cantidad, si hace falta).
- Tests: `app/test/features/capture/label_confirmation_screen_test.dart`.

## Dependencies
- SPEC-004 (R5), SPEC-030 (formato y "Falta: …").

## Edge Cases
- La porción llega vacía de la IA (no legible) y la persona la escribe después: "¿Cuánto comiste?"
  la sigue (SPEC-004 R5, ya cubierto por el controlador).
- La persona borra "¿Cuánto comiste?" después de editarlo: queda vacío y ya no sigue a la porción
  (R3); "Falta: cuánto comiste".
- Porción no válida ("1.200"): igual que vacía (R2).

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No.

## Tests Required
- Widget: AC1–AC5.
- Manual: cambiar la porción en el teléfono y ver que "¿Cuánto comiste?" cambia.

## Out of Scope
- Cambiar la unidad (g/ml) de "¿Cuánto comiste?" por separado de la porción.
- Que la IA lea mejor la porción (T-030).

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC5 con evidencia · analyze y tests verdes en `app` · prueba manual · reviewer PASS
  enlazado.

## Change Log
- 2026-10-07: creación a pedido de la usuaria ("si"), a partir de T-031.
- 2026-10-07: **Approved por la usuaria** ("aprobada"). Status → Implementing.

## Review
Informe del reviewer:
