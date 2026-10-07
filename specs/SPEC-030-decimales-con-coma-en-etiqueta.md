# SPEC-030: Decimales con coma en "Confirmar etiqueta"

## Status
Done
Path: Standard (corrige la entrada de números de una pantalla; no cambia `nutrition_core`, la IA
ni el catálogo)

## Objective
Que en "Confirmar etiqueta" se puedan escribir decimales con coma ("1,4"), como se escribe en
Colombia, que los valores se muestren con coma y que la pantalla diga qué falta cuando no deja
guardar.

## Context
Backlog T-029. Encontrado al probar SPEC-029 en el teléfono (2026-10-07). La usuaria corrigió la
proteína a "1,4" y el botón **Guardar y continuar** quedó deshabilitado sin explicación.

Causa: `_NumberField` (`app/lib/features/capture/label_confirmation_screen.dart`) convierte el texto
con `double.tryParse`, que solo acepta punto. Con "1,4" devuelve `null`, la proteína queda vacía y
`canSave` es falso. Además, `_numberText` muestra los valores de la IA con `toString()` ("15.0";
un valor calculado desde "por 100 g" puede verse como "17.799999999999997").

Las demás pantallas ya usan `parseDecimal` (`app/lib/ui/number_input_es.dart`), que acepta coma o
punto pero solo **un** decimal; en una etiqueta hay valores con dos ("0,25 g").

## User Story
Como persona que confirma una etiqueta, quiero escribir "1,4" y que la app lo entienda, para no
quedarme sin poder guardar y sin saber por qué.

## Requirements
- R1. Los campos numéricos de "Confirmar etiqueta" (porción, calorías, proteína, carbohidratos,
  grasa, fibra, azúcar, sodio y "¿Cuánto comiste?") aceptan coma o punto como separador decimal,
  con **hasta 2 decimales**. No se aceptan separadores de miles ni signos.
- R2. Los valores que llegan de la IA se muestran con coma y sin ceros de más ("15", "2,9",
  "1,78"), con máximo 2 decimales. Redondear para mostrar **no cambia** el valor guardado en el
  controlador mientras la persona no edite el campo (invariante 3: redondear solo al presentar).
- R3. Un texto no válido ("1.200", "1,234", "abc") muestra debajo del campo: "Escribe un número
  con máximo 2 decimales, por ejemplo 1,4." y el campo cuenta como vacío.
- R4. Si **Guardar y continuar** está deshabilitado, un texto encima del botón dice qué falta, en
  este orden: nombre del producto, porción, calorías, proteína, carbohidratos, grasa, "cuánto
  comiste", o la confirmación de Atwater. Ejemplo: "Falta: proteína."
- R5. El parser es una función compartida en `app/lib/ui/number_input_es.dart` con su número de
  decimales como parámetro. `parseDecimal` (un decimal) no cambia para las demás pantallas.

## Acceptance Criteria
- AC1. En "Confirmar etiqueta", escribir "1,4" y "1.4" en proteína → el controlador recibe 1,4 y,
  con lo demás completo, **Guardar y continuar** se habilita `[widget]`.
- AC2. Una extracción con calorías 15.0, grasa 2.9 y carbohidratos 1.7799999999999998 → los campos
  muestran "15", "2,9" y "1,78"; guardar sin editarlos persiste 1.7799999999999998 `[widget]`.
- AC3. Escribir "1.200" o "1,234" en sodio → aparece el mensaje de R3 y el valor queda vacío;
  "1,2" y "0,25" se aceptan `[unit + widget]`.
- AC4. Con todo completo menos la proteína → aparece "Falta: proteína." y el botón sigue
  deshabilitado; al completarla, el texto desaparece `[widget]`.
- AC5. Los tests existentes de `label_confirmation_*_test.dart` y de las pantallas que usan
  `parseDecimal` siguen verdes sin cambiar sus expectativas, salvo las que comprueban el texto con
  punto de un valor inicial (se listan en la Verificación) `[widget]`.

## Technical Constraints
- Invariante 2: la validación de la etiqueta (Atwater ±20 %, porción obligatoria) sigue en
  `nutrition_core` y no cambia.
- Invariante 3: lo que se muestra se redondea; lo que se guarda no.
- Errores en español, accionables, sin trazas técnicas.

## Components / Files Affected
- `app/lib/ui/number_input_es.dart` (parser con N decimales y formato con coma).
- `app/lib/features/capture/label_confirmation_screen.dart` (`_NumberField`, `_numberText`, texto
  de lo que falta).
- `app/lib/features/capture/label_confirmation_controller.dart` (lista de lo que falta, si hace
  falta exponerla).
- Tests: `app/test/features/capture/label_confirmation_*_test.dart`, test unitario del parser.

## Dependencies
- SPEC-004 (pantalla de etiquetas), SPEC-008/SPEC-015 (`parseDecimal`).

## Edge Cases
- Campo vacío: sigue siendo "vacío" (los opcionales pueden quedar así).
- "1," o ",5": no válidos (mensaje de R3). "0" es válido.
- Teclado que solo muestra punto (algunos Android): el punto funciona igual.
- Valor de la IA con más de 2 decimales: se muestra redondeado (R2) y, si no se edita, se guarda el
  original.
- Valor de la IA muy grande ("14360" mg de sodio): se muestra sin separador de miles ("14360").

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No.

## Tests Required
- Unit: AC3 (parser y formato).
- Widget: AC1–AC5.
- Manual: confirmar una etiqueta real en el teléfono escribiendo con coma.

## Out of Scope
- Que la IA lea porción y "por 100 g" de la columna correcta: se revisa aparte con la foto de la
  usuaria (posible cambio de prompt, Strict).
- Cambiar `parseDecimal` en otras pantallas.
- Separadores de miles.

## Open Questions
- Ninguna. Decisión tomada: máximo 2 decimales y sin separador de miles, para que "1.200" no se
  lea como 1,2 sin avisar.

## Definition of Done
- AC1–AC5 con evidencia · analyze y tests verdes en `app` · reviewer PASS enlazado.

## Change Log
- 2026-10-07: creación a pedido de la usuaria ("sí, redacta la SPEC-030"), a partir del fallo
  encontrado al probar SPEC-029. Backlog T-029.
- 2026-10-07: **Approved por la usuaria** ("aprobada la SPEC-030"). Se implementa después de cerrar
  SPEC-029.
- 2026-10-07: SPEC-029 fusionada; Status → Implementing.
- 2026-10-07: implementada. `parseDecimalUpTo` y `formatDecimalEs` en `app/lib/ui/number_input_es.dart`
  (`parseDecimal` delega con un decimal); `_NumberField` con error de R3; `missingForSave` en el
  controlador y texto "Falta: …" encima del botón. Falta la prueba manual en el teléfono.
- 2026-10-07: reviewer PASS; sus 4 MINOR atendidos (ver Review). Falta la prueba manual en el teléfono.
- 2026-10-07: prueba manual en el teléfono hecha (ver Verificación). Status → Review.
- 2026-10-07: **la usuaria aprueba fusionar** ("aprobado, fusiona a develop"). Status → Done.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/capture/label_confirmation_screen_test.dart` › "SPEC-030 AC1: \"1,4\" …" y "… \"1.4\" …": habilita Guardar y lo guardado por 100 g es 1,4 × 100/30 |
| AC2 | ✅ | mismo archivo › "SPEC-030 AC2…": muestra "15", "2,9" y "1,78"; sin editar se guarda `carbsG100 == 1.7799999999999998` |
| AC3 | ✅ | `app/test/ui/number_input_es_test.dart` (parser y formato: "1.200", "1,234", "1,", ",5", "-1" no válidos; "1,2", "0,25", "0", "14360" válidos) y `label_confirmation_screen_test.dart` › "SPEC-030 AC3…" (mensaje de R3 y sodio guardado como `null`) |
| AC4 | ✅ | `label_confirmation_screen_test.dart` › "SPEC-030 AC4: \"Falta: proteína.\" hasta completarla" |
| AC5 | ✅ | app: analyze sin avisos, 338/338 (tras los MINOR del reviewer). Expectativas cambiadas, como prevé el AC: "AC2/AC4: muestra los valores transcritos, editables" pasa de "140.0" y "30.0" a "140" y "30" (R2). `parseDecimal` conserva su comportamiento (test "parseDecimal sigue aceptando solo un decimal") |
| Manual | ✅ | 2026-10-07, Motorola edge 50 pro, etiqueta real elegida por la usuaria: los valores de la IA salen con coma ("2,8", "0,2", "1,3", "1,8"); "Falta: nombre del producto." porque la IA no lo leyó; proteína "1,4" deja Guardar activo; sodio "1.200" muestra el mensaje de R3; proteína vacía → "Falta: proteína." y Guardar deshabilitado. No se guardó el producto de prueba |

## Review
Revisión (2026-10-07, subagente `reviewer`, sobre `ca79df9`): **PASS**. AC1–AC5 con evidencia; app
analyze sin avisos y 336/336; `missingForSave` equivale al `canSave` anterior; invariantes 2 y 3
respetadas; la prueba manual pendiente no bloquea. 4 MINOR:
- "Falta: ¿Cuánto comiste?." (signo y punto): ahora "cuánto comiste".
- Sin test del orden con varios faltantes ni del ítem de Atwater: 2 tests nuevos en
  `label_confirmation_controller_test.dart` (338/338).
- `formatDecimalEs` con negativos diminutos o ≥1e21: documentado en la función.
- Heredado de SPEC-004: al cambiar la porción, el campo "¿Cuánto comiste?" no actualiza su texto
  aunque el controlador sí: T-031 en el backlog.
