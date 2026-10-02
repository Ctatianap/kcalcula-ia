# Calidad del reconocimiento de voz en es-CO en dispositivos reales (PV-05)

Pregunta: ¿Qué tan bien transcribe `speech_to_text` las frases de comida en es-CO en un Android y
un iPhone físicos? ¿El reconocimiento ocurre en el dispositivo o en servidores del SO?

Decisión que desbloquea: AC8 de `specs/SPEC-002-entrada-por-voz.md` y la fila "Audio de voz" de
`docs/privacy.md` (hoy `POR VERIFICAR`).

Estado: **EN CURSO.** Android: primera ronda hecha (antes del arreglo de R5/R9) y prueba de modo
avión hecha; falta repetir s02, s04 y s05 con el arreglo. iOS: pendiente.

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
| Android | motorola edge 50 pro | Android 16 | POR CONFIRMAR | Sí |
| iOS | | | | |

## Resultados — Android

### Ronda 1 (2026-10-01, antes del arreglo de R5/R9 — commit `c87f32a`)

Sin pausas al hablar, según la persona que dictó. En esta ronda la app tenía un bug: cuando el
reconocedor cerraba la escucha por su cuenta, la app seguía en "escuchando" y al reintentar
borraba el texto. Por eso s02, s04 y s05 no miden solo la calidad del reconocimiento.

| id | Esperado | Transcrito | Exacta | Palabras correctas | ¿Cambia el resultado? |
|---|---|---|---|---|---|
| s01 | dos huevos revueltos y una arepa pequeña con queso | dos huevos y una arepa pequeña con queso | No | 8/9 (89 %) | Sí, leve: se pierde la preparación "revueltos" |
| s02 | 150 gramos de pechuga de pollo a la plancha | 150 | No | 1/8 (13 %) | Sí: se pierde el alimento (corte, ver nota) |
| s03 | un café con leche | un café con leche | Sí | 4/4 (100 %) | No |
| s04 | media taza de arroz blanco y un plátano maduro frito | media taza | No | 2/10 (20 %) | Sí: se pierden los alimentos (corte) |
| s05 | almorcé 180 g de arroz, medio aguacate y ensalada con una cucharada de aceite de oliva | medio aguacate ensalada con | No | 4/15 (27 %) | Sí: se pierden arroz y aceite (corte y reintento que borró el texto) |
| s06 | me comí un poquito de queso | comí un poquito de queso | No | 5/6 (83 %) | No ("me" no cambia el registro) |
| s07 | una manzana | una manzana | Sí | 2/2 (100 %) | No |
| s08 | dos tajadas de pan integral con mantequilla de maní | dos tajadas de pan integral con mantequilla de maní | Sí | 9/9 (100 %) | No |
| s09 | un vaso de jugo de naranja | un vaso de jugo de naranja | Sí | 6/6 (100 %) | No |
| s10 | hola, ¿cómo estás? | Hola cómo estás | Sí | 3/3 (100 %) | No |

Diagnóstico de los cortes (log temporal de `speech_to_text`, dictando s05): los resultados parciales
llegan acumulados y correctos ("almorcé 180 gramos de arroz media aguacate ensalada") y luego el
reconocedor del SO emite `notListening` → `done` → resultado final **a mitad de frase, sin pausa**.
La app pide `EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS = 2000`, pero en este equipo el
reconocedor no lo respeta. POR VERIFICAR si es general de Android 16 o propio de este equipo.
Arreglo aprobado: R5 ampliado y R9 nuevo de SPEC-002 (el texto se conserva y se puede seguir
dictando con otro toque).

### Ronda 2 (después del arreglo) — s02, s04, s05

| id | Esperado | Transcrito | Toques | Exacta | Palabras correctas | ¿Cambia el resultado? |
|---|---|---|---|---|---|---|
| s02 | 150 gramos de pechuga de pollo a la plancha | | | | | |
| s04 | media taza de arroz blanco y un plátano maduro frito | | | | | |
| s05 | almorcé 180 g de arroz, medio aguacate y ensalada con una cucharada de aceite de oliva | | | | | |

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
| Android | No: con modo avión la app no permite dictar | Con la configuración actual (sin `onDevice`), el audio se procesa en servidores de Google; nunca va a nuestro backend |
| iOS | | |

**POR VERIFICAR (documentación, no medición):** qué garantizan Google y Apple sobre retención del
audio enviado a sus servidores de reconocimiento. Delegar al subagente `researcher` si la fila de
privacidad lo necesita.

## Conclusión

_Se completa después de la medición._ Debe decir: si la calidad es suficiente para la beta (el
usuario siempre puede editar la transcripción antes de enviar, SPEC-002), qué errores son
recurrentes (números, tildes, palabras regionales) y qué cambia en `docs/privacy.md`.
