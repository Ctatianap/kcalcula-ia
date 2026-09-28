# SPEC-004: Foto de tabla nutricional

## Status
Draft
Path: Strict (toca `nutrition_core`, un esquema/prompt de IA nuevo y datos que salen del
dispositivo — skill `ai-pipeline`)

## Objective
Que el usuario pueda fotografiar la tabla nutricional impresa de un producto, confirmar (o
corregir) los valores transcritos, indicar cuánto comió, y que eso entre al mismo flujo de
revisión/cálculo/registro que ya existe para texto y voz — quedando guardado como un "producto
personal" reutilizable sin repetir la foto la próxima vez.

## Context
Backlog T-005, depende de T-002 (SPEC-001, `Status: Done`... revisar: en `docs/backlog.md` T-002
referencia SPEC-001 en `Status: Review`, AC11 sigue pendiente del proyecto Vertex real — no
bloquea esta SPEC). Aplica D-de-visión de
`docs/decisions/ADR-001-decisiones-iniciales.md` (LLM de visión en vez de OCR local, porque el
OCR pierde la estructura de la tabla). El flujo ya está descrito en
`docs/architecture.md#flujo-etiqueta-nutricional-spec-posterior`: esta SPEC es esa "SPEC
posterior".

**Verificado antes de escribir esta SPEC** (para no dejarlo como duda innecesaria):
`ollama show gemma4:e4b` (modelo local usado para desarrollo del MVP, ADR-002) confirma que el
modelo sí tiene la capacidad `vision` — el mismo modelo que ya se usa para `parseMeal` en local
puede procesar la foto de la etiqueta sin costo, igual que Vertex (PV-02 ya confirmó que
`gemini-2.5-flash` es multimodal). No hace falta ningún modelo nuevo ni gasto adicional para
desarrollar y probar `extractLabel` durante el MVP.

## User Story
Como persona que compra un producto empacado, quiero tomarle una foto a la tabla nutricional en
vez de escribir cada valor a mano, para registrar productos comerciales rápido y con precisión —
y que si vuelvo a comer lo mismo, no tenga que repetir la foto.

## Requirements
- R1. Nueva vía de entrada en `CaptureScreen`: botón de "foto de etiqueta" (junto a texto y voz,
  no los reemplaza). Abre cámara o selector de galería.
- R2. La imagen se envía al callable `extractLabel(imagen)` → `label_extraction.v1`: nombre del
  producto si aparece impreso, porción declarada (cantidad + unidad, tal como está impresa),
  valores por porción y/o por 100 g/ml si la etiqueta los trae (muchas etiquetas colombianas dan
  ambos), y `unreadable_fields` (campos impresos pero ilegibles/borrosos en la foto). La IA **solo
  transcribe** lo que está impreso; nunca completa un campo que no pudo leer ni infiere un valor
  (invariante 1 y 2) — lo que no se puede leer va a `unreadable_fields`, no se adivina.
- R3. `nutrition_core` valida los valores transcritos antes de mostrarlos como "correctos": Atwater
  ±20 % (mismo criterio que el catálogo) sobre el conjunto por 100 g/ml (derivado de por-porción si
  la etiqueta no trae por-100 directamente) y porción > 0. Si falla Atwater o hay
  `unreadable_fields`, se marca visualmente y se exige que el usuario corrija o confirme
  explícitamente antes de continuar — nunca se usa un valor no confirmado (invariante 2).
- R4. Pantalla de confirmación: todos los valores transcritos son editables. El usuario puede
  corregir cualquier campo (incluidos los que vinieron marcados como no leídos) antes de aceptar.
- R5. El usuario indica la cantidad que comió, en gramos o mililitros explícitos (ej. "comí 45
  g"). Si no da una cantidad explícita en g/ml, se usa la porción declarada en la etiqueta como
  cantidad por defecto (editable), igual que ya hace `default_portion` para el catálogo.
- R6. Cálculo: se reutiliza `calculateItemNutrients`/`resolveGrams` de `nutrition_core` tratando el
  producto personal confirmado como un `FoodCatalogEntry` equivalente (valores por 100 g/ml,
  con una única `portion` = la porción impresa). Cuando la cantidad consumida viene en g/ml
  explícitos para un producto de este origen, la base de cálculo es `QuantityBasis.label` (ya
  existe en el enum y en `confidence.dart`, con `hasLabelGramsOrMl` → **Alta precisión**) — hoy
  `resolveGrams` no distingue esto de `explicit_weight`; ver Technical Constraints.
- R7. El producto confirmado se guarda como **producto personal** reutilizable
  (`personal_products` en `user.db`, ver Components) con su `source_ref` de auditoría ("etiqueta
  transcrita y confirmada por el usuario, `<fecha>`" — invariante 8 ya contempla "etiqueta
  confirmada" como fuente válida). Se puede volver a usar sin repetir la foto (ver R7 en
  Acceptance Criteria y la Open Question sobre cómo se busca).
- R8. Una vez resuelto el ítem (gramos + nutrientes + confianza), entra a la misma
  `ReviewController`/pantalla de revisión que ya existe — no se duplica lógica de cálculo ni de
  registro.
- R9. Errores en español, sin trazas técnicas: sin permiso de cámara/galería, foto ilegible (todos
  los campos en `unreadable_fields`), error del proveedor de IA, sin red/timeout — mismo patrón que
  `parseMeal` (fallback: queda la opción de escribir el producto a mano por texto).
- R10. Antes de enviar la imagen: se redimensiona/comprime en el dispositivo (propuesto: máx. 1600
  px en el lado más largo, JPEG calidad ~85 %) para acotar costo y latencia; si el archivo
  seleccionado no es una imagen válida, error claro sin enviarlo.
- R11. `extractLabel` no persiste ni registra la imagen ni su contenido en ningún log — solo
  metadatos (latencia, tokens, versión de prompt, validez de esquema, código de error), igual que
  `parseMeal` (invariante 5).
- R12. `docs/privacy.md` (fila "Foto de etiqueta", hoy placeholder) se completa con el flujo real:
  la imagen sale del dispositivo hacia el proveedor de IA configurado (Ollama local en desarrollo
  = no sale del dispositivo; Vertex AI en producción = sí sale), nunca se guarda.

## Acceptance Criteria
- AC1. Con permiso concedido, tomar/seleccionar una foto muestra un indicador de "analizando" y
  luego una pantalla de confirmación con los valores transcritos `[widget]`.
- AC2. Con un resultado simulado (`fake` provider) de una etiqueta "30 g = 140 kcal" con
  proteína/carbohidratos/grasa dentro de ±20 % Atwater: los valores se muestran sin advertencia,
  editables `[unit+widget]`.
- AC3. Con un resultado simulado fuera de ±20 % Atwater: aparece una advertencia clara y no se
  puede continuar sin corregir o confirmar explícitamente pese a la advertencia `[unit]`.
- AC4. Con `unreadable_fields` no vacío (ej. grasa ilegible): ese campo aparece vacío/marcado para
  completarse a mano, nunca con un valor inventado `[widget]`.
- AC5. Con el producto "30 g = 140 kcal" confirmado y el usuario indicando "comí 45 g": el
  resultado es 210 kcal (140 × 45/30) con confianza **Alta precisión** `[unit]` — coincide con el
  criterio de aceptación del backlog.
- AC6. El producto queda guardado en `personal_products`; en una comida posterior aparece
  disponible para reutilizarse sin repetir la foto (mecanismo exacto: ver Open Questions)
  `[integration]`.
- AC7. Sin permiso de cámara: mensaje "Necesito permiso de la cámara para esto. Puedes escribirlo
  en su lugar." y el campo de texto sigue disponible `[widget]`.
- AC8. Error del proveedor de IA o sin red al analizar la foto: mensaje en español sin traza
  técnica, se puede reintentar `[unit]`.
- AC9. `label_extraction.v1` (zod `.strictObject`) no tiene ningún campo de confianza ni de "valor
  sugerido/calculado"; solo transcripción y `unreadable_fields` `[unit]`.
- AC10. Una imagen de prueba por encima del límite propuesto se redimensiona antes de enviarse (se
  verifica el tamaño resultante) `[unit o manual]`.
- AC11. `docs/privacy.md` refleja el flujo real (qué sale, hacia dónde, con qué proveedor) sin
  inventar el comportamiento de producción antes de tenerlo verificado `[manual]`.
- AC12. Eval con etiquetas reales contra el proveedor real (Vertex u Ollama local): **pendiente
  aceptado**, igual que AC11 de SPEC-001/AC8 de SPEC-002 — se ejecuta cuando exista un pequeño
  set de fotos reales (formal, en T-006) o al menos una prueba manual con 3-5 fotos propias antes
  de mover esta SPEC a `Done` `[manual, pendiente aceptado si no alcanza a hacerse ahora]`.

## Technical Constraints
- Invariante 1: `label_extraction.v1` no puede tener campos de nutrientes "calculados" por la IA —
  solo transcripción de lo impreso. Invariante 2: `nutrition_core` valida (Atwater, porción > 0) y
  el usuario confirma antes de usar. Invariante 3: el cálculo sigue viviendo solo en
  `nutrition_core`. Invariante 4: la confianza la calculan reglas existentes
  (`confidence.dart`), no la IA. Invariante 5: `extractLabel` sin estado, sin loggear contenido.
  Invariante 6/12: la foto sale del dispositivo → Strict + `docs/privacy.md`. Invariante 8: el
  producto personal se guarda con `source_ref` de auditoría (ver R7); "etiqueta confirmada" es una
  fuente válida explícitamente listada en `CLAUDE.md`.
- `resolveGrams` (`packages/nutrition_core`) hoy infiere la base de cálculo solo por la forma del
  `QuantityInput` (unidad `g`/`ml` → siempre `explicit_weight`); no distingue si el alimento viene
  del catálogo o de un producto personal. Para que "cantidad explícita + producto de etiqueta" dé
  `QuantityBasis.label` (Alta precisión, como ya exige `docs/architecture.md`) hace falta un
  parámetro nuevo (propuesto: `isLabelProduct: bool = false`) — cambio pequeño y con tests, no
  reinterpreta el resto de la función.
- Nueva función pública en `nutrition_core` para el chequeo Atwater ±20 % de un producto personal.
  Es una duplicación deliberada (2-3 líneas) de la misma fórmula que ya existe en
  `data/build_catalog/lib/validators.dart`: no se comparte código entre esos dos paquetes porque
  `nutrition_core` debe seguir sin dependencias de Flutter ni de otros paquetes del repo (regla ya
  vigente), y acoplar dos paquetes por una fórmula de 3 líneas sería una abstracción prematura.
- `label_extraction.v1`: mismo patrón que `parsed_meal.v1` (`zod.strictObject`,
  `additionalProperties: false`, JSON Schema espejo con `anyOf`+`null` para opcionales).
- Paquete Flutter para cámara/galería: verificar versión estable actual al implementar (no se fija
  aquí). Permiso de cámara vía `permission_handler` (ya es dependencia del proyecto, se reutiliza
  el mismo patrón que `speech_to_text`/micrófono de SPEC-002).

## Components / Files Affected
`functions/src/ai/schemas.ts` (nuevo `label_extraction.v1` + JSON Schema espejo) ·
`functions/src/ai/provider.ts` (`AiProvider` gana `extractLabel`) ·
`functions/src/ai/{fake,vertex,ollama}.ts` (implementan `extractLabel`) ·
`functions/src/ai/prompts/extract_label.v1.md` (nuevo, inmutable una vez usado) ·
`functions/src/index.ts` (nuevo callable `extractLabel`, límite de tamaño de imagen, 1 reintento
igual que `parseMeal`) · `packages/nutrition_core/lib/src/quantity_resolution.dart`
(`isLabelProduct`) · nueva función de validación Atwater en `nutrition_core` ·
`app/lib/infra/ai_client/*` (método `extractLabel`) · `app/lib/infra/storage/*` (tabla
`personal_products`, DAO) · `app/lib/features/capture/*` (botón de foto, flujo de cámara/galería,
pantalla de confirmación de etiqueta) · `app/lib/features/review/*` (cantidad consumida en g/ml
para productos personales) · `app/android/.../AndroidManifest.xml` +
`app/ios/.../Info.plist` (permiso de cámara/galería) · `app/pubspec.yaml` (paquete de
cámara/imagen) · `docs/privacy.md` (fila "Foto de etiqueta").

## Dependencies
T-002 (`CaptureScreen`/`CaptureController`/`ReviewController` ya existen, no cambian su contrato
público salvo lo mínimo de R6).

## Edge Cases
- Foto borrosa/mal iluminada: la mayoría o todos los campos en `unreadable_fields` → el usuario
  completa a mano; nunca se bloquea sin salida (fallback a texto).
- Etiqueta que solo da valores por porción, no por 100 g (común en Colombia): `nutrition_core`
  deriva el por-100 desde porción + cantidad declarada para poder validar Atwater y calcular.
- Etiqueta que da valores por 100 g Y por porción con una inconsistencia entre ambos (redondeos de
  fábrica): se usa el valor por 100 g como base de cálculo (más preciso), se muestra el de porción
  solo como referencia.
- Producto sin tabla nutricional visible en la foto (ej. se fotografió el frente del empaque):
  `unreadable_fields` completo, mismo fallback que foto borrosa.
- Usuario cancela la cámara o no selecciona ninguna foto: vuelve al estado inicial de captura, sin
  error.

## Security & Privacy
- Sale del dispositivo: la foto de la etiqueta, hacia el proveedor de IA configurado. En
  desarrollo (Ollama local, `AI_PROVIDER=ollama`) **no sale del dispositivo** (se procesa en la
  máquina local). En producción (Vertex AI) sí sale hacia los servidores de Google Cloud, con la
  misma política de retención/entrenamiento ya documentada para `parseMeal` en `docs/privacy.md`.
- El backend nunca guarda la imagen ni su contenido (invariante 5); solo metadatos.
- El producto personal confirmado (nombre + valores) se guarda únicamente en `user.db`, en el
  dispositivo — igual que cualquier otro dato del usuario (invariante: sin cuentas, todo local).

## Tests Required
- Unit: `nutrition_core` — Atwater de producto personal (dentro/fuera de ±20 %), `resolveGrams`
  con `isLabelProduct: true` (Alta precisión con g/ml explícitos, comportamiento sin cambios para
  el resto de bases). `functions/src/ai/schemas.test.ts` — `label_extraction.v1` (válido, inválido,
  `additionalProperties` rechazado). `functions/src/ai/fake.test.ts` — fixtures de `extractLabel`
  (dentro y fuera de Atwater, con `unreadable_fields`).
- Widget: pantalla de confirmación de etiqueta (edición de campos, advertencia Atwater, campos no
  leídos), botón de foto en `CaptureScreen`, fallback sin permiso.
- Integration: flujo completo foto simulada → confirmación → "comí 45 g" → revisión → registro →
  210 kcal / Alta precisión (AC5, mismo patrón que `capture_to_review_flow_test.dart`). Reutilizar
  un producto personal ya guardado en una comida nueva (AC6).
- Manual: AC10 (tamaño real de imagen tras redimensionar), AC11 (`docs/privacy.md`), AC12 (fotos
  reales).

## Out of Scope
Recorte manual de la foto, múltiples etiquetas en una sola foto, lectura de código de barras o
integración con bases de datos de productos comerciales (Open Food Facts u otras), fusionar
productos personales duplicados, edición de un producto personal ya creado desde fuera del flujo
de captura, empaques en otro idioma que español, evals formales con dataset (T-006).

## Open Questions
- **Cómo se reutiliza un producto personal (R7/AC6)**: propongo una lista simple "Mis productos"
  buscable por nombre, accesible desde `CaptureScreen` (botón junto a texto/voz/foto), separada de
  la búsqueda por `food_query` del catálogo — evita mezclar dos fuentes de datos (`catalog.db`
  solo-lectura vs. `user.db` de escritura) en una sola búsqueda FTS. Alternativa: integrar
  productos personales directamente en la resolución de `food_query` de texto/voz (para que
  "yogur griego marca X" lo encuentre sin abrir una lista aparte) — más natural para el usuario
  pero cambia `CatalogRepository`/`ReviewController` para consultar dos bases de datos distintas
  en el mismo paso, más alcance. ¿Cuál de las dos para esta SPEC?
- Paquete Flutter exacto para cámara/galería (se verifica su versión estable al implementar, no se
  fija aquí — mismo patrón que `speech_to_text` en SPEC-002).
- Límite exacto de tamaño/resolución de imagen (R10 propone 1600 px / JPEG 85 % como default
  razonable): ¿de acuerdo, o el usuario prefiere otro valor?

## Definition of Done
- AC1–AC12 con evidencia enlazada en esta SPEC (AC12 puede quedar "pendiente aceptado").
- `dart analyze`/`flutter analyze`/`tsc` sin warnings y tests verdes en los paquetes tocados.
- Reviewer: `PASS` enlazado.
- `docs/privacy.md` actualizado con el resultado real (no supuesto).

## Change Log
- 2026-09-27: creación, a partir de T-005 de `docs/backlog.md`.

## Review
Informe del reviewer:
