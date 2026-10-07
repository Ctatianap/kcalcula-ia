# SPEC-029: Vertex AI en el backend desplegado de desarrollo

## Status
Implementing
Path: Strict (proveedor de IA real; el texto y la foto de la etiqueta salen del dispositivo hacia
Google; cuesta dinero; skill `ai-pipeline`)

## Objective
Que la app instalada en el teléfono analice comidas y etiquetas con IA real (`gemini-2.5-flash` en
Vertex AI) llamando al backend desplegado en `kcalcula-ia-dev`, en lugar del proveedor `fake`.

## Context
Backlog T-027. El backend desplegado no define `AI_PROVIDER`, así que `selectProvider`
(`functions/src/index.ts`) usa `fake`, que solo conoce las 10 frases de prueba (`s01`–`s10`) y
devuelve `items: []` para cualquier otra. Por eso en el teléfono "la IA no funciona".

ADR-002 dejó Ollama para el MVP y Vertex "antes de salir al mercado, o antes si la usuaria lo
decide". La usuaria lo decidió el 2026-10-07 ("hagamos lo de vertex para que ya nos funcione la
ia"). Ollama no sirve para el backend desplegado: corre en el PC, no en la nube.

Ya está probado: el adaptador `vertex.ts` corrió contra Vertex real en `kcalcula-ia-dev` el
2026-10-02 (SPEC-001 AC11). Baseline `parse_meal.v1__vertex__gemini-2.5-flash__2026-10-02.json`:
esquema 50/50, detección 94,5 %, cantidad y unidad 90,7 %, latencia p50 3,0 s y p95 5,8 s.
`extractLabel` no tiene baseline con Vertex (solo con Ollama).

El consentimiento (`onboarding_screen.dart`) y `docs/privacy.md` ya nombran a Vertex AI (Google,
fuera de Colombia) como destino del texto y de la foto.

**Corrección (2026-10-07, al revisar Google Cloud):** el backend **nunca se ha desplegado** en
`kcalcula-ia-dev`: la API de Cloud Functions no está habilitada, y la API de Firebase App Check
tampoco. En el teléfono, `flutter run` registra `Failed to exchange debug token` y
`Firebase App Check API has not been used in project`. Así que la app no llegaba ni a `fake`: cada
análisis fallaba antes. La cuenta de servicio de Compute no tiene ningún rol en el proyecto. La
alerta de presupuesto ya existe desde SPEC-007 (paso 5 del Checklist de beta, "monto bajo").

## User Story
Como persona que usa la app en su teléfono, quiero escribir, dictar o fotografiar lo que comí y que
la IA real lo entienda, para no depender de las frases de prueba.

## Requirements
- R1. **Proveedor según el ambiente** (`functions/src/ai/provider_name.ts`). En el emulador
  (`FUNCTIONS_EMULATOR=true`) solo cuenta `AI_PROVIDER`. Desplegado cuenta `DEPLOYED_AI_PROVIDER` y,
  si no está, `AI_PROVIDER`. Sin configuración o con un valor desconocido: `fake`, así que el
  emulador, CI y los tests no llaman a Vertex ni cuestan dinero. El proveedor se crea en la primera
  llamada, no al cargar el módulo, para que `firebase deploy` no lea los params de Vertex.
- R2. **Configuración del despliegue de `kcalcula-ia-dev`** en `functions/.env.kcalcula-ia-dev`
  (ignorado por git; sin secretos): `DEPLOYED_AI_PROVIDER=vertex`, `VERTEX_PROJECT_ID=kcalcula-ia-dev`,
  `VERTEX_LOCATION=us-east1` y `GEMINI_MODEL_ID=gemini-2.5-flash` (los mismos valores por defecto del
  código: `firebase deploy --non-interactive` exige todos los params en el `.env` aunque tengan
  `default`). **Lo crea la
  usuaria**: la invariante 7 no me deja escribir archivos `.env`.
- R3. **Permisos:** la cuenta de servicio con la que corren `parseMeal` y `extractLabel` tiene el
  rol `roles/aiplatform.user` en `kcalcula-ia-dev`, y la API de Vertex AI está habilitada.
- R4. **El emulador no pasa a Vertex por accidente.** El emulador sí carga
  `functions/.env.kcalcula-ia-dev` (OQ3), pero ignora `DEPLOYED_AI_PROVIDER` (R1). Los comandos de
  CLAUDE.md siguen valiendo, con `AI_PROVIDER` en la línea de comandos.
- R5. **Control de gasto:** la alerta de presupuesto de SPEC-007 queda en USD 5 al mes con avisos al
  50/90/100 % (la usuaria la revisa y ajusta; no se crea otra). `maxInstances: 10` no cambia.
- R6. **Evals de etiquetas con Vertex:** `extract_label.v1` se corre con `AI_PROVIDER=vertex`.
  Exige esquema válido en el 100 % de los casos. El resultado se guarda como baseline solo si la
  usuaria lo aprueba.
- R7. **Logs:** solo metadatos (invariante 5). Se comprueba en Cloud Logging después del despliegue.
- R9. **Tiempo límite de las etiquetas:** `extractLabel` pasa de 10 s a 60 s, en la función
  (`timeoutSeconds`) y en la app (`HttpsCallableOptions`). `parseMeal` se queda en 10 s.
- R10. **Primer despliegue** de `parseMeal`, `extractLabel` y `healthCheck` en `kcalcula-ia-dev`
  (`us-east1`) con `firebase deploy --only functions`, que habilita las APIs que necesite (Cloud
  Functions, Cloud Build, Artifact Registry, Cloud Run, Eventarc). Si el build falla por permisos
  de la cuenta de servicio, se le dan solo los roles que pida el error y se documentan aquí.
- R11. **App Check en el proyecto:** se habilita `firebaseappcheck.googleapis.com` y la usuaria
  registra en la consola de Firebase el token de depuración de su teléfono (Android). El token no
  se escribe en el repo.
- R8. **Documentación:** ADR-002 registra el cambio de decisión (Vertex en dev desde 2026-10-07).
  `docs/privacy.md` deja de decir que la foto "no sale del dispositivo de desarrollo" en dev: con
  este cambio sale hacia Vertex AI, igual que el texto. `docs/architecture.md` y CLAUDE.md
  (Comandos) mencionan cómo se configura cada ambiente.

## Acceptance Criteria
- AC1. Con el backend desplegado, escribir en el teléfono "un caldo de costilla con arepa y un jugo
  de mora" (frase que `fake` no conoce) → el Detalle de comida muestra al menos caldo de costilla,
  arepa y jugo de mora, y no aparece la pantalla de "no encontré comida" `[manual]`.
- AC2. Con el backend desplegado, fotografiar una tabla nutricional real → la app muestra los
  valores transcritos para confirmar, y `nutrition_core` los valida (porción, Atwater) como hoy
  `[manual]`.
- AC3. En Cloud Logging, las entradas de AC1 y AC2 muestran el modelo `gemini-2.5-flash`, la
  versión del prompt, la latencia y los tokens, y **no** contienen el texto escrito ni la imagen
  `[manual]`.
- AC4. `AI_PROVIDER=vertex VERTEX_PROJECT_ID=kcalcula-ia-dev npm --prefix functions run
  evals:extract-label` → esquema válido 47/47. Un caso que falle por cuota (429) se repite solo
  con `--case=<id>` y cuenta si sale válido. Se informan la latencia p50/p95 y los tokens, y se
  comparan con el baseline de Ollama `[eval]`.
- AC5. `resolveProviderName`: sin variables → `fake`; desplegado con `DEPLOYED_AI_PROVIDER=vertex`
  → `vertex`; en el emulador con `DEPLOYED_AI_PROVIDER=vertex` → `fake`, y con
  `AI_PROVIDER=ollama` → `ollama` `[unit]`. Además, el emulador sin variables con
  `.env.kcalcula-ia-dev` creado responde `items: []` a una frase fuera de los fixtures `[manual]`.
- AC6. `npm --prefix functions run build && npm --prefix functions test` verdes. Ningún prompt,
  esquema ni adaptador cambia (`git diff develop -- functions/src/ai/prompts functions/src/ai/schemas.ts
  functions/src/ai/vertex.ts` vacío) `[unit]`.
- AC9. `gcloud functions list --project=kcalcula-ia-dev --regions=us-east1` muestra `parseMeal`,
  `extractLabel` y `healthCheck` en estado `ACTIVE` `[manual]`.
- AC10. En `flutter run` ya no aparecen `Failed to exchange debug token` ni el 403 de la API de App
  Check; AC1 cubre que la llamada pasa `enforceAppCheck` `[manual]`.
- AC8. `extractLabel` tiene `timeoutSeconds: 60` y la app espera 60 s; `parseMeal` sigue en 10 s.
  Una etiqueta real en el teléfono que tarde más de 10 s se lee sin error de tiempo agotado
  `[manual]`.
- AC7. Los documentos de R8 están actualizados y el reviewer lo comprueba `[manual]`.

## Technical Constraints
- Invariante 1 (la IA estructura, nunca calcula): no cambia; mismo prompt `parse_meal.v1` y mismo
  esquema.
- Invariante 5: logs solo con metadatos.
- Invariante 7: sin secretos; Vertex con la cuenta de servicio de Functions. Yo no leo ni escribo
  `.env`.
- `firebase deploy` y `gcloud` necesitan tu confirmación en cada uso.

## Components / Files Affected
- `functions/.env.kcalcula-ia-dev` (lo crea la usuaria; fuera de git).
- `functions/src/ai/provider_name.ts` (+ test), `functions/src/index.ts` (selección perezosa y
  timeout), `app/lib/infra/ai_client/ai_client.dart` (timeout),
  `functions/src/evals/run_extract_label.ts` (`--case`).
- `docs/decisions/ADR-002-ia-local-vs-vertex.md`, `docs/privacy.md`, `docs/architecture.md`,
  `CLAUDE.md` (Comandos).
- `evals/baselines/extract_label.v1__vertex__gemini-2.5-flash__<fecha>.json` (si se aprueba).
- IAM de `kcalcula-ia-dev` (consola o `gcloud`).

## Dependencies
- SPEC-001 (adaptador Vertex), SPEC-004 (etiquetas), SPEC-005 (evals), SPEC-007 (App Check,
  `maxInstances`), ADR-002.
- Facturación activa en `kcalcula-ia-dev` (ya lo estaba el 2026-10-02).

## Edge Cases
- **Falta el permiso de Vertex** (R3): la función falla. La app debe mostrar el error de IA en
  español, con "Reintentar" y "Buscar en la base manualmente" (SPEC-012 y SPEC-018), sin trazas.
  Se comprueba de paso en AC1 si ocurre.
- **Vertex tarda más que el tiempo límite** (texto: p95 5,8 s contra 10 s; etiqueta: p95 21 s y
  máximo 37,6 s contra 60 s): la app muestra el error de tiempo agotado que ya existe.
- **Respuesta inválida del modelo**: un reintento y luego `ai-invalid-output`, como hoy.
- **Sin red en el teléfono**: igual que hoy.
- **Cuota de Vertex agotada o facturación desactivada**: error de IA en la app; la alerta de
  presupuesto (R5) avisa antes.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? **Sí en la práctica, no en el diseño.** El texto y la foto
  de la etiqueta pasan a llegar a Vertex AI (Google, `us-east1`) desde el backend de desarrollo.
  Hoy, con `fake`, no salen del backend. El consentimiento y `docs/privacy.md` ya lo declaran para
  Vertex; R8 corrige la frase de la foto en desarrollo.
- PV-03 sigue abierto en lo que falta confirmar del texto oficial (caché de datos y registro de
  abuso). Ver Open Questions.
- El único usuario de `kcalcula-ia-dev` hoy es la usuaria. No hay beta abierta.

## Tests Required
- Unit: AC6 (la suite existente con `fake`).
- Eval: AC4.
- Manual: AC1, AC2, AC3, AC5, AC7.

## Out of Scope
- El proyecto de producción `kcalcula-ia` y la salida al mercado.
- Cambiar el prompt, el esquema, el modelo, la región o el timeout de `parseMeal`.
- Desactivar el razonamiento ("thinking") de `gemini-2.5-flash` para bajar la latencia: T-028.
- Pedir a Google la excepción del registro de abuso.
- Volver a correr el baseline de `parse_meal` con Vertex: el modelo y el prompt son los mismos del
  2026-10-02.

## Open Questions
- OQ1. **Monto de la alerta de presupuesto (R5).** Recomendación: USD 5 al mes, con avisos al 50 %,
  90 % y 100 %. Con unas 650 tokens de entrada y 170 de salida por análisis de texto, son miles de
  análisis antes de llegar a USD 1 (el precio en Vertex sigue POR VERIFICAR, PV-02). La alerta
  avisa, **no corta** el gasto.
- OQ2. **Caché de datos de Vertex.** Se desactiva (decisión de la usuaria) con
  `PATCH .../v1/projects/kcalcula-ia-dev/cacheConfig` y `disableCache: true`, que aplica a todo el
  proyecto (`docs/research/2026-10-07-vertex-dev-config.md`, confianza media-alta). La lectura del
  2026-10-07 devuelve `retentionConfig.retentionType: DURABLE` y ningún `disableCache`: el campo
  de retención no estaba en la investigación. Después del PATCH se vuelve a leer; si sigue
  `DURABLE`, se le pregunta al `researcher` antes de dar la caché por desactivada.
- OQ3. **¿El emulador carga `.env.kcalcula-ia-dev`?** Resuelta
  (`docs/research/2026-10-07-vertex-dev-config.md`): sí, y los `.env` ganan sobre el shell. Por eso
  R1 usa `DEPLOYED_AI_PROVIDER`. `FUNCTIONS_EMULATOR="true"` confirmado en `firebase-tools` 15.31.0
  (`lib/emulator/functionsEmulator.js`).

## Definition of Done
- AC1–AC7 con evidencia · build y tests de `functions` verdes · evals de etiquetas con esquema
  100 % · reviewer PASS enlazado · ADR-002, privacy y architecture actualizados · aprobación de la
  usuaria (Strict).

## Change Log
- 2026-10-07: creación a pedido de la usuaria ("hagamos lo de vertex para que ya nos funcione la
  ia"). Backlog T-027.
- 2026-10-07: **Approved por la usuaria** ("aprobada la SPEC-029, sigue"), con las recomendaciones
  de OQ1 (alerta de USD 5 al mes, avisos al 50/90/100 %) y OQ2 (desactivar la caché de datos).
  Status → Implementing.
- 2026-10-07: hallazgos que contradicen la SPEC; implementación detenida a la espera de la usuaria.
  (1) Evals de etiquetas con Vertex (AC4, sin guardar baseline): esquema 46/47 (el caso que falla,
  `label_52`, es un 429 RESOURCE_EXHAUSTED de cuota, no una salida inválida); campos 697/725
  (96,1 %; Ollama: 73,0 %); 2 campos puntuados inventados (`label_38`, azúcar 0 donde se esperaba
  null); latencia p50 8,5 s, p95 21,2 s, máximo 37,6 s; 13 de 46 casos pasan de 10 s, así que con
  el timeout actual (10 s en la función y en la app) fallaría cerca de 1 de cada 4 etiquetas.
  (2) `docs/research/2026-10-07-vertex-dev-config.md` (OQ3): el emulador carga
  `.env.kcalcula-ia-dev` y los valores de los `.env` ganan sobre la variable del shell, así que R4
  no se puede cumplir sin cambiar código: sin `.env.local` el emulador usaría Vertex; con
  `AI_PROVIDER=fake` en `.env.local`, `AI_PROVIDER=ollama` en la línea de comandos dejaría de
  funcionar.

- 2026-10-07: **la usuaria aprueba los cuatro cambios** ("aprobad"): R1 y R4 con
  `DEPLOYED_AI_PROVIDER` y selección por ambiente (cambia código); R9 timeout de 60 s en
  `extractLabel`; AC4 repite un 429 con `--case`; acepta como regresión conocida los 2 campos
  inventados de `label_38` (azúcar 0 sin estar impreso; la persona confirma los valores) y abre T-028
  (razonamiento del modelo). Status sigue en Implementing.
- 2026-10-07: implementados R1, R4 y R9; `--case` en el runner. `label_52` repetido: válido, 17/17
  campos. functions 57/57; app analyze sin avisos y 324/324.
- 2026-10-07: hueco en la SPEC al revisar Google Cloud: el backend nunca se desplegó y la API de App
  Check no está habilitada. Se añaden R10 (primer despliegue), R11 (App Check y token de
  depuración), AC9 y AC10; R5 reutiliza la alerta de SPEC-007; OQ2 anota `DURABLE`. Status →
  Draft hasta que la usuaria lo apruebe.
- 2026-10-07: **Approved por la usuaria** el cambio (R10, R11, R5, AC9, AC10) ("aprobado"). Status →
  Implementing.
- 2026-10-07: API de App Check habilitada. Caché de Vertex desactivada: el PATCH con
  `disableCache: true` terminó bien y la nueva lectura devuelve `"disableCache": true`, sin
  `retentionConfig` (el `DURABLE` desapareció). El rol de Vertex no se pudo dar todavía: la cuenta
  de servicio de Compute **aún no existe**; se crea al habilitar las APIs del primer despliegue (R10).
- 2026-10-07: primer `firebase deploy` detenido antes de subir nada: habilitó Cloud Functions,
  Cloud Build, Artifact Registry y Extensions, y luego pidió `VERTEX_LOCATION` y `GEMINI_MODEL_ID`
  en el `.env`. R2 ahora los incluye.

## Review
Informe del reviewer:
