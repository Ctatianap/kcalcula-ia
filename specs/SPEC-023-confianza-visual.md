# SPEC-023: Confianza visual

## Status
Draft
Path: Standard (presentación de la confianza ya calculada por reglas; no cambia la regla ni el
cálculo)

## Objective
Que la persona entienda de un vistazo qué tan precisa es cada cifra y qué puede hacer para mejorarla,
sin colores de alarma.

## Context
Fase F2 de `docs/backlog.md` ("confianza visual"). La confianza se calcula por reglas
(`docs/architecture.md`, sección Confianza; invariante 4) y hoy se muestra como texto ("Buena
estimación") en la tarjeta de kcal del detalle (SPEC-012) y como "~" en Hoy, Historial y Progreso.
Principio del producto: "sin inventar precisión".

## User Story
Como persona que registra, quiero ver qué parte de mi comida es estimada y cómo afinarla, para confiar
en los números.

## Requirements
- R1. **Indicador de 3 niveles** (componente de `ui/components/`): Alta precisión, Buena estimación y
  Estimación, con ícono y texto (nunca solo color), en tonos del sistema visual (SPEC-010, sin rojo ni
  verde de alarma).
- R2. **Detalle de comida:** el indicador en la tarjeta de kcal y un indicador pequeño por ingrediente.
- R3. **"¿Por qué?":** tocar el indicador abre una hoja con la explicación en español de la regla que
  aplicó (p. ej. "Tamaño estimado: la porción viene de una medida típica, no de un peso") y una acción
  para mejorarla cuando exista ("Escribe los gramos", "Toma foto de la etiqueta").
- R4. **Hoy e Historial:** las tarjetas de comida muestran el indicador de la comida (mismo
  componente); el "~" se mantiene en los totales.
- R5. Lectura accesible: cada indicador tiene etiqueta semántica ("Confianza: buena estimación").

## Acceptance Criteria
- AC1. Para cada nivel, el indicador muestra su ícono y su texto, y su etiqueta semántica `[widget]`.
- AC2. En el detalle de "dos huevos (unidad) y una arepa pequeña", la arepa muestra "Estimación", el
  huevo "Buena estimación" y la tarjeta el nivel de la comida según la regla del 15 % `[widget]`.
- AC3. Tocar el indicador de la arepa abre la explicación de `size_descriptor` y la acción "Escribe
  los gramos", que enfoca el ajuste de cantidad `[widget]`.
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
- ¿Íconos propuestos (círculo lleno / medio / contorno) o los del lienzo de diseño? Falta el artboard
  de este componente.
- ¿La acción "Toma foto de la etiqueta" debe abrir directamente la cámara (SPEC-004)?

## Definition of Done
- AC1–AC6 con evidencia · analyze y tests verdes · reviewer PASS enlazado · arquitectura actualizada
  (componente de confianza).

## Change Log
- 2026-10-04: creación a partir de F2 ("confianza visual").

## Review
Informe del reviewer: pendiente.
