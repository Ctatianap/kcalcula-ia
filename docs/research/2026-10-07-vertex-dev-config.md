# Configuración de Vertex AI en `kcalcula-ia-dev` (SPEC-029: OQ2, OQ3, R3)

Pregunta:
1. (OQ2) ¿Cómo se desactiva a nivel de proyecto la caché de datos de Vertex AI para Gemini (retención
   cero)? Comando, endpoint, alcance (global o por región), lectura del estado y permisos IAM.
2. (OQ3) Con `functions/.env`, `functions/.env.<projectId>` y `functions/.env.local`, ¿qué archivos carga
   el emulador de Functions y con qué precedencia? ¿Una variable puesta en la línea de comandos gana
   sobre los `.env`? (El código lee `process.env.AI_PROVIDER` y usa `defineString` para `VERTEX_PROJECT_ID`).
3. (R3) ¿Con qué cuenta de servicio corren por defecto las Functions 2nd gen? ¿Basta `roles/aiplatform.user`
   para `generateContent`? Comandos para dar el rol, comprobarlo y comprobar la API.

Decisión que desbloquea: pasos de despliegue de SPEC-029 (R3, R4, OQ2) y si R4 (`.env.local` con
`AI_PROVIDER=fake`) es compatible con los comandos de emulador de CLAUDE.md.

Fecha de consulta de todas las fuentes: 2026-10-07.

Nota de método: la herramienta de lectura web solo devolvió el menú de navegación de varias páginas de
`docs.cloud.google.com` (la de retención cero, la de control de acceso y la referencia REST). En esos casos
el contenido se tomó de los fragmentos que el buscador extrae de la página oficial; se indica como
"vía fragmento de búsqueda". Para OQ3 la documentación de Firebase no detalla la precedencia con el
entorno del shell, así que se leyó el código fuente de `firebase-tools` (rama `master`).

## CONFIRMADO

### 1. Caché de datos de Vertex AI (OQ2)
- Por defecto los modelos Gemini guardan en caché entradas y salidas hasta 24 h; para retención cero hay
  que desactivar la caché, y se desactiva **a nivel de proyecto** — Google Cloud, "Gemini Enterprise Agent
  Platform and zero data retention" (https://docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention,
  2026-10-07, vía fragmento de búsqueda).
- **El cambio aplica a todas las regiones de Google Cloud** (no es por región; no hace falta `us-east1`)
  — misma página (2026-10-07, vía fragmento de búsqueda).
- Leer el estado actual (ejemplo de la página oficial, que usa el host `us-central1-aiplatform`):
  ```
  curl -X GET \
    -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type: application/json" \
    https://us-central1-aiplatform.googleapis.com/v1/projects/PROJECT_ID/cacheConfig
  ```
  Respuesta con caché activa: solo `"name": "projects/PROJECT_ID/cacheConfig"`. Con caché desactivada:
  incluye además `"disableCache": true` — misma página (2026-10-07, vía fragmento de búsqueda).
- Desactivar:
  ```
  curl -X PATCH \
    -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type: application/json" \
    https://us-central1-aiplatform.googleapis.com/v1/projects/PROJECT_ID/cacheConfig \
    -d '{ "name": "projects/PROJECT_ID/cacheConfig", "disableCache": true }'
  ```
  — misma página (2026-10-07, vía fragmento de búsqueda).
- Referencia REST `projects.updateCacheConfig`: `PATCH https://aiplatform.googleapis.com/v1/{cacheConfig.name}`,
  con `cacheConfig.name` de la forma `projects/{project}/cacheConfig` —
  https://docs.cloud.google.com/vertex-ai/generative-ai/docs/reference/rest/v1/projects/updateCacheConfig
  (2026-10-07, vía fragmento de búsqueda; la URL directa devolvió 404 sin el parámetro `authuser`).
- **Permiso:** para ejecutar el cambio el usuario necesita el rol **`roles/aiplatform.admin`**
  (Gemini Enterprise Agent Platform Administrator) — página de retención cero (2026-10-07, vía fragmento
  de búsqueda). `roles/aiplatform.user` no aparece como suficiente.
- La caché por defecto es en memoria (no en reposo), aislada por proyecto, TTL 24 h; Google afirma que
  eso "no viola" la retención cero; aun así se puede desactivar con `disableCache` — misma página y
  https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview
  (2026-10-07, vía fragmento de búsqueda). Para no retener caché además hay que no crear cachés
  explícitas (el proyecto no las usa).

### 2. Archivos `.env` en el emulador (OQ3)
- Documentación de Firebase: `.env.local` tiene precedencia sobre `.env` y sobre el `.env` específico
  del proyecto cuando se usa el emulador; los `.env.<project_ID>` se incluyen en el despliegue a ese
  proyecto — https://firebase.google.com/docs/functions/config-env (2026-10-07, vía fragmento de búsqueda).
- Código de `firebase-tools` (`src/functions/env.ts`, función `findEnvfiles`, rama `master`,
  https://raw.githubusercontent.com/firebase/firebase-tools/master/src/functions/env.ts, 2026-10-07):
  ```
  const files: string[] = [".env"];
  files.push(`.env.${projectId}`);
  if (projectAlias) { files.push(`.env.${projectAlias}`); }
  if (isEmulator) { files.push(FUNCTIONS_EMULATOR_DOTENV); }   // ".env.local"
  ```
  y `loadUserEnvs` los fusiona en ese orden con `envs = { ...envs, ...parseStrict(data) }`: **el último gana**.
  Orden efectivo en el emulador: `.env` < `.env.<projectId>` < `.env.<alias>` < `.env.local`.
  `.env.<projectId>` y `.env.<alias>` no pueden coexistir (lanza error).
- El emulador pasa `isEmulator: true` y `projectId: this.args.projectId` (el proyecto activo o `--project`)
  — `src/emulator/functionsEmulator.ts` (`getUserEnvs` y `discoverTriggers`),
  https://raw.githubusercontent.com/firebase/firebase-tools/master/src/emulator/functionsEmulator.ts (2026-10-07).
  **Por tanto: con proyecto activo `kcalcula-ia-dev`, el emulador SÍ carga `.env.kcalcula-ia-dev`, y
  `.env.local` gana sobre él.**
- **La línea de comandos NO gana sobre los `.env`.** En `startNode` el proceso de la función se lanza con:
  ```
  env: {
    node: backend.bin,
    METADATA_SERVER_DETECTION: "none",
    ...process.env,
    ...envs,          // getRuntimeEnvs(): incluye las variables de los .env
    PORT: socketPath,
  },
  ```
  `envs` se esparce después de `process.env`, así que si un `.env` cargado define `AI_PROVIDER`, ese
  valor sobrescribe `AI_PROVIDER=ollama` puesto en el shell. La variable del shell solo llega a la
  función si ningún `.env` cargado la define — mismo archivo (2026-10-07).
- `defineString` en el emulador: `resolveParams` toma el valor de los `.env` cargados (`userEnvs`); si no
  está, usa el `default` o pregunta de forma interactiva. **`process.env` no se consulta** —
  https://raw.githubusercontent.com/firebase/firebase-tools/master/src/deploy/functions/params.ts (2026-10-07).
  Si el valor se pide por consola, el emulador lo escribe en `.env.local` (`writeResolvedParams` →
  `writeUserEnvs`, que en el emulador escribe en `.env.local`) —
  https://raw.githubusercontent.com/firebase/firebase-tools/master/src/functions/env.ts (2026-10-07).

### 3. Cuenta de servicio y permisos (R3)
- "1st gen functions use the Google App Engine default service account [...], **2nd gen functions use the
  Compute Engine default service account**" — https://firebase.google.com/docs/functions/2nd-gen-upgrade (2026-10-07).
- "At runtime, Cloud Run functions defaults to using the Compute Engine default service account
  (`PROJECT_NUMBER-compute@developer.gserviceaccount.com`), which also has the Editor role on the project";
  la restricción de organización `iam.automaticIamGrantsForDefaultServiceAccounts` puede impedir ese
  rol Editor automático y se aplica por defecto en organizaciones creadas después del 2024-05-03 —
  https://docs.cloud.google.com/functions/docs/concepts/iam (2026-10-07).
- Se puede cambiar la cuenta por función (`serviceAccount`) o global (`setGlobalOptions`) —
  https://firebase.google.com/docs/reference/functions/firebase-functions.runtimeoptions (2026-10-07, vía fragmento de búsqueda).
- Para hacer peticiones de prompt se necesita el permiso `aiplatform.endpoints.predict`, incluido en
  `roles/aiplatform.user` — https://docs.cloud.google.com/vertex-ai/docs/general/access-control y
  https://docs.cloud.google.com/vertex-ai/generative-ai/docs/maas/grant-access-open-models (2026-10-07, vía fragmento de búsqueda).
- Tutorial oficial de llamar a Gemini en Vertex desde una cuenta de servicio:
  `gcloud services enable aiplatform.googleapis.com ...` y
  `gcloud projects add-iam-policy-binding PROJECT_ID --member="serviceAccount:...@PROJECT_ID.iam.gserviceaccount.com" --role=roles/aiplatform.user`;
  "This role allows access to most Vertex AI capabilities" —
  https://docs.cloud.google.com/workflows/docs/tutorials/use-vertex-ai-models (2026-10-07).

## NO CONFIRMADO / CONTRADICTORIO
- **Host del endpoint de `cacheConfig`:** la guía usa `us-central1-aiplatform.googleapis.com`; la referencia
  REST usa `aiplatform.googleapis.com`. Ambos apuntan al recurso de proyecto `projects/PROJECT_ID/cacheConfig`
  y la guía dice que aplica a todas las regiones, pero no se verificó que el host global responda igual.
  Usar el de la guía es lo más seguro.
- **Nombre exacto del permiso IAM** de `getCacheConfig`/`updateCacheConfig` (p. ej. `aiplatform.cacheConfigs.*`):
  no se pudo leer en la referencia. Solo está confirmado que `roles/aiplatform.admin` basta. No se sabe si
  la lectura (GET) funciona con un rol menor.
- **Token:** la guía usa `gcloud auth application-default print-access-token`. Con
  `gcloud auth print-access-token` (credenciales de usuario de gcloud) debería funcionar igual para un
  usuario con el rol, pero no está en la página; no verificado.
- **Durable Caching (cambio de 2026-10-15)** — solo fuentes SECUNDARIAS: un PR público
  (https://github.com/SCCSSAR/SAR_dispatch_flow/pull/67), un issue
  (https://github.com/uriva/ai-utils/issues/4) y un hilo del foro de Google AI Developers
  (https://discuss.ai.google.dev/t/does-project-level-cacheconfig-ephemeral-apply-to-the-gemini-developer-api-or-vertex-ai-only/187073),
  todos consultados el 2026-10-07. Dicen que desde el 2026-10-15 la caché implícita "durable" (en disco,
  hasta 24 h) se activa por defecto para Gemini 3.x Flash/Pro; que Google sugirió
  `retentionConfig: {retentionType: EPHEMERAL}` pero ese campo devolvía 400 ("Unknown name") en v1/v1beta1;
  y que `disableCache: true` sí se aplicó. No se encontró el anuncio oficial ni la doc oficial del campo
  `retentionConfig`. Según esas fuentes **no afecta a `gemini-2.5-flash`**, pero no está confirmado si
  `disableCache: true` también desactiva la caché durable.
- No se confirmó si la retención cero exige además otras medidas (registro de abuso, grounding, etc.):
  existe la página https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/abuse-monitoring
  pero no se pudo leer. El registro de abuso está fuera del alcance de SPEC-029.
- **OQ3:** la precedencia `.env` sobre el shell sale del código de `master` el 2026-10-07, no de la
  documentación; puede variar entre versiones de `firebase-tools`. No se comprobó la versión instalada.
- **R3:** si `kcalcula-ia-dev` está en una organización con `iam.automaticIamGrantsForDefaultServiceAccounts`
  (o es un proyecto personal sin organización) no se sabe; por eso hay que dar el rol explícitamente
  y no contar con el Editor automático. No se confirmó en docs si `aiplatform.user` cubre también
  `countTokens` u otras llamadas que el SDK `@google/genai` pudiera hacer (el adaptador solo usa
  `generateContent`, según la SPEC).

## Implicaciones para el proyecto
- **OQ2:** el comando es un `PATCH` sobre `projects/kcalcula-ia-dev/cacheConfig`; se hace una vez y vale
  para todas las regiones. Quien lo ejecute necesita `roles/aiplatform.admin` (la usuaria como Owner del
  proyecto debería tenerlo implícito; no verificado). Es una acción con `curl` + token: pide confirmación humana.
- **OQ3 / R4 — conflicto con la SPEC:** R4 dice que, si `.env.local` define `AI_PROVIDER=fake`, "los
  comandos de CLAUDE.md siguen valiendo, con la variable explícita en la línea de comandos". **Según el
  código, no es así:** `.env.local` sobrescribe `AI_PROVIDER=ollama` y `AI_PROVIDER=vertex` del shell, así
  que el emulador quedaría siempre en `fake`. Y sin `.env.local`, con proyecto activo `kcalcula-ia-dev`, el
  emulador carga `.env.kcalcula-ia-dev` (`AI_PROVIDER=vertex`) y también le gana al shell, con lo que AC5
  (emulador sin variables → `fake`) fallaría y el emulador llamaría a Vertex con costo.
- `VERTEX_PROJECT_ID` (`defineString`) en el emulador nunca se lee del shell: viene de los `.env` o del
  `default`, o se pregunta y se escribe en `.env.local`.
- AC4 (evals) corre fuera del emulador con `process.env` normal: no le afecta esta precedencia.
- **R3:** sin `serviceAccount` en el código, la cuenta es `PROJECT_NUMBER-compute@developer.gserviceaccount.com`.
  `roles/aiplatform.user` incluye `aiplatform.endpoints.predict`, que es el permiso para hacer prompts.

## Comandos (para que los ejecute la usuaria; ninguno se ejecutó)
```
# Número del proyecto (lectura)
gcloud projects describe kcalcula-ia-dev --format="value(projectNumber)"

# ¿API de Vertex habilitada? (lectura; si imprime aiplatform.googleapis.com, lo está)
gcloud services list --enabled --project=kcalcula-ia-dev \
  --filter="config.name=aiplatform.googleapis.com" --format="value(config.name)"
# Habilitarla si falta
gcloud services enable aiplatform.googleapis.com --project=kcalcula-ia-dev

# ¿Ya tiene la cuenta de Compute el rol? (lectura; vacío = no lo tiene)
gcloud projects get-iam-policy kcalcula-ia-dev \
  --flatten="bindings[].members" \
  --filter="bindings.role=roles/aiplatform.user AND bindings.members:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --format="value(bindings.role)"

# Dar el rol
gcloud projects add-iam-policy-binding kcalcula-ia-dev \
  --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# Caché de Vertex: leer estado
curl -X GET \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://us-central1-aiplatform.googleapis.com/v1/projects/kcalcula-ia-dev/cacheConfig

# Caché de Vertex: desactivar
curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://us-central1-aiplatform.googleapis.com/v1/projects/kcalcula-ia-dev/cacheConfig \
  -d '{"name": "projects/kcalcula-ia-dev/cacheConfig", "disableCache": true}'
```
(La guía oficial usa `gcloud auth application-default print-access-token`; si el de usuario falla con
403/401, probar ese. Los filtros de `gcloud ... --filter` siguen la sintaxis documentada de gcloud,
pero estos comandos concretos no se probaron.)

## Recomendación (no vinculante)
- OQ2: aplicar el `PATCH` y confirmar con el `GET` que aparece `"disableCache": true`; guardar la
  evidencia en la SPEC. Volver a revisar si se pasa a un modelo Gemini 3.x (caché durable, solo fuentes
  secundarias por ahora).
- OQ3/R4: corregir R4 en la SPEC antes de implementarla. Opciones a evaluar por el equipo (no decididas):
  (a) no poner `AI_PROVIDER` en ningún `.env` que cargue el emulador y pasar la configuración del despliegue
  por otra vía; (b) lanzar el emulador con un proyecto distinto (`--project demo-...` u otro id) para que no
  cargue `.env.kcalcula-ia-dev`; (c) aceptar `.env.local` con `fake` y cambiar los comandos de CLAUDE.md
  para Ollama/Vertex (p. ej. editar `.env.local` en vez de la línea de comandos). Conviene comprobarlo con
  una prueba manual en la versión instalada de `firebase-tools`.
- R3: dar `roles/aiplatform.user` a la cuenta de Compute y no depender del rol Editor automático; a futuro,
  considerar una cuenta de servicio dedicada para `parseMeal`/`extractLabel`.

## Resolución (2026-10-07, SPEC-029)
El conflicto de OQ3/R4 se resolvió sin `AI_PROVIDER` en `.env.kcalcula-ia-dev`: el archivo usa
`DEPLOYED_AI_PROVIDER=vertex` y el código lo ignora en el emulador (`functions/src/ai/provider_name.ts`).
Lo que esta nota dice sobre `.env.kcalcula-ia-dev` con `AI_PROVIDER=vertex` describe el problema, no
la configuración final. La caché se desactivó con el PATCH de OQ2 y la lectura posterior dio
`"disableCache": true`.
