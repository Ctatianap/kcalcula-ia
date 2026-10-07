# ADR-002 — Modelo local (Ollama) durante el MVP, Vertex AI antes de salir al mercado

Estado: Aceptado, modificado el 2026-10-07 (ver Actualización) · Fecha: 2026-09-27

## Contexto
D7 de ADR-001 ya deja el proveedor de IA detrás de un adaptador (`AiProvider`) con Gemini vía
Vertex AI como proveedor inicial. Vertex AI no tiene capa gratuita: cada llamada cuesta dinero real
desde la primera, aunque sea centavos con `gemini-2.5-flash`. El proyecto todavía es un MVP sin
usuarios ni fecha de salida al mercado, y el usuario prefiere no gastar dinero real en una app que
todavía se está construyendo (ver decisión y motivo en la memoria de la sesión).

## Decisión
Mientras el proyecto sea un MVP en construcción (sin salir al mercado): usar un modelo local vía
[Ollama](https://ollama.com) corriendo en la máquina de desarrollo (`gemma4:e4b` por defecto,
~9.6 GB, soporta español y salida JSON estructurada de forma nativa) como `AiProvider` de
desarrollo, seleccionable con `AI_PROVIDER=ollama`. `vertex.ts` queda intacto y listo para producción
— cambiar de proveedor es solo cambiar la variable de entorno, sin tocar `schemas.ts`, `handler.ts`
ni el prompt.

**Cuándo volver a Vertex AI:** antes de que la app salga al mercado (fin de T-008, "Endurecimiento
para beta"), o antes si el usuario decide correr los evals reales de AC11 sobre `kcalcula-ia-dev`.

## Por qué
- Costo cero mientras se construye la app (sin usuarios reales que dependan de la calidad del
  modelo todavía).
- Mismo esquema, mismo prompt (`parse_meal.v1.md`), mismo handler y reintento que Vertex — el
  adaptador ya estaba diseñado para esto (D7 de ADR-001), así que no es una desviación de
  arquitectura, es usar el adaptador para lo que fue pensado.
- Ollama expone salida estructurada nativa vía JSON Schema (`z.toJSONSchema(parsedMealSchema)`
  directamente, sin duplicar el esquema a mano como sí hizo falta para Vertex).

## Alternativas consideradas
- **IA en el dispositivo del usuario final** (Gemini Nano/AICore en Android, Apple Intelligence/
  Foundation Models en iOS): ambos ya soportan español y JSON estructurado, pero Android sigue en
  *Developer Preview* (sin dispositivos de producción todavía) y ambos solo funcionan en hardware
  reciente/compatible — dejaría sin la función principal a buena parte de los usuarios en Colombia
  con celulares más antiguos o de gama media. Se descarta para producción por ahora; podría
  revisarse a futuro como *fallback* opcional, no como reemplazo de Vertex AI.
- **Gemini Developer API gratuita** (`ai.google.dev`, no Vertex AI): tiene capa gratuita real, pero
  sus términos permiten usar los datos para mejorar productos de Google — contradice el principio ya
  documentado en `docs/privacy.md` ("los datos del usuario no se usan para entrenar modelos") y lo
  que ya se había resuelto en PV-03. Descartada.

## Trade-off
- La calidad de extracción de `gemma4:e4b` no está medida contra el smoke test todavía (no hay
  baseline); puede diferir de `gemini-2.5-flash` en casos ambiguos. Aceptable mientras solo el
  desarrollador prueba la app.
- Requiere que quien desarrolle tenga Ollama instalado y el modelo descargado localmente
  (`brew install ollama && ollama pull gemma4:e4b`); no es parte del build reproducible de CI.

## Actualización 2026-10-07 — Vertex AI en el backend desplegado de desarrollo
La usuaria adelantó el cambio a Vertex AI ("hagamos lo de vertex para que ya nos funcione la ia"):
el backend desplegado no puede usar Ollama (corre en el PC, no en la nube), así que con `fake` la
app en el teléfono solo reconocía las frases de prueba. Desde SPEC-029, `kcalcula-ia-dev` usa
`DEPLOYED_AI_PROVIDER=vertex` en `functions/.env.kcalcula-ia-dev` (`gemini-2.5-flash`, `us-east1`;
`AI_PROVIDER` no, porque el emulador también carga ese archivo y pasaría a Vertex), con timeouts de
10 s en `parseMeal` y 60 s en `extractLabel`, con una alerta de presupuesto de 5.000 COP al mes (≈ USD 1,2; decisión de la usuaria, por ahora)
y la caché de datos de Vertex desactivada. Ollama sigue disponible para el emulador local, y `fake`
sigue siendo el valor por defecto del código (emulador, CI y tests sin costo). El proyecto de
producción `kcalcula-ia` queda para cuando la app salga al mercado.
