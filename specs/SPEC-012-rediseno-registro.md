# SPEC-012: Rediseño del flujo de registro

## Status
Approved
Path: Standard (presentación y flujo; no cambia prompts, esquemas de IA, cálculos ni datos que salen
del dispositivo)

## Objective
Que registrar una comida se vea y se sienta como en el diseño: "¿Qué comiste?" con pestañas,
"Analizando" con pasos visibles, "Detalle de comida" con el tipo de comida y el sello de base
verificada, y una pantalla de error útil.

## Context
Backlog T-013. Diseño: artboards "¿Qué comiste?", "Analizando", "Detalle de comida" y "Error de la
IA" del lienzo https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD. Decisión 6 del rediseño: la foto
del plato es F2; en este MVP la pestaña Foto es la foto de la **tabla nutricional** (SPEC-004).
Hoy: `features/capture` (texto, micrófono, cámara de etiqueta) y `features/review` (ítems con
+/-, tipo de comida en un desplegable).

## User Story
Como persona que registra lo que come, quiero un flujo claro que me muestre qué está pasando y me
deje corregir antes de guardar.

## Requirements
- R1. **"¿Qué comiste?"**: encabezado con Volver y tres pestañas: **Texto** (por defecto; campo con
  contador 0/500 y botón "Analizar"), **Voz** (micrófono de SPEC-002, la transcripción queda en el
  campo de texto) y **Foto** ("Foto de la tabla nutricional", abre el flujo de SPEC-004). Al pie, la
  nota fija: "Tu texto o foto se envía a la IA solo para estructurarlo. Las calorías las calcula tu
  teléfono.". La sección "Recientes" es SPEC-017.
- R2. **"Analizando"**: muestra lo que se envió y cuatro pasos: "Enviando a la IA", "Identificando
  alimentos y cantidades", "Buscando en la base verificada" y "Calculando en tu teléfono". Cada paso
  se marca cuando **de verdad** termina: los dos primeros con la respuesta de la IA y los otros dos
  con la resolución y el cálculo locales. Lleva la nota de privacidad y un botón "Cancelar".
- R3. **Cancelar**: vuelve a "¿Qué comiste?" con el texto intacto e ignora la respuesta si llega
  después. No se guarda nada.
- R4. **"Detalle de comida"** (la revisión actual, rediseñada): título con los nombres de los
  alimentos, hora y fecha; tarjeta de kcal con P/C/G (con "~" si es estimación); selector de tipo de
  comida en botones (Desayuno, Almuerzo, Cena, Snack), que reemplaza el desplegable; lista de
  ingredientes con nombre, cómo se obtuvo la cantidad ("Cantidad dicha por ti", "Tamaño estimado ·
  ajústalo"), botones −/+ y kcal; botones "Corregir" (vuelve a "¿Qué comiste?" con el texto) y
  "Guardar". "Añadir" ingrediente es SPEC-018.
- R5. **Sello "Base verificada"**: aparece si todos los ítems salen del catálogo o de una etiqueta
  confirmada, es decir, si todos tienen `source_ref` (invariante 8). Si algún ítem no se resolvió,
  no aparece y se sigue sin poder guardar (como hoy).
- R6. **"Algo salió mal"** (fallo de la IA o del parseo): ilustración, "No pude entender tu comida",
  "No se guardó nada en tu diario." y tres consejos: revisar la conexión, describir cada alimento
  con su cantidad y, si es foto, acercarse con buena luz. Botón "Reintentar" (vuelve a enviar el
  mismo texto) y Volver. El botón "Buscar en la base manualmente" es SPEC-018.
- R7. Los mensajes de error actuales (`docs/architecture.md`, Errores) se mantienen, ahora dentro de
  esta pantalla.

## Acceptance Criteria
- AC1. "¿Qué comiste?" muestra las 3 pestañas; Texto activa por defecto, contador "0/500" y
  "Analizar" deshabilitado con el campo vacío; la nota de privacidad visible `[widget]`.
- AC2. "Analizando" marca los pasos en orden con un `AiClient` falso que responde después de una
  espera; la resolución y el cálculo marcan los pasos 3 y 4 `[widget]`.
- AC3. "Cancelar" durante el análisis vuelve con el texto intacto; una respuesta que llega después
  no navega ni guarda `[widget]`.
- AC4. Detalle: el tipo de comida se cambia con los botones y se guarda con la comida; −/+ ajusta los
  gramos y las kcal como hoy; "Corregir" vuelve con el texto `[widget + integration]`.
- AC5. Sello: visible con todos los ítems resueltos; oculto si alguno queda sin resolver
  `[widget]`.
- AC6. Error: con la IA en timeout se ve "No pude entender tu comida" con los 3 consejos; "Reintentar"
  vuelve a enviar el mismo texto `[widget]`.
- AC7. Los flujos de texto, voz y etiqueta (`test/integration/*_flow_test.dart`) siguen verdes,
  adaptados a los nuevos controles `[integration]`.

## Technical Constraints
- Invariantes 1, 2 y 4: la IA solo estructura; nada de esto cambia el prompt ni el esquema.
- Sistema visual de SPEC-010.

## Components / Files Affected
- `app/lib/features/capture/` (pantalla con pestañas, "Analizando", error).
- `app/lib/features/review/` (detalle rediseñado, selector de tipo de comida).
- Tests de integración de los tres flujos.

## Dependencies
- SPEC-010.

## Edge Cases
- Sin red: "Analizando" pasa al error con el consejo de conexión.
- Permiso de micrófono denegado en la pestaña Voz: mensaje de SPEC-002 y la pestaña Texto sigue
  disponible.
- Doble toque en "Analizar" o "Guardar": se ignora mientras hay una operación en curso.
- La IA responde sin alimentos: el error dice "No encontré alimentos en lo que escribiste".

## Security & Privacy
- No sale ningún dato nuevo; las notas de privacidad repiten lo que ya dice la política.

## Tests Required
- Widget: AC1–AC6. Integration: AC7. Manual: recorrido en el teléfono con texto, voz y etiqueta.

## Out of Scope
- Foto del plato (F2), comidas recientes (SPEC-017), búsqueda manual y "Añadir" (SPEC-018), editar
  una comida ya guardada, compartir.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC7 con evidencia; analyze y tests verdes; reviewer PASS; recorrido manual.

## Change Log
- 2026-10-03: creación a partir de T-013 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.

## Review
Informe del reviewer: pendiente.
