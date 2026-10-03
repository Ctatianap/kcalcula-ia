# Calidad del reconocimiento de voz en es-CO en dispositivos reales (PV-05)

Pregunta: ¿Qué tan bien transcribe `speech_to_text` las frases de comida en es-CO en un Android y
un iPhone físicos? ¿El reconocimiento ocurre en el dispositivo o en servidores del SO?

Decisión que desbloquea: AC8 de `specs/SPEC-002-entrada-por-voz.md` y la fila "Audio de voz" de
`docs/privacy.md` (hoy `POR VERIFICAR`).

Estado: **Android completo** (ronda 3, versión final, commit `8bccfad`). **iOS: pendiente.**

## Método

- Frases: las 10 primeras de `evals/datasets/parse_meal.v1.jsonl` (`s01`–`s10`). Son los mismos 10
  casos de `slice_smoke.jsonl`, que cita AC8 y que SPEC-005 reemplazó (ver `evals/README.md`).
- Build: `flutter run` (debug) con el teléfono conectado por USB o depuración inalámbrica. En
  Android, la pantalla se puede manejar desde el Mac con `scrcpy`, pero **el micrófono es el del
  teléfono**: se dicta hablándole al teléfono.
- Configuración de la app (`app/lib/features/capture/speech_recognizer.dart` y
  `silencePauseFor` en `voice_input_controller.dart`): `localeId: es_CO`, `partialResults: true`,
  sin `onDevice` (default del plugin: el SO decide si usa servidores). El tiempo de silencio
  **cambia según la ronda**: rondas 1 y 2a con `pauseFor: 2 s`; ronda 2b y ronda 3 (la que cuenta
  para AC8) **sin `pauseFor` en Android**. Para la medición en iOS, la versión vigente usa
  `pauseFor: 2 s` (R5 de SPEC-002).
- Procedimiento por frase: tocar el micrófono, leer la frase una vez a ritmo normal y esperar a
  que la escucha se cierre sola (o tocar "Detener"); copiar **exactamente** lo que quedó en el
  campo de texto, antes de editar o enviar nada. Si se cortó, anotar cuántos toques hicieron
  falta (con R9 el texto nuevo se agrega al anterior).
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
| Android | motorola edge 50 pro | Android 16 | español (Colombia) | Sí |
| iOS | | | | |

## Resultados — Android

### Ronda 1 (2026-10-01, antes del arreglo de R5/R9 — commit `db5cf7d`)

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

### Ronda 2 (2026-10-02, con el arreglo de R5/R9) — s02, s04, s05

**2a. Con `pauseFor: 2 s`** (la app pasa a Android `EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS
= 2000`, como en la ronda 1):

| id | Transcrito | Toques | Qué pasó |
|---|---|---|---|
| s02 | 150 g de pechuga de pollo a la plancha | 1 | Exacta ("g" = "gramos") |
| s04 | media ta | 1 | **Corte prematuro**: el SO emite `notListening`/`done` antes de los resultados, a la 2.ª palabra. El reintento (R9 agregó al texto, correcto) terminó en `error_no_match` |

La persona que dictó reportó además intentos previos en que "no escuchaba nada, se cortaba".

**2b. Experimento sin `pauseFor`** (no se pasa el extra a Android; el reconocedor usa su propio
criterio para cerrar):

| id | Intento | Transcrito | Toques | Exacta | Palabras correctas | ¿Cambia el resultado? |
|---|---|---|---|---|---|---|
| s04 | 1 | media taza de arroz y un plátano maduro frito | 1 | Sí respecto a lo dicho (la persona omitió "blanco") | 9/9 | No |
| s04 | 2 | media taza de arroz blanco y un plátano frito | 1 | No (se dijo "maduro", no se reconoció) | 9/10 (90 %) | Sí, leve: "plátano" en vez de "plátano maduro" |
| s04 | 3 | media taza de arroz blanco y maduro frito | 1 | No (faltó "un plátano") | 8/10 (80 %) | No en la práctica ("maduro" es plátano maduro en es-CO) |
| s05 | 1 | almorcé 180 G de arroz medio aguacate y ensalada con una cucharada de aceite de oliva | 1 | Sí | 15/15 | No |
| s05 | 2 | — | 1 | — | — | `error_speech_timeout`: el SO no detectó voz (probablemente la persona no alcanzó a empezar a hablar) |
| s05 | 3 | almorcé 180 gramos de arroz medio aguacate y ensalada con una cucharada de aceite de oliva | 1 | Sí | 15/15 | No |

Conclusión del experimento: **0 cortes a mitad de frase en 5 intentos con voz sin el extra de
silencio**, frente a cortes repetidos con él. En `speech_to_text` 7.5.0, `pauseFor` hace dos cosas:
pasa el extra `EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS` al reconocedor de Android y arma
un temporizador en Dart que llama a `stop()` si el resultado no cambia durante ese tiempo
(`lib/speech_to_text.dart`, `_setupListenAndPause`). El experimento quitó ambos a la vez, así que
no distingue cuál de los dos causaba los cortes; para la decisión no hace falta, porque los dos
salen con `pauseFor` nulo. POR VERIFICAR si pasa igual en otros equipos y versiones de Android.

### Ronda 3 (2026-10-02, versión final: R5 sin tiempo de silencio en Android, R9) — las 10 frases

Esta es la ronda que cuenta para AC8 en Android. Ningún corte a mitad de frase. La persona que
dictó no reportó el número de toques por frase.

| id | Esperado | Transcrito | Exacta | Palabras correctas | ¿Cambia el resultado? |
|---|---|---|---|---|---|
| s01 (intento 1) | dos huevos revueltos y una arepa pequeña con queso | dos huevos revueltos y una pequeña con queso | No | 8/9 (89 %) | Sí: se pierde "arepa" |
| s01 (intento 2) | dos huevos revueltos y una arepa pequeña con queso | de huevo revuelto si una arepa pequeña con queso | No | 5/9 (56 %) | Sí: se pierde la cantidad ("dos" → "de") |
| s02 | 150 gramos de pechuga de pollo a la plancha | 150 gramos de pechuga de pollo a la plancha | Sí | 8/8 | No |
| s03 | un café con leche | un café con leche | Sí | 4/4 | No |
| s04 | media taza de arroz blanco y un plátano maduro frito | media taza de arroz blanco y un plátano maduro frito | Sí | 10/10 | No |
| s05 | almorcé 180 g de arroz, medio aguacate y ensalada con una cucharada de aceite de oliva | almorcé 150 gramos de arroz medio aguacate y ensalada con una cucharada de aceite de oliva | No | 14/15 (93 %) | **Sí: cantidad equivocada (180 → 150 g)** |
| s06 | me comí un poquito de queso | Me comí un poquito de queso | Sí | 6/6 | No |
| s07 | una manzana | una manzana | Sí | 2/2 | No |
| s08 | dos tajadas de pan integral con mantequilla de maní | dos tajadas de pan integral con mantequilla de maní | Sí | 9/9 | No |
| s09 | un vaso de jugo de naranja | un vaso de jugo de naranja | Sí | 6/6 | No |
| s10 | hola, ¿cómo estás? | Hola cómo estás | Sí | 3/3 | No |

Prueba libre adicional (la persona que dictó, sin guion, ~40 palabras), transcrita completa sin
cortes: "desayuné una arepa con trocitos de carne un café con leche hecho con una cucharada de café
instantáneo y dos de leche en polvo adicionalmente mi snack fue un yogurt griego con fruta y para
el almuerzo arroz con atún y ensalada". No hay texto esperado con qué compararla; muestra que una
comida larga y realista entra en una sola escucha.

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
| Android (ronda 3; s01 = intento 1) | 8 | 98 % | 2 (s01: alimento perdido; s05: cantidad equivocada) |
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

**Android (motorola edge 50 pro, Android 16, es-CO):**
- Calidad suficiente para la beta: 8/10 exactas y 98 % de palabras correctas en la versión final.
  El usuario siempre ve y puede editar la transcripción antes de analizar (R6), y las cantidades
  se ven otra vez en la pantalla de revisión.
- Errores que cambian el registro: una palabra de alimento omitida ("arepa") y un número mal
  reconocido ("180" → "150"). Los números son el error más costoso: un número equivocado no se
  nota como raro. No hubo errores de tildes ni de palabras regionales ("arepa", "plátano maduro",
  "tajadas" se reconocieron bien cuando se oyeron).
- La causa principal de los malos resultados iniciales no era el reconocimiento sino la app: el
  bug de estado de R5/R9 y el tiempo de silencio de 2 s, que provocaba cortes. Ambos se arreglaron
  (commits `db5cf7d` y `8bccfad`).
- Privacidad: sin conexión no hay reconocimiento, así que con la configuración actual el audio se
  procesa en servidores de Google. Nunca pasa por nuestro backend.

**iOS:** pendiente.
