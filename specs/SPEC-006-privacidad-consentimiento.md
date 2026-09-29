# SPEC-006: Privacidad y consentimiento

## Status
Review
Path: Strict (consentimiento y control de datos que salen del dispositivo — CLAUDE.md)

## Objective
Antes de que la app use IA por primera vez, el usuario ve y acepta explícitamente qué se envía y a
quién, y confirma ser mayor de edad. En cualquier momento puede borrar todos sus datos, exportarlos,
y leer el borrador de política de privacidad completo.

## Context
Backlog T-007, depende de T-002 (SPEC-001, `Done`). `docs/privacy.md` ya existe como borrador
técnico interno ("Requiere revisión legal antes de publicar") con el inventario de datos y los
controles previstos, pero ninguno de esos controles existe todavía en la app: no hay pantalla de
onboarding, no hay forma de borrar o exportar datos, y el texto de política es solo la tabla técnica
de `docs/privacy.md`, no un texto pensado para que lo lea el usuario.

`docs/research/POR-VERIFICAR.md` tenía abierto **PV-07** (Ley 1581 de 2012 aplicada a esta app,
bloquea T-007 "revisión legal humana"); el subagente `researcher` lo investigó en paralelo a este
Draft y dejó la nota
[`docs/research/2026-09-28-ley-1581-consentimiento.md`](../docs/research/2026-09-28-ley-1581-consentimiento.md)
(PV-07 ahora "resuelto parcialmente" — quedan 3 puntos sin confirmar, ver esa nota). Sus hallazgos
(fuentes primarias: Ley 1581/2012, Decreto 1377/2013, doctrina de la SIC) informan R2/R6 y las Open
Questions de abajo, pero **no sustituyen** la revisión legal humana que ya pide `docs/privacy.md` y
el propio backlog.

## User Story
Como usuaria en Colombia que va a registrar su alimentación con esta app, quiero entender qué pasa
con lo que escribo o fotografío antes de usarlo por primera vez, poder borrar o exportar mis datos
cuando quiera, y confiar en que nada sale de mi teléfono sin que yo lo haya aceptado.

## Requirements
- R1: Al primer lanzamiento (sin consentimiento registrado localmente), antes de cualquier otra
  pantalla se muestra un onboarding que explica en español sencillo qué se envía a un proveedor de
  IA, para qué, y que nunca calcula valores nutricionales; incluye un enlace para expandir/leer el
  borrador completo de política de privacidad (R6).
- R2: El onboarding tiene dos casillas independientes, ninguna premarcada, ambas obligatorias para
  continuar: (a) "Confirmo que soy mayor de 18 años" y (b) consentimiento explícito para el
  procesamiento de lo que el usuario escriba/fotografíe. Por PV-07 (Ley 1581 Art. 6-7, Decreto 1377
  Art. 6-7), el texto de (b) debe nombrar explícitamente: que se trata como dato sensible de
  salud/nutrición, qué se envía (lo escrito o la foto de la etiqueta), a quién (Vertex AI/Google,
  fuera de Colombia) y para qué (estructurar la entrada, nunca calcular valores nutricionales). El
  botón "Continuar" está deshabilitado hasta marcar ambas.
- R3: Al aceptar, se guarda localmente (Drift, `user.db`) que el consentimiento y la confirmación de
  edad fueron dados, con fecha/hora y la versión del texto de política aceptado. En lanzamientos
  posteriores la app no vuelve a mostrar el onboarding.
- R4: Existe una pantalla de Ajustes, accesible desde la pantalla principal, con: "Borrar todos mis
  datos", "Exportar mis datos" y un enlace a "Ver política de privacidad completa".
- R5: "Borrar todos mis datos" pide confirmación explícita (diálogo con advertencia de que no se
  puede deshacer) y, al confirmar, elimina todo el contenido de `meals`, `meal_items` y
  `personal_products` en `user.db`.
- R6: El borrador de política de privacidad (texto en español es-CO, marcado explícitamente como
  borrador pendiente de revisión legal — igual que ya hace `docs/privacy.md`) describe: qué datos se
  procesan y con qué proveedor de IA, que no hay cuentas ni identificadores de usuario en el backend,
  dónde viven los datos, cómo borrarlos/exportarlos, que se tratan como dato sensible de salud por
  criterio conservador, y (gap detectado en PV-07) un canal de contacto (correo) para consultas o
  ejercicio de derechos ARCO, aunque no exista cuenta ni backend con estado.
- R7: "Exportar mis datos" genera un archivo JSON local con la instantánea completa de comidas,
  ítems y productos personales del usuario (estructura en Technical Constraints) y lo entrega
  mediante el mecanismo nativo de compartir del sistema operativo — la app nunca decide ni transmite
  el archivo por su cuenta; el destino final lo elige el usuario en ese momento (guardarlo, enviarlo
  por correo, etc.).
- R8: Ajustes tiene una acción "Revocar consentimiento", separada de "Borrar todos mis datos" (Ley
  1581 Art. 8: derecho a revocar la autorización en cualquier momento). Pide confirmación explícita
  y, al confirmar, limpia el `ConsentRecord` (sin borrar `meals`/`meal_items`/`personal_products`) y
  navega inmediatamente a `OnboardingScreen` — el usuario debe volver a aceptar para seguir usando la
  app, pero sus datos ya registrados no se pierden.

## Acceptance Criteria
- AC1: Primer lanzamiento (sin fila de consentimiento en `user.db`) → se muestra `OnboardingScreen`
  antes que `DiaryScreen` `[integration]`
- AC2: En `OnboardingScreen`, con solo una de las dos casillas marcada → botón "Continuar"
  deshabilitado; al desmarcar una casilla ya marcada, vuelve a deshabilitarse `[widget]`
- AC3: Marcar ambas casillas y pulsar "Continuar" → se persiste el consentimiento (fila con
  `ageConfirmed=true`, `consentGiven=true`, marca de tiempo, versión de política) y la app navega a
  `DiaryScreen` `[integration]`
- AC4: Reabrir la app (nueva instancia de `AppDatabase` sobre el mismo archivo, consentimiento ya
  guardado) → entra directo a `DiaryScreen`, sin mostrar el onboarding `[integration]`
- AC5: Desde Ajustes, "Borrar todos mis datos" → aparece diálogo de confirmación; cancelarlo no
  borra nada `[widget]`
- AC6: Desde Ajustes, "Borrar todos mis datos" → confirmar dejas las tablas `meals`, `meal_items` y
  `personal_products` vacías; un diario con comidas de días distintos queda igual de vacío `[integration]`
- AC7: Desde Ajustes, "Exportar mis datos" con datos existentes → genera un JSON válido con la
  estructura documentada (comidas, ítems, productos personales) y se lo pasa al servicio de
  compartir con la ruta del archivo `[widget, con SharingService fake]`
- AC8: "Exportar mis datos" con el diario vacío → genera JSON válido con arreglos vacíos, sin error
  `[unit]`
- AC9: El JSON de exportación no incluye ningún identificador de red, token de App Check, ni
  metadatos técnicos del backend — solo los datos del usuario que ya vivían en `user.db` `[unit]`
- AC10: Ajustes tiene un enlace "Ver política de privacidad completa" que muestra el texto cargado
  desde el asset de política `[widget]`
- AC11: El borrador de política (texto real, no placeholder) cubre los puntos de R6 (incluido el
  canal de contacto) y está marcado como pendiente de revisión legal `[manual]`
- AC12: El texto de la casilla de consentimiento (R2b) nombra explícitamente el dato de salud, qué
  se envía, a quién (Vertex AI/Google, fuera de Colombia) y para qué, sin estar premarcada `[manual,
  revisión de texto contra PV-07]`
- AC13: Desde Ajustes, "Revocar consentimiento" → aparece diálogo de confirmación; cancelarlo no
  cambia nada `[widget]`
- AC14: Desde Ajustes, "Revocar consentimiento" → confirmar limpia el `ConsentRecord` guardado, la
  app navega de inmediato a `OnboardingScreen`, y `meals`/`meal_items`/`personal_products` quedan
  intactos (a diferencia de AC6) `[integration]`

## Technical Constraints
- Invariantes de CLAUDE.md que aplican: 5 (backend sin estado — no cambia, esta SPEC es 100 % local),
  6 (nada nuevo sale del dispositivo sin Strict Path + `docs/privacy.md` actualizado — el export es
  la única superficie nueva y es explícitamente iniciada por el usuario, no automática).
- Nueva tabla Drift en `user.db` (bump `schemaVersion` a 3, `onUpgrade` crea la tabla, no toca las
  existentes — mismo patrón que SPEC-004):
  ```
  ConsentRecord: id (fija, una sola fila), ageConfirmed (bool), consentGiven (bool),
  policyVersion (text), consentedAt (datetime nullable)
  ```
- JSON de exportación (borrador de forma, a validar en Review):
  ```json
  {
    "exportedAt": "2026-09-28T00:00:00.000Z",
    "meals": [
      {"id": 1, "eatenAt": "...", "mealType": "almuerzo", "confidence": "Buena estimación",
       "items": [{"mention": "...", "nameSnapshot": "...", "grams": 150.0,
                  "energyKcal": 250.0, "proteinG": 20.0, "carbsG": 10.0, "fatG": 12.0,
                  "confidence": "...", "sourceRef": "..."}]}
    ],
    "personalProducts": [
      {"id": 1, "nameEs": "...", "energyKcal100": 460.0, "servingGrams": 20.0, "sourceRef": "..."}
    ]
  }
  ```
- `share_plus: ^13.3.0` (verificado en pub.dev, última estable al momento de escribir) para el
  mecanismo de compartir — nueva dependencia directa.
- Texto de política como asset (`assets/legal/privacy_policy_draft_es.md`), no hardcodeado en Dart,
  para poder actualizarlo sin recompilar lógica.

## Components / Files Affected
- `app/lib/features/onboarding/` (nuevo): `onboarding_screen.dart`, `onboarding_controller.dart`
- `app/lib/features/settings/` (nuevo): `settings_screen.dart`, `settings_controller.dart`
- `app/lib/infra/sharing/sharing_service.dart` (nuevo): interfaz + implementación sobre `share_plus`
  (mismo patrón que `ImagePickerService`/`SpeechRecognizer`: detrás de una interfaz por usar canales
  de plataforma)
- `app/lib/infra/storage/app_database.dart`: tabla `ConsentRecord`, `schemaVersion` 2 → 3
- `app/lib/infra/storage/storage_repository.dart`: `getConsentState()`, `saveConsent(...)`,
  `revokeConsent()`, `deleteAllUserData()`, `exportUserData()`
- `app/lib/app.dart`, `app/lib/app_routes.dart`: gate de onboarding, rutas `onboarding`/`settings`
- `app/lib/features/diary/diary_screen.dart`: entrada a Ajustes (ícono en el `AppBar`)
- `app/assets/legal/privacy_policy_draft_es.md` (nuevo)
- `app/pubspec.yaml`: `share_plus`, asset de política
- `docs/privacy.md`: fila nueva para "exportar" en el inventario, marcar los controles ya
  implementados
- `docs/backlog.md`: T-007 → estado de esta SPEC

## Dependencies
- T-002 (SPEC-001, `Done`)

## Edge Cases
- Casillas marcadas y luego desmarcadas antes de pulsar Continuar → botón vuelve a deshabilitarse.
- "Borrar todos mis datos" con la base ya vacía → no falla, mensaje de éxito igual.
- Exportar con nombres/mentions con tildes o caracteres especiales → JSON válido en UTF-8.
- El mecanismo de compartir del SO falla o el usuario lo cancela → mensaje de error en español; no
  se pierde ningún dato existente (el archivo exportado es una copia, nunca reemplaza `user.db`).
- Usuario que ya tenía datos de una versión anterior (sin fila de `ConsentRecord`, p. ej. viene de
  SPEC-004) → conserva sus `meals`/`meal_items`/`personal_products` tras la migración, pero ve el
  onboarding la próxima vez que abra la app — el consentimiento no se asume retroactivamente.
- Revocar consentimiento con el diario lleno de comidas → los datos permanecen intactos, solo se
  vuelve a pedir el consentimiento; si el usuario vuelve a aceptar, sigue viendo su historial igual
  que antes (a diferencia de "Borrar todos mis datos").
- Revocar consentimiento y luego cerrar la app sin volver a aceptar → al reabrir, sigue mostrando el
  onboarding (mismo criterio que AC1, no es un estado distinto del "primer lanzamiento").

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? El export es la única superficie nueva, y es 100 %
  iniciada y dirigida por el usuario a través del share sheet del sistema operativo — la app arma el
  JSON localmente y se lo entrega al SO, nunca lo transmite ella misma a un servidor propio ni de
  terceros. Aun así, `docs/privacy.md` se actualiza con esta fila porque el usuario puede terminar
  compartiéndolo a un destino externo por su propia decisión.
- El archivo temporal de la foto que toma `image_picker` (SPEC-004) es un detalle del caché del
  sistema operativo, no algo que la app persista aparte de los bytes en memoria que ya procesa y
  descarta — "Borrar todos mis datos" no necesita tocarlo porque la app nunca lo guarda.
- El JSON de exportación no debe incluir tokens de App Check ni ningún metadato de red (AC9).
- Pendiente aceptado (PV-07, no bloquea esta SPEC, sí bloquea publicación real): si el tratamiento
  vía Vertex AI califica como "transmisión" a un encargado (cubierta por el consentimiento general)
  o como "transferencia internacional" que exige autorización expresa e inequívoca separada (Ley
  1581 Art. 26) depende del contrato/DPA real de Google Cloud, no evaluado. Mientras tanto, el texto
  de R2b declara explícitamente que el dato sale de Colombia hacia Google/Vertex AI, cubriendo el
  escenario más conservador sin un segundo checkbox.
- Pendiente aceptado: si el Registro Nacional de Bases de Datos (RNBD) aplica a la estructura legal
  real del proyecto (umbral de 100.000 UVT, solo confirmado por fuentes secundarias) — ver
  `docs/research/2026-09-28-ley-1581-consentimiento.md`. No es una acción técnica de esta SPEC.

## Tests Required
- Unit: `storage_repository_test.dart` (grupos "SPEC-006: consentimiento" y "SPEC-006: borrar todo y
  exportar" — `getConsentState`/`saveConsent`/`revokeConsent`/`deleteAllUserData`/`exportUserData`)
- Widget / Integration: `onboarding_screen_test.dart` (AC2, AC3, AC12), `settings_screen_test.dart`
  (AC5-AC7, AC9, AC10, AC13-AC14), `integration/onboarding_gate_flow_test.dart` (AC1, AC4 — el gate
  de `app.dart`)
- Eval: no aplica (sin cambios de prompt/esquema de IA)
- Manual: AC11 (lectura completa del texto de política contra R6)

## Out of Scope
- Verificación real de edad (solo declaración, sin documento de identidad).
- Registro Nacional de Bases de Datos (RNBD) u otro trámite regulatorio — es una acción humana, no
  técnica; se documenta si aplica pero no se automatiza.
- Traducción del borrador de política a otro idioma distinto de es-CO.
- Cambiar el consentimiento por tipo de dato (todo o nada, como hoy: si no acepta, no puede usar la
  app, dado que casi toda la app depende de IA).

## Open Questions
Ninguna abierta. Las dos preguntas de diseño de este Draft ya se resolvieron:
- ¿Basta un checkbox in-app como forma de autorización para datos sensibles? Sí — PV-07, ver R2.
- ¿Se incluye "revocar consentimiento" separado de "borrar mis datos"? Sí — el usuario lo aprobó,
  ver R8/AC13/AC14.

## Evidencia de Acceptance Criteria
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `integration/onboarding_gate_flow_test.dart`: "AC1: primer lanzamiento sin consentimiento muestra el onboarding, no el diario" |
| AC2 | ✅ | `onboarding_screen_test.dart`: "AC2: con solo una casilla marcada..." y "AC2: desmarcar una casilla ya marcada..." |
| AC3 | ✅ | `onboarding_screen_test.dart`: "AC3: marcar ambas y Continuar persiste el consentimiento y navega al diario" |
| AC4 | ✅ | `integration/onboarding_gate_flow_test.dart`: "AC4: con consentimiento ya guardado entra directo al diario..." |
| AC5 | ✅ | `settings_screen_test.dart`: "AC5: cancelar el diálogo de borrar no borra nada" |
| AC6 | ✅ | `settings_screen_test.dart`: "AC6: confirmar borra todos los datos del usuario" |
| AC7 | ✅ | `settings_screen_test.dart`: "AC7, AC9: exportar entrega un JSON válido..." |
| AC8 | ✅ | `storage_repository_test.dart`: "exportUserData con el diario vacío da arreglos vacíos, sin error (AC8)" |
| AC9 | ✅ | `storage_repository_test.dart` ("exportUserData con datos existentes produce la estructura documentada (AC7, AC9)") y `settings_screen_test.dart` (mismo test que AC7, verifica ausencia de `token`/`appCheck` en el JSON escrito a disco) |
| AC10 | ✅ | `settings_screen_test.dart` ("el enlace a la política completa navega a esa pantalla" — la navegación) + `legal/privacy_policy_screen_test.dart` ("AC10/AC11: carga y muestra el texto real del asset de política" — monta `PrivacyPolicyScreen` real, sin stub, y verifica contenido real del asset) |
| AC11 | ✅ manual | `app/assets/legal/privacy_policy_draft_es.md` leído completo: cubre proveedor de IA, sin cuentas, dónde viven los datos, borrar/exportar/revocar, dato sensible de salud, canal de contacto, y encabezado "BORRADOR: pendiente de revisión legal humana" |
| AC12 | ✅ | `onboarding_screen_test.dart`: "AC12: la casilla de consentimiento nombra el dato de salud, el destino y el propósito" |
| AC13 | ✅ | `settings_screen_test.dart`: "AC13: cancelar el diálogo de revocar no cambia nada" |
| AC14 | ✅ | `settings_screen_test.dart`: "AC14: confirmar revocar limpia el consentimiento, navega al gate, y no toca meals" |

Verificado: `app` → `flutter analyze` sin issues, `flutter test` 79/79 verdes (incluye las 3
integraciones existentes de SPEC-001/002/004 ajustadas para sembrar consentimiento antes de pumpear
`MyApp`, ya que ahora el gate de onboarding es lo primero que se ve sin él).

## Definition of Done
- Todos los AC con evidencia · `flutter analyze` y `flutter test` verdes · reviewer PASS enlazado ·
  `docs/privacy.md` y `docs/backlog.md` actualizados · texto de política revisado contra los
  hallazgos de PV-07 (revisión legal humana sigue pendiente aparte, no bloquea `Done` de esta SPEC,
  igual que AC4/AC11 de SPEC-005 con Vertex AI).

## Change Log
- 2026-09-28: creación, a partir de T-007 de `docs/backlog.md`.
- 2026-09-28: incorporados los hallazgos de PV-07 (`researcher`,
  `docs/research/2026-09-28-ley-1581-consentimiento.md`): R2 ahora exige texto explícito en la
  casilla de consentimiento (dato de salud, qué se envía, a quién, para qué); R6/AC11 suman un canal
  de contacto para derechos ARCO; se resolvió la pregunta de si un checkbox basta legalmente (sí); se
  dejaron como "pendiente aceptado" dos puntos que PV-07 no pudo cerrar (transmisión vs. transferencia
  internacional bajo el contrato real de Google, aplicabilidad del RNBD).
- 2026-09-29: el usuario aprobó sumar R8 "Revocar consentimiento" (AC13/AC14), separado de "Borrar
  todos mis datos" — cierra el gap de Ley 1581 Art. 8 (derecho a revocar la autorización en cualquier
  momento) que señaló PV-07. Ya no quedan Open Questions.
- 2026-09-29: el usuario aprobó la SPEC ("aprobada"). Status → `Implementing`.
- 2026-09-29: implementación completa (tabla `ConsentRecord`, onboarding, Ajustes, exportación,
  borrador de política, `docs/privacy.md` actualizado). 77/77 tests de `app` verdes, `flutter
  analyze` sin issues. Status → `Review`.
- 2026-09-29: primera pasada del reviewer — `CHANGES_REQUESTED`, 2 MAJOR reales:
  1. "Exportar mis datos" no manejaba errores del share sheet/E·S de archivo — quedaban sin capturar
     en un callback `async void`, contradiciendo el Edge Case ya documentado en esta SPEC y el
     invariante de errores visibles en español de CLAUDE.md. Corregido: `try/catch` en las tres
     acciones de Ajustes (exportar, borrar todo, revocar), con el mismo mensaje genérico que ya usa
     `ai_client_errors.dart` ("Ocurrió un error. Intenta de nuevo."). Nuevo test en
     `settings_screen_test.dart` con `FakeSharingService(shouldThrow: true)` que confirma el mensaje
     y que la pantalla no se cae.
  2. La evidencia citada para AC10 solo probaba que ocurre una navegación (ruta *stub*), no que
     `PrivacyPolicyScreen` realmente carga y muestra el texto del asset — un typo futuro en la ruta
     del asset no se habría detectado. Corregido: nuevo test
     `test/features/legal/privacy_policy_screen_test.dart` que monta `PrivacyPolicyScreen` real
     (sin stub) y verifica contenido real del markdown.
  También se corrigió el MINOR relacionado: `PrivacyPolicyScreen` no manejaba `snapshot.hasError` en
  su `FutureBuilder` (quedaría en spinner infinito si el asset fallara al cargar) — ahora muestra el
  mismo mensaje genérico en español. El MINOR sobre `SettingsController` escribiendo `dart:io File`
  directamente (en vez de una interfaz de `infra/`) se dejó como está — no bloquea, y crear una
  abstracción para un solo call site de escritura sería sobre-ingeniería para lo que hace.
  `flutter test` → 79/79 verdes tras los fixes.

## Review
Informe del reviewer:
