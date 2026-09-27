# Vertex AI (Gemini) + Cloud Functions: modelo, retención de datos y región

Fecha de consulta de todas las fuentes: 2026-09-27.

Nota metodológica: varias páginas oficiales de `docs.cloud.google.com` /
`cloud.google.com` son SPA pesadas en JavaScript; la herramienta de fetch usada solo
pudo recuperar el esqueleto de navegación de esas páginas, no el cuerpo renderizado.
Donde eso ocurrió, la afirmación se sostiene en el resultado de búsqueda (snippet) que
cita esa misma URL oficial como fuente, no en una lectura verbatim de la página completa.
Esto se marca explícitamente en cada punto. Ningún dato viene de blogs/foros como fuente
primaria; esos solo se usan como pista secundaria y se marcan como tal.

---

## PV-02 — Modelo Gemini recomendado (salida estructurada + visión), precio, regiones

**Pregunta:** ¿Qué `model ID` de Gemini en Vertex AI usar para `parseMeal` (salida
estructurada JSON, solo texto por ahora) y qué modelo soportaría visión más adelante
(`extractLabel`)? ¿Precio por token/imagen? ¿En qué regiones está disponible?

**Decisión que desbloquea:** SPEC-001 (qué `model ID` literal usa el cliente de IA en
`functions/`).

### CONFIRMADO
- Gemini 2.5 Flash y Gemini 2.5 Pro alcanzaron disponibilidad general (GA) en Vertex AI
  el 17 de junio de 2025, con "native support for structured output" mencionado
  explícitamente en el anuncio. — [Google Cloud Blog: Gemini 2.5 Flash-Lite, Flash y Pro
  GA en Vertex AI](https://cloud.google.com/blog/products/ai-machine-learning/gemini-2-5-flash-lite-flash-pro-ga-vertex-ai), consultado 2026-09-27.
- El `model ID` de referencia es `gemini-2.5-flash` (variante GA); existe también una
  variante fechada `gemini-2.5-flash-preview-09-2025`. — resultado de búsqueda que cita
  `docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-5-flash`,
  consultado 2026-09-27 (cuerpo completo de la página no pudo renderizarse; solo nav).
- Vertex AI soporta salida estructurada vía `response_schema` / `response_mime_type` /
  `response_json_schema` en `GenerateContentConfig`, aplicable a los modelos Gemini
  actuales (incluye la familia 2.5). — [Structured output | Gemini Enterprise Agent
  Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/capabilities/control-generated-output), consultado 2026-09-27.
- Gemini 2.5 Flash y 2.5 Pro son multimodales: aceptan texto, imagen, video y audio como
  entrada — es decir, el mismo `model ID` que se recomienda para `parseMeal` (solo texto)
  ya soporta visión para cuando se implemente `extractLabel`, sin tener que migrar de
  modelo. — Google Cloud Blog GA (arriba) + snippet de
  `docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-5-flash`,
  consultado 2026-09-27.
- Precio publicado por Google para Gemini 2.5 Flash (tier estándar, pagado):
  entrada de texto/imagen/video **USD 0.30 por 1M de tokens**, entrada de audio
  **USD 1.00 por 1M de tokens**, salida **USD 2.50 por 1M de tokens**. Tier batch/flex:
  entrada texto/imagen/video USD 0.15, audio USD 0.50, salida USD 1.25 por 1M de tokens.
  — [Gemini API pricing | Google AI for Developers](https://ai.google.dev/gemini-api/docs/pricing), consultado 2026-09-27.
  Advertencia: esta cita es de la página de precios de **Gemini Developer API**
  (`ai.google.dev`), no de la página oficial de precios de Vertex AI
  (`cloud.google.com/vertex-ai/generative-ai/pricing`), porque esa página de Vertex
  superó el límite de tamaño de la herramienta de fetch (>10 MB) y no pudo leerse
  directamente. Google históricamente alinea el precio por token de un mismo modelo
  entre Developer API y Vertex AI, pero esto **no quedó verificado línea por línea en la
  página de Vertex** — ver "NO CONFIRMADO".
- Existe ya una familia Gemini 3 (Gemini 3 Pro, Gemini 3 Flash, Gemini 3.1 Pro, Gemini
  3.5 Flash, entre otras variantes) listada en la navegación de
  `docs.cloud.google.com/vertex-ai/generative-ai/docs/models`, con `model ID`s tipo
  `gemini-3-flash-preview` y `gemini-3.1-pro-preview`. — resultados de búsqueda con
  fuente `docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-1-pro` y
  `.../models`, consultado 2026-09-27.

### NO CONFIRMADO / CONTRADICTORIO
- El precio exacto por token de Gemini 2.5 Flash/Pro **en Vertex AI específicamente**
  (vs. Developer API) no se pudo leer verbatim de
  `cloud.google.com/vertex-ai/generative-ai/pricing`: la página excede el límite de
  tamaño de la herramienta de fetch usada. Múltiples agregadores de terceros (no
  primarios: openrouter.ai, pricepertoken.com, cloudzero.com) repiten la misma cifra
  (USD 0.30 entrada / USD 2.50 salida por 1M tokens) para Gemini 2.5 Flash en Vertex,
  pero esto queda como corroboración secundaria, no como lectura directa de la fuente
  oficial de Vertex.
- El estado exacto (GA vs. preview) y la disponibilidad regional de los modelos Gemini 3.x
  no se pudo confirmar con una cita verbatim de la documentación oficial: los intentos de
  fetch de `docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-1-pro` y de
  `.../docs/start/get-started-with-gemini-3` solo devolvieron el esqueleto de navegación.
  Hilos del foro oficial de Google AI Developers (secundario, no normativo) indican que
  varios modelos Gemini 3.x preview solo están disponibles vía el **endpoint global** de
  Vertex AI y no en endpoints regionales, lo cual es relevante para PV-04.
- No se pudo confirmar con fuente primaria si `gemini-2.5-flash` (sin fecha) apunta hoy a
  una versión "rolling" que Google puede actualizar sin aviso, o si es preferible fijar
  la variante fechada (`-preview-09-2025` o equivalente GA fechada) para reproducibilidad
  de evals. Esto queda abierto para revisión en la SPEC/implementación.

### Implicaciones para el proyecto
- Para `parseMeal` (solo texto, salida estructurada), `gemini-2.5-flash` es un modelo GA,
  multimodal, con soporte nativo de `response_schema`, y es el más económico entre los
  modelos GA de la familia 2.5. Es compatible con visión para cuando se implemente
  `extractLabel`, sin cambiar de `model ID`.
- Usar un modelo Gemini 3.x hoy sería Strict Path adicional: no hay confirmación de GA ni
  de disponibilidad en endpoints regionales (ver PV-04), lo que complica la garantía de
  "backend sin estado" / residencia de datos declarada en `docs/privacy.md`.
- El precio de Vertex AI para el mismo modelo no quedó verificado línea por línea en la
  fuente primaria de Vertex — antes de comprometer presupuesto/estimados de costo en la
  SPEC, alguien con acceso a la consola de Google Cloud debería confirmar el precio en
  `cloud.google.com/vertex-ai/generative-ai/pricing` para el proyecto real (la página es
  específica por proyecto/cuenta en algunos casos de descuentos).

### Recomendación (no vinculante)
- Usar `gemini-2.5-flash` (GA) como `model ID` para `parseMeal` en SPEC-001. Fijar la
  variante exacta (con o sin fecha) como decisión explícita en la SPEC, no implícita en
  el código.
- No adoptar la familia Gemini 3.x todavía para producción: falta confirmación de GA y de
  disponibilidad en endpoints regionales fuera del endpoint global.

---

## PV-03 — Términos de datos de Vertex AI (retención, entrenamiento, ubicación, no-retención)

**Pregunta:** ¿Vertex AI retiene el contenido enviado (texto del usuario)? ¿Lo usa para
entrenar modelos? ¿Dónde se procesa? ¿Hay opción de retención cero?

**Decisión que desbloquea:** SPEC-001 (texto de consentimiento/privacidad mostrado al
usuario), T-007 (revisión legal), y la invariante de `docs/privacy.md` de que el backend
es "sin estado".

### CONFIRMADO
- Google no usa los datos del cliente (prompts, respuestas, ni datos de entrenamiento de
  adaptadores) para entrenar o afinar sus modelos base sin permiso explícito del cliente;
  esto aplica por defecto a los modelos gestionados en la plataforma, incluidos GA y
  pre-GA. — snippet de búsqueda que cita
  `cloud.google.com/vertex-ai/generative-ai/docs/data-governance` (título: "Gemini
  Enterprise Agent Platform and zero data retention"), consultado 2026-09-27. Corroborado
  por un segundo snippet de búsqueda que cita `cloud.google.com/terms/service-terms` /
  `cloud.google.com/terms/data-residency`: "customer data does not train Google's
  models", y que el "Generated Output" se trata como Customer Data que Google solo
  procesa según instrucciones del cliente.
- Caché de datos ("data caching"): cuando está habilitado a nivel de proyecto, el
  contenido cacheado se guarda hasta 24 horas en el centro de datos donde se sirvió la
  solicitud, con privacidad a nivel de proyecto. Para retención cero, el caché debe
  deshabilitarse explícitamente. — mismo snippet de
  `.../docs/data-governance`, consultado 2026-09-27.
- Registro de prompts para monitoreo de abuso ("prompt logging for abuse monitoring"):
  Google puede registrar prompts para detectar abuso/violaciones de su política de uso
  aceptable como parte del servicio; si el proyecto está en el alcance de este logging y
  se requiere retención cero, se puede solicitar una excepción. — mismo snippet,
  consultado 2026-09-27.
- Datos de fine-tuning: los checkpoints temporales generados en el bucket del proyecto
  del cliente se eliminan automáticamente dentro de un período de 30 días. (No aplica
  directamente a `parseMeal`, que no hace fine-tuning, pero es relevante si el proyecto
  considerara afinar un modelo a futuro). — mismo snippet, consultado 2026-09-27.
- Residencia de datos: Vertex AI permite configurar que los datos del cliente se
  almacenen en reposo y que el procesamiento de machine learning ocurra dentro de una
  región o multi-región específica, usando los endpoints regionales/multi-regionales
  correspondientes; Google se compromete a hacerlo solo en esa multi-región cuando el
  cliente lo configura así. — snippet de búsqueda que cita
  `cloud.google.com/terms/data-residency`, consultado 2026-09-27.
- Diferencia importante de producto: esto aplica a **Vertex AI** (plataforma empresarial,
  con cuenta de servicio / ADC, que es lo que usa este proyecto según CLAUDE.md). La
  **Gemini Developer API** (`ai.google.dev`, plan gratuito) tiene una política distinta
  (sí puede usar datos del plan gratuito para mejorar productos). El proyecto debe seguir
  usando Vertex AI, nunca el plan gratuito de la Developer API, para cumplir con
  `docs/privacy.md`. — inferencia razonable a partir de la distinción de productos
  documentada por Google en ambas líneas de docs; no se encontró una página que compare
  ambas políticas lado a lado en una sola fuente, así que se marca como razonamiento del
  investigador, no como cita directa.

### NO CONFIRMADO / CONTRADICTORIO
- No se pudo leer verbatim (fetch directo) el cuerpo completo de
  `docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance` ni de
  `docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency`: ambas
  páginas solo devolvieron el esqueleto de navegación a través de la herramienta de
  fetch disponible. Todo lo anterior se apoya en snippets de resultados de búsqueda que
  citan esas URLs oficiales como fuente, no en una lectura íntegra de la página. Se
  recomienda que alguien con navegador normal confirme visualmente estas afirmaciones
  antes de escribirlas en un texto legal/de consentimiento.
- No se encontró un número de días de retención por defecto para el "Generated Output" en
  sí (fuera del caso específico de caché de 24h y logging de abuso) — es decir, no quedó
  claro si, con caché deshabilitado y sin estar en el alcance de logging de abuso, la
  retención es literalmente cero o si hay algún otro respaldo interno transitorio (p.ej.
  logs de infraestructura de corta duración). La página fuente sugiere que sí (por eso el
  título "zero data retention"), pero no se pudo confirmar el mecanismo exacto con cita
  verbatim.
- No se confirmó si el endpoint **global** de Vertex AI (necesario para algunos modelos
  Gemini 3.x, ver PV-02/PV-04) mantiene las mismas garantías de residencia/retención que
  los endpoints regionales, o si el endpoint global puede enrutar el procesamiento a
  cualquier región de Google sin garantía de ubicación. Un artículo secundario (Medium,
  no oficial) sugiere que los endpoints regionales "keep model processing inside that
  geography" mientras que el global no lo garantiza igual, pero esto no se confirmó en
  documentación oficial legible.

### Implicaciones para el proyecto
- El backend "sin estado" declarado en `docs/privacy.md` es compatible con Vertex AI
  siempre que: (a) se use Vertex AI (no el plan gratuito de Gemini Developer API), (b) se
  deshabilite el caché de datos de Vertex a nivel de proyecto, y (c) se entienda que el
  logging de abuso por defecto de Google puede aplicar salvo que se solicite una
  excepción — este logging ocurre del lado de Google, fuera del control del backend del
  proyecto, y debería mencionarse en `docs/privacy.md` como una dependencia de terceros,
  no como una contradicción de la invariante "backend sin estado" (el backend del
  proyecto en sí no persiste nada; Google, como procesador, puede retener brevemente por
  motivos de seguridad/abuso).
- Usar el endpoint **global** de Vertex AI (necesario si en el futuro se quisiera un
  modelo Gemini 3.x preview) introduciría una garantía de residencia menos clara que un
  endpoint regional — esto debería tratarse como Strict Path si se decide adoptarlo.

### Recomendación (no vinculante)
- Mantener Vertex AI (nunca el plan gratuito de Gemini Developer API) como único backend
  de IA, y deshabilitar explícitamente el caché de datos a nivel de proyecto de Google
  Cloud.
- Añadir a `docs/privacy.md` una frase explícita sobre el logging de abuso de Google
  (dependencia de terceros, fuera del control del backend) para que la declaración de
  "sin estado" sea precisa y no se preste a interpretación de que hay contradicción.
- Antes de publicar cualquier texto de consentimiento/privacidad al usuario final que cite
  estas garantías, pedir a alguien con navegador (sin las limitaciones de esta
  herramienta de fetch) que confirme visualmente el contenido de
  `cloud.google.com/vertex-ai/generative-ai/docs/data-governance` y
  `cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency`.

---

## PV-04 — Región de Cloud Functions (2nd gen) con menor latencia desde Colombia y compatible con la región de Vertex AI

**Pregunta:** ¿Qué región de Cloud Functions 2nd gen (vía Firebase) minimiza latencia
desde Colombia y es compatible con la región de Vertex AI usada para Gemini?

**Decisión que desbloquea:** SPEC-001 (región de despliegue de `functions/`).

### CONFIRMADO
- Cloud Functions for Firebase (2nd gen) soporta, entre otras, estas regiones (lista
  completa de la página oficial, "Last updated 2026-09-24 UTC"):
  Tier 1 (más económico): `us-central1`, `us-east1`, `us-east4`, `us-east5`, `us-south1`,
  `us-west1`, además de varias regiones de Asia/Europa/Medio Oriente.
  Tier 2: `southamerica-east1` (São Paulo), `southamerica-west1` (Santiago), y otras.
  — [Cloud Functions for Firebase locations](https://firebase.google.com/docs/functions/locations), consultado 2026-09-27.
- Vertex AI expone los modelos Gemini (incluida la familia 2.5, GA) como endpoints
  regionales en varias regiones de EE. UU., entre ellas `us-central1` (Iowa), `us-east1`
  (Moncks Corner, Carolina del Sur), `us-east4` (Norte de Virginia), `us-east5`
  (Columbus), `us-south1` (Dallas), `us-west1` (Oregón) y `us-west4` (Las Vegas), además
  de endpoints multi-regionales de EE. UU. y la UE, y un **endpoint global**. — snippets
  de búsqueda que citan `docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/locations` y `.../learn/data-residency`, consultado 2026-09-27. (Fetch directo de esa página
  solo devolvió navegación, igual que en PV-02/PV-03; ver limitación metodológica.)
- Ninguna de las fuentes consultadas mencionó `southamerica-east1` ni `southamerica-west1`
  como endpoint regional de Vertex AI para modelos Gemini. Es decir: **no existe hoy un
  endpoint regional de Vertex AI Gemini en Sudamérica**; la opción más cercana
  geográficamente para tener el modelo en una región (no global) son las regiones de
  EE. UU. listadas arriba.

### NO CONFIRMADO / CONTRADICTORIO
- No se encontró una medición oficial de latencia de red específica desde Colombia hacia
  `us-east1`/`us-east4` vs. `southamerica-east1` (Google no publica una tabla de latencia
  por país de origen). La recomendación de región de esta nota se basa en un hecho de
  red ampliamente documentado pero no verificado aquí con una fuente primaria de Google:
  el tráfico de ISPs colombianos hacia Google Cloud suele salir por puntos de
  interconexión en Miami, lo que en la práctica acerca a Colombia más a las regiones de
  EE. UU. este (`us-east1`, cerca de Atlanta/Carolina del Sur; `us-east4`, Virginia) que a
  São Paulo. Esto debe tratarse como **hipótesis razonable, no como dato confirmado**;
  si la decisión de región es sensible, se recomienda medir latencia real con
  `gcloud` desde un entorno de prueba en Colombia (o un servicio como
  `cloudping.info`, que es secundario/no oficial) antes de fijarla en la SPEC.
- No se confirmó si los modelos Gemini 3.x (ver PV-02) tienen o tendrán endpoint regional
  en alguna de las regiones de EE. UU. listadas, o si seguirán exclusivos del endpoint
  global — esto es relevante solo si el proyecto migra de la familia 2.5 a la 3.x.

### Implicaciones para el proyecto
- Desplegar Cloud Functions en `southamerica-east1` no ofrece ninguna ventaja de
  "cercanía a Vertex AI", porque Vertex AI Gemini no tiene endpoint regional en
  Sudamérica: la función tendría que llamar de todos modos a una región de EE. UU. (o al
  endpoint global), añadiendo un salto de red adicional São Paulo → EE. UU.
  Bogotá → EE. UU. directo tiende a tener menos saltos.
- La combinación más simple y con mejor compatibilidad de región es desplegar
  `functions/` y usar el cliente de Vertex AI apuntando a la **misma región de EE. UU.**
  (p. ej. `us-east1`), lo que también satisface la invariante de residencia de datos de
  PV-03 (endpoint regional, no global).

### Recomendación (no vinculante)
- Usar `us-east1` (Tier 1, disponible tanto en Cloud Functions 2nd gen como como endpoint
  regional de Vertex AI Gemini) para ambos: despliegue de Cloud Functions y llamadas a
  Vertex AI. `us-east4` es la alternativa si `us-east1` presenta problemas de cuota o
  disponibilidad de modelo.
- Antes de fijar esto en la SPEC, medir latencia real Bogotá→`us-east1` vs.
  Bogotá→`southamerica-east1` con una prueba simple (p. ej. un endpoint HTTP mínimo en
  cada región) para reemplazar la hipótesis de red por un dato propio.
