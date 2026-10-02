# Calidad del reconocimiento de voz en es-CO en dispositivos reales (PV-05)

Pregunta: ¿Qué tan bien transcribe `speech_to_text` las frases de comida en es-CO en un Android y
un iPhone físicos? ¿El reconocimiento ocurre en el dispositivo o en servidores del SO?

Decisión que desbloquea: AC8 de `specs/SPEC-002-entrada-por-voz.md` y la fila "Audio de voz" de
`docs/privacy.md` (hoy `POR VERIFICAR`).

Estado: **PLANTILLA — pendiente de la medición manual.** Ninguna cifra de este documento es real
hasta que se llenen las tablas.

## Método

- Frases: las 10 primeras de `evals/datasets/parse_meal.v1.jsonl` (`s01`–`s10`). Son los mismos 10
  casos de `slice_smoke.jsonl`, que cita AC8 y que SPEC-005 reemplazó (ver `evals/README.md`).
- Build: `flutter run` (debug) con el teléfono conectado por USB o depuración inalámbrica. En
  Android, la pantalla se puede manejar desde el Mac con `scrcpy`, pero **el micrófono es el del
  teléfono**: se dicta hablándole al teléfono.
- Configuración de la app (`app/lib/features/capture/speech_recognizer.dart`): `localeId: es_CO`,
  `partialResults: true`, `pauseFor: 2 s`, sin `onDevice` (default del plugin: el SO decide si
  usa servidores).
- Procedimiento por frase: tocar el micrófono, leer la frase una vez a ritmo normal, detener y
  copiar **exactamente** lo que quedó en el campo de texto, antes de editar o enviar nada.
- Ambiente: anotar si es silencioso o con ruido, y la distancia aproximada al teléfono.

### Cómo se cuenta la coincidencia
1. Se normalizan el esperado y el transcrito: minúsculas, sin signos de puntuación, espacios
   colapsados. Las tildes **sí** cuentan (por ejemplo, "platano" ≠ "plátano").
2. Las cifras y los números en palabras son equivalentes ("150" = "ciento cincuenta", "180 g" =
   "180 gramos"), porque `parseMeal` interpreta ambos.
3. **Exacta (sí/no):** el transcrito normalizado es idéntico al esperado.
4. **Palabras correctas (%):** palabras esperadas que aparecen en el transcrito, en orden, divididas
   por el total de palabras esperadas.
5. **¿Cambia el resultado?:** sí, si el error cambia un alimento, una cantidad o una unidad (por
   ejemplo, "dos" por "los"). No, si solo afecta palabras que no cambian el registro.

## Dispositivos

| Plataforma | Modelo | Versión del SO | Idioma del sistema | ¿Modo avión probado? |
|---|---|---|---|---|
| Android | | | | |
| iOS | | | | |

## Resultados — Android

| id | Esperado | Transcrito | Exacta | Palabras correctas | ¿Cambia el resultado? |
|---|---|---|---|---|---|
| s01 | dos huevos revueltos y una arepa pequeña con queso | | | | |
| s02 | 150 gramos de pechuga de pollo a la plancha | | | | |
| s03 | un café con leche | | | | |
| s04 | media taza de arroz blanco y un plátano maduro frito | | | | |
| s05 | almorcé 180 g de arroz, medio aguacate y ensalada con una cucharada de aceite de oliva | | | | |
| s06 | me comí un poquito de queso | | | | |
| s07 | una manzana | | | | |
| s08 | dos tajadas de pan integral con mantequilla de maní | | | | |
| s09 | un vaso de jugo de naranja | | | | |
| s10 | hola, ¿cómo estás? | | | | |

## Resultados — iOS

| id | Esperado | Transcrito | Exacta | Palabras correctas | ¿Cambia el resultado? |
|---|---|---|---|---|---|
| s01 | dos huevos revueltos y una arepa pequeña con queso | | | | |
| s02 | 150 gramos de pechuga de pollo a la plancha | | | | |
| s03 | un café con leche | | | | |
| s04 | media taza de arroz blanco y un plátano maduro frito | | | | |
| s05 | almorcé 180 g de arroz, medio aguacate y ensalada con una cucharada de aceite de oliva | | | | |
| s06 | me comí un poquito de queso | | | | |
| s07 | una manzana | | | | |
| s08 | dos tajadas de pan integral con mantequilla de maní | | | | |
| s09 | un vaso de jugo de naranja | | | | |
| s10 | hola, ¿cómo estás? | | | | |

## Resumen

| Plataforma | Exactas (de 10) | Palabras correctas (promedio) | Frases donde cambia el resultado |
|---|---|---|---|
| Android | | | |
| iOS | | | |

## ¿Dónde se procesa el audio?

Prueba empírica por plataforma: con el teléfono en modo avión (sin wifi), ¿la app sigue
transcribiendo?
- Sí → hay reconocimiento en el dispositivo para es-CO en ese equipo, aunque sin `onDevice: true`
  el SO puede usar servidores cuando hay red.
- No (error de "reconocimiento no disponible" o de red) → depende de servidores de Google/Apple.

| Plataforma | ¿Transcribe en modo avión? | Conclusión para `docs/privacy.md` |
|---|---|---|
| Android | | |
| iOS | | |

**POR VERIFICAR (documentación, no medición):** qué garantizan Google y Apple sobre retención del
audio enviado a sus servidores de reconocimiento. Delegar al subagente `researcher` si la fila de
privacidad lo necesita.

## Conclusión

_Se completa después de la medición._ Debe decir: si la calidad es suficiente para la beta (el
usuario siempre puede editar la transcripción antes de enviar, SPEC-002), qué errores son
recurrentes (números, tildes, palabras regionales) y qué cambia en `docs/privacy.md`.
