# SPEC-012: Rediseño del flujo de registro

## Status
Review
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

## Evidencia
| AC | Evidencia |
|----|-----------|
| AC1 | `app/test/features/review/meal_analysis_test.dart` › "AC1: tres pestañas, Texto por defecto, contador 0/500, Analizar deshabilitado y nota de privacidad" |
| AC2 | mismo archivo › "AC2: los pasos se marcan en orden 0 → 2 → 3 → 4 y luego el detalle" (unit) y "AC2: pasos 1-2 con la respuesta de la IA; 3-4 con la resolución y el cálculo locales" (widget, `AiClient` que responde cuando el test lo libera) |
| AC3 | mismo archivo › "AC3: Cancelar vuelve con el texto intacto y la respuesta tardía no navega ni guarda" (widget) y "AC3: tras cancelar, una respuesta tardía se ignora" (unit) |
| AC4 | mismo archivo › "AC4: el tipo de comida se cambia con botones y se guarda; −/+ ajusta gramos y kcal" y "AC4: \"Corregir\" vuelve a \"¿Qué comiste?\" con el texto" (app completa con `user.db` en memoria); `test/features/review/review_screen_test.dart` › AC8 |
| AC5 | mismo archivo › "AC5: el sello \"Base verificada\" aparece…" y "AC5: sin sello si un ítem queda sin resolver; Guardar sigue deshabilitado" |
| AC6 | mismo archivo › "AC6: con la IA en timeout se ve el error con 3 consejos; \"Reintentar\" envía el mismo texto" y "AC6: \"Volver\" desde el error regresa con el texto" |
| AC7 | `test/integration/capture_to_review_flow_test.dart`, `voice_to_review_flow_test.dart`, `label_to_review_flow_test.dart`, `storage_errors_test.dart` adaptados (pestañas, "Guardar", total en `meal-detail-kcal`) y verdes |

Edge cases: doble toque en Analizar ("edge case: un doble toque en Analizar abre un solo análisis"),
IA sin alimentos (unit + widget), micrófono denegado con la pestaña Texto disponible
(`capture_screen_voice_test.dart` › AC4), texto grande ×2 en 360 px sin desbordes.
Manual: recorrido en el teléfono pendiente (lo hace la usuaria).

## Change Log
- 2026-10-03: creación a partir de T-013 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.
- 2026-10-03: implementada (autorización única de la usuaria para implementar y fusionar el lote
  SPEC-012 a SPEC-019). Detalles menores decididos con la opción recomendada:
  - "Analizando", el detalle y el error viven en `features/review` (`MealAnalysisScreen`, ruta
    `/analysis` con el texto como argumento), no en `capture`: así los pasos 3 y 4 se marcan con la
    resolución y el cálculo reales sin que las features se importen. `CaptureController` se
    eliminó; "¿Qué comiste?" solo abre `/analysis`.
  - La etiqueta confirmada (SPEC-004) va directo al detalle (`ReviewScreen`), sin "Analizando": su
    IA ya corrió en la confirmación.
  - Pausa de 300 ms con los cuatro pasos marcados antes de abrir el detalle (si no, los pasos 3 y 4
    no alcanzan a verse).
  - "~" en kcal y P/C/G salvo con "Alta precisión", como en Hoy; la confianza de la comida se muestra
    en la tarjeta de kcal (ya no por ítem).
  - Textos de cómo se obtuvo la cantidad: "Cantidad dicha por ti" (peso explícito o unidades), "De tu
    etiqueta", "Tamaño estimado · ajústalo", "Medida casera estimada · ajústala", "Porción estimada ·
    ajústala".
  - Título del detalle con los nombres del catálogo unidos con "," e "y"; la mención original va
    entre comillas debajo de cada ingrediente.
  - El error de lectura de `user.db` durante el análisis usa la misma pantalla, con el título "No
    pude leer tus datos" y sin los consejos de la IA.
  - Fechas en es-CO movidas a `app/lib/ui/date_format_es.dart` (las comparten Hoy y el detalle).
  Status → Review.
- 2026-10-03: reviewer **PASS** (commit 21d39ac; app 199/199, analyze limpio), sin BLOCKER ni MAJOR.
  MINOR atendidos antes de fusionar:
  - "Reintentar" tras un fallo de lectura de `user.db` ya no reenvía el texto a la IA: reusa la
    respuesta recibida y repite solo la resolución (test unitario).
  - El error de lectura ya no repite el título en el cuerpo.
  - Quitar todos los ingredientes muestra un aviso ("Quitaste todos los alimentos…").
  - Tests nuevos: doble toque en "Guardar" registra una sola comida; sello "Base verificada" en el
    flujo de etiqueta confirmada; aviso sin ingredientes.
  - Decisión anotada: el error de la **foto de etiqueta** sigue dentro de la pestaña Foto (no en
    "Algo salió mal"), porque "Reintentar" de esa pantalla reenvía texto y la foto se repite con
    "Tomar foto"; el consejo de luz se mantiene en "Algo salió mal" tal como pide R6.
  - Sin cambio: la hora del título es la de apertura del detalle y `eaten_at` se toma al guardar
    (cosmético); `mealTypeLabels` sigue en `ui/date_format_es.dart`.
  Fusionada en `develop` por la autorización única de la usuaria. Sigue en Review hasta el
  recorrido manual en el teléfono.

## Review
Informe del reviewer (2026-10-03, commit 21d39ac): **PASS**. AC1–AC7 cumplidos con evidencia en tests
(`meal_analysis_test.dart` y los cuatro tests de integración); invariantes 1–4 y 8 sin cambios;
ningún dato nuevo sale del dispositivo. Hallazgos MINOR: ver Change Log (atendidos o anotados).
