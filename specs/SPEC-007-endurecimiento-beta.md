# SPEC-007: Endurecimiento para beta

## Status
Implementing
Path: Strict (App Check real, nuevo dato que sale del dispositivo con Crashlytics — CLAUDE.md)

## Objective
Conectar la app por primera vez a un proyecto Firebase real (`kcalcula-ia-dev`), activar App Check
con proveedores reales, decidir e implementar el reporte de fallos con el consentimiento correcto,
y dejar un checklist verificable de lo que falta para una beta cerrada.

## Context
Backlog T-008, depende de T-003/T-004/T-005/T-006/T-007 (todos `Done`).

Al inventariar el estado real antes de escribir esta SPEC encontré que **la app nunca se ha
conectado a Firebase de verdad**: no existe `app/lib/firebase_options.dart` (no se ha corrido
`flutterfire configure`), `main.dart` nunca llama `Firebase.initializeApp()`, y `aiClientProvider`
sigue siendo el placeholder que lanza `UnimplementedError` fuera de los tests (`AiClient.firebase(...)`
existe desde SPEC-001 pero nunca se usó). Todo lo construido hasta ahora se probó contra fakes o el
emulador. `docs/architecture.md` ya documentaba la intención ("App Check obligatorio... en desarrollo
se usa el proveedor de depuración") pero el código para activarlo nunca se escribió.

Se le presentó esto al usuario junto con dos decisiones:
- **Reporte de fallos**: el usuario eligió **adoptar Firebase Crashlytics** (en vez de no adoptar
  nada). Esto es un dato nuevo que sale del dispositivo — Strict Path, requiere actualizar
  `docs/privacy.md` y el consentimiento de SPEC-006.
- **Proyecto objetivo**: el usuario eligió **`kcalcula-ia-dev` primero** (no `kcalcula-ia`/prod,
  que sigue diferido — ver memoria de la sesión sobre la separación dev/prod).

`docs/research/POR-VERIFICAR.md` tenía abierto **PV-08** (cuotas de Play Integrity/App Attest, TTL
recomendado); el subagente `researcher` lo investigó en paralelo a este Draft — ver
[`docs/research/2026-09-29-app-check-cuotas.md`](../docs/research/2026-09-29-app-check-cuotas.md).
Hallazgos clave: Play Integrity tiene cuota gratuita de 10.000 solicitudes/día (de sobra para una
beta cerrada), pero requiere vincular el proyecto de GCP a Play Console (rol Owner directo, app
puede quedarse en pista interna); App Attest no publica cuota pero es irrelevante a esta escala
(`attestKey()` es una vez por instalación) y **no funciona en el Simulador de iOS** (solo dispositivo
real o el proveedor de depuración); el TTL de token por defecto (1h, configurable 30 min–7 días) se
deja sin cambiar; y Firebase advierte explícitamente que dejar el proveedor de depuración activo en
una build de release expondría el backend a dispositivos no verificados — por eso el código debe
condicionar el proveedor por `kDebugMode`, no hardcodear el de depuración (AC14).

**Adoptar Crashlytics obliga a extender el mecanismo de consentimiento de SPEC-006**: hoy
`ConsentRecord` guarda `policyVersion`, pero nada compara ese valor contra la versión vigente del
código — un usuario que ya aceptó la política v1 nunca vería que cambió. Esta SPEC añade esa
comparación (R5) para que agregar Crashlytics dispare un re-consentimiento real, no silencioso.

## User Story
Como responsable de este proyecto, quiero que la app hable con un backend real y que si algo se
rompe en manos de un usuario de beta yo me entere — sin que eso signifique enviar el contenido de
sus comidas a ningún sitio, y sin que empiece a pasar antes de que la persona lo haya aceptado.

## Requirements
- R1: `main.dart` llama `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
  usando el `firebase_options.dart` generado por `flutterfire configure` contra `kcalcula-ia-dev`
  (acción del usuario, ver Checklist de beta) antes de construir cualquier provider que dependa de
  Firebase.
- R2: `aiClientProvider` se sobrescribe en `main.dart` con
  `AiClient.firebase(FirebaseFunctions.instanceFor(region: 'us-east1'))` (misma región que
  `functions/src/index.ts`) en vez de lanzar `UnimplementedError`.
- R3: App Check se activa inmediatamente después de `Firebase.initializeApp()`: proveedor de
  depuración en debug (`kDebugMode`), Play Integrity (Android) / App Attest (iOS) en release —
  igual que ya documenta `docs/architecture.md`, ahora escrito.
- R4: Firebase Crashlytics se inicializa en `main()` con la recolección **desactivada por defecto**
  (`setCrashlyticsCollectionEnabled(false)`). Los manejadores globales (`FlutterError.onError`,
  `PlatformDispatcher.instance.onError`) quedan conectados desde el arranque, pero no se envía nada
  mientras la recolección esté desactivada. Ningún error reportado incluye contenido de usuario
  (texto de comida, nombre de producto, foto, ruta de archivo exportado) — solo lo que Crashlytics
  adjunta por defecto (stack trace, versión de la app, metadata técnica del dispositivo). Detrás de
  una interfaz `CrashReporter` (mismo patrón que `SharingService`/`ImagePickerService`), para poder
  probarlo sin depender de Firebase real.
- R5: El gate de consentimiento (`_RootGate`, SPEC-006) compara `ConsentRecord.policyVersion` contra
  la versión vigente del código, no solo si existe una fila. Si difiere (o no existe), se muestra el
  onboarding antes de continuar. Al confirmar que hay consentimiento vigente, se activa la
  recolección de Crashlytics (`setCollectionEnabled(true)`); al revocar el consentimiento
  (`SettingsController.revokeConsent`, SPEC-006 R8), se desactiva de nuevo
  (`setCollectionEnabled(false)`).
- R6: El borrador de política (`privacy_policy_draft_es.md`) y el texto de la casilla de
  consentimiento (R2 de SPEC-006) se actualizan para nombrar explícitamente el reporte de fallos:
  qué se envía (solo diagnóstico técnico, nunca contenido de comidas), a quién (Google/Firebase
  Crashlytics), para qué (corregir errores). `privacyPolicyVersion` sube de `'v1'` a `'v2'`.
- R7: `docs/privacy.md` gana una fila nueva para Crashlytics en el inventario de datos.
- R8: Esta SPEC documenta un "Checklist de beta" (ver sección propia) con cada acción de consola que
  solo el usuario puede hacer, en orden, y qué hago yo después de cada una.
- R9: `maxInstances: 10` en `functions/src/index.ts` (ya existente desde SPEC-001) se revisa y se
  documenta como decisión vigente para una beta cerrada — sin cambio de código salvo que el usuario
  pida otro valor.
- R10: Auditoría de estados de error: `AiClientErrorType.appCheck` (ya mapeado en
  `ai_client_errors.dart`) se re-verifica contra App Check real; un fallo al inicializar o activar
  Crashlytics no bloquea el resto de la app (se captura, la app sigue funcionando sin reporte de
  fallos en esa sesión).

## Acceptance Criteria
- AC1: `app/lib/main.dart` llama `Firebase.initializeApp(...)` con
  `DefaultFirebaseOptions.currentPlatform` `[manual — bloqueado hasta que exista
  app/lib/firebase_options.dart, ver Checklist de beta]`
- AC2: `aiClientProvider` overridden con `AiClient.firebase(...)`, ya no lanza `UnimplementedError`
  en producción `[manual, mismo bloqueo]`
- AC3: `main.dart` activa App Check con `kDebugMode ? debug : (playIntegrity/appAttest)` `[manual,
  mismo bloqueo; verificación real de veredictos de Play Integrity/App Attest en un build de release
  firmado queda Out of Scope — requiere Play Console/Apple Developer]`
- AC4: `CrashReporter` (interfaz) se activa con `setCollectionEnabled(false)` en `main()` y ningún
  call site del proyecto le pasa contenido de usuario `[unit + revisión de código, grep dirigido]`
- AC5: Al aceptar el onboarding (primera vez, o tras un cambio de `policyVersion`) → se llama
  `crashReporter.setCollectionEnabled(true)` `[integration, con FakeCrashReporter]`
- AC6: Al revocar el consentimiento (SPEC-006 R8) → se llama
  `crashReporter.setCollectionEnabled(false)` `[integration]`
- AC7: `ConsentRecord` con `policyVersion` antiguo (`'v1'`) + reabrir la app → se muestra el
  onboarding de nuevo antes de `DiaryScreen`, con el texto actualizado (`'v2'`) — no es un estado
  distinto de "primer lanzamiento" `[integration]`
- AC8: `ConsentRecord` con `policyVersion` vigente (`'v2'`) → sigue entrando directo al diario, sin
  regresión de AC4 de SPEC-006 `[integration]`
- AC9: `docs/privacy.md` tiene la fila de Crashlytics (qué se envía, a quién, con qué exclusión
  explícita de contenido) `[manual]`
- AC10: El texto de política y la casilla de consentimiento mencionan Crashlytics explícitamente
  `[manual]`
- AC11: Esta SPEC incluye la sección "Checklist de beta" completa `[manual]`
- AC12: Si `CrashReporter` falla al inicializar o activar (p. ej. sin red), la app sigue funcionando
  con normalidad — no bloquea el onboarding ni el resto de la app `[unit]`
- AC13: Ningún test existente de SPEC-006 se rompe tras el bump de `policyVersion` y el nuevo
  criterio de comparación `[regresión — suite completa de `app`]`
- AC14: El proveedor de App Check en `main.dart` se decide con `kDebugMode` en tiempo de compilación
  (no un valor fijo ni una variable de entorno que pudiera quedar mal puesta) — revisión de código
  confirma que una build de release (`kDebugMode == false`) siempre resuelve a
  `playIntegrity`/`appAttest`, nunca al proveedor de depuración `[manual, revisión de código —
  PV-08: Firebase advierte que el proveedor de depuración en release expone el backend]`

## Technical Constraints
- Invariantes de CLAUDE.md que aplican: 5 (backend sin estado — no cambia), 6 (nada nuevo sale del
  dispositivo sin Strict Path + `docs/privacy.md` actualizado — Crashlytics es la superficie nueva,
  gateada por consentimiento).
- Nueva dependencia: `firebase_crashlytics: ^5.4.0` (verificado en pub.dev al momento de escribir).
- `firebase_options.dart` **no se genera a mano**: lo produce `flutterfire configure` (acción del
  usuario). El código que depende de él (R1-R3) no se escribe hasta que exista — evita romper
  `flutter analyze`/la compilación mientras tanto.
- `ConsentRecord` (tabla Drift de SPEC-006) no cambia de esquema — solo cambia la lógica que compara
  `policyVersion` contra la constante vigente (`infra/legal/privacy_policy.dart`).
- Región de `FirebaseFunctions.instanceFor` debe ser `'us-east1'`, igual que
  `functions/src/index.ts`.
- TTL de token de App Check: se deja el default de Firebase (1 hora) — PV-08 no encontró evidencia de
  que la escala de esta beta justifique cambiarlo.

## Components / Files Affected
- `app/lib/main.dart`: `Firebase.initializeApp`, activación de App Check, override de
  `aiClientProvider`, inicialización de `CrashReporter` con recolección desactivada.
- `app/lib/infra/crash_reporting/crash_reporter.dart` (nuevo): interfaz + `FirebaseCrashReporter`.
- `app/lib/infra/crash_reporting/crash_reporting_providers.dart` (nuevo).
- `app/lib/app.dart` (`_RootGate`): comparación de `policyVersion`, activa/desactiva
  `CrashReporter` según el resultado.
- `app/lib/features/settings/settings_controller.dart`: `revokeConsent()` también desactiva
  `CrashReporter`.
- `app/lib/infra/legal/privacy_policy.dart`: `privacyPolicyVersion` `'v1'` → `'v2'`.
- `app/assets/legal/privacy_policy_draft_es.md`: texto de Crashlytics + fecha/versión.
- `app/lib/features/onboarding/onboarding_screen.dart`: texto de la casilla de consentimiento.
- `app/pubspec.yaml`: `firebase_crashlytics`.
- `functions/src/index.ts`: sin cambio de código, comentario de decisión sobre `maxInstances`.
- `docs/privacy.md`: fila nueva de Crashlytics.
- `docs/backlog.md`: T-008 → estado de esta SPEC.
- `app/lib/firebase_options.dart` (generado por el usuario, no por mí — no se versiona a mano).

## Dependencies
- T-003, T-004, T-005, T-006, T-007 (todos `Done`).
- **Dependencia dura de una acción humana en medio de la implementación**: R1-R3 (y por lo tanto
  AC1-AC3) no se pueden escribir hasta que el usuario complete el primer bloque del Checklist de
  beta (`flutterfire configure`). R4-R10 (Crashlytics, re-consentimiento, docs, checklist) no
  dependen de eso y se implementan primero.

## Edge Cases
- Usuario con `ConsentRecord` de la versión anterior (`'v1'`) → ve el onboarding de nuevo con el
  texto actualizado; sus `meals`/`meal_items`/`personal_products` no se tocan (mismo criterio que
  revocar consentimiento en SPEC-006).
- Revocar consentimiento con Crashlytics ya activado → se desactiva junto con el resto del acceso a
  la app; no quedan reportes "en vuelo" con contenido (nunca los hubo, R4 los excluye por diseño).
- Sin red al intentar activar `CrashReporter` → falla en silencio, la app sigue funcionando, se
  reintenta en el próximo lanzamiento (mismo patrón que cualquier inicialización opcional).
- El proveedor de depuración de App Check queda activo por error en un build de release → riesgo de
  seguridad real (ver hallazgos de PV-08); se documenta cómo verificarlo en el Checklist de beta
  antes de publicar.
- `flutterfire configure` no se ha corrido todavía (estado actual del repo) → `main.dart` sigue
  usando los providers de siempre (fake en tests, `UnimplementedError` fuera de ellos) hasta que el
  usuario complete el paso; no se rompe nada mientras tanto.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? Sí: reportes de fallos de Crashlytics (stack traces,
  versión de la app, metadata técnica del dispositivo — Google/Firebase, fuera de Colombia, igual
  que Vertex AI). **Nunca** contenido de usuario. Gateado por consentimiento explícito (R5): no se
  envía nada hasta que el usuario acepta la política actualizada, y se detiene si revoca.
  `docs/privacy.md` se actualiza en el mismo cambio (invariante 6).
- App Check con proveedores reales reduce superficie de abuso del backend (atestación real de
  dispositivo en vez de solo el proveedor de depuración) — mejora de seguridad, no un dato nuevo.
- Sin secretos en el diff: `firebase_options.dart` contiene identificadores de proyecto públicos (no
  son secretos — son las mismas claves que ya viajan en cualquier APK/IPA), pero de todas formas no
  se versiona a mano por mí; lo genera el usuario con su propia sesión de `flutterfire configure`.

## Tests Required
- Unit: `crash_reporter_test.dart` (si aplica lógica propia más allá de delegar a Firebase);
  `privacy_policy_version_test.dart` o equivalente para la comparación de versión.
- Widget / Integration: extender `onboarding_gate_flow_test.dart` (AC7/AC8, con
  `FakeCrashReporter`), extender `settings_screen_test.dart` (AC6 — revocar desactiva el
  crash reporter).
- Eval: no aplica.
- Manual: AC1-AC3, AC9-AC11 (Checklist de beta, texto de política).

## Out of Scope
- Configurar `kcalcula-ia` (prod) — sigue diferido.
- Publicar la app en Play Store/App Store, o cualquier acción que solo tenga sentido con una cuenta
  real de Play Console/Apple Developer.
- Verificación real de veredictos de Play Integrity/App Attest en un dispositivo/build de release
  firmado (requiere lo anterior).
- Instrumentar manualmente cada bloque `catch` existente para reportar a Crashlytics — solo captura
  automática de errores no controlados (`FlutterError.onError`/`PlatformDispatcher.instance.onError`)
  por ahora.
- Cambiar `AI_PROVIDER` a `vertex` en ningún ambiente (decisión de costo aparte).
- Cifrado de `user.db` con SQLCipher (PV-11).
- Un texto de onboarding distinto para "primera vez" vs. "política actualizada" — misma pantalla en
  ambos casos.

## Open Questions
Ninguna abierta. Decisiones del usuario (Crashlytics sí, `kcalcula-ia-dev` primero) y hallazgos de
PV-08 ya incorporados.

## Checklist de beta (acciones que solo el usuario puede hacer)
En orden — dime cuando completes cada bloque y sigo con la implementación que depende de él:

1. `firebase login` (si esta máquina no tiene ya una sesión).
2. `dart pub global activate flutterfire_cli`.
3. Desde `app/`: `flutterfire configure --project=kcalcula-ia-dev`, seleccionar Android e iOS. Esto
   genera `app/lib/firebase_options.dart` y registra las apps en el proyecto `kcalcula-ia-dev`.
4. Confirmarme cuando esté listo — continúo con R1-R3 (Firebase real, App Check, `aiClientProvider`).
5. En la consola de GCP Billing de `kcalcula-ia-dev`: crear una alerta de presupuesto (bajo,
   coherente con minimizar costo — un umbral pequeño como aviso temprano, no un límite duro).
6. En la consola de Firebase de `kcalcula-ia-dev`: confirmar que Crashlytics aparece habilitado tras
   el primer evento de prueba (normalmente se activa solo).
7. Más adelante, no bloquea esta SPEC: cuando exista una build de release real, vincular el proyecto
   de GCP a Play Console (App integrity → Link Cloud project — quien lo haga debe ser Owner directo
   del proyecto, no basta un rol heredado por grupo; la app puede quedarse en pista interna, no hace
   falta publicarla) y un equipo de Apple Developer (iOS, App Attest no funciona en el Simulador,
   solo dispositivo real) para que Play Integrity/App Attest emitan veredictos reales — hasta
   entonces, cualquier build no-release sigue usando el proveedor de depuración. Cuota gratuita de
   Play Integrity: 10.000 solicitudes/día, de sobra para una beta cerrada.

## Definition of Done
- Todos los AC con evidencia (AC1-AC3 pueden quedar "pendiente aceptado" si el Checklist de beta no
  se completa en esta sesión — no bloquea `Done` de esta SPEC, igual que AC11 de SPEC-001 con
  Vertex AI real) · `flutter analyze` y `flutter test` verdes en `app` · reviewer PASS enlazado ·
  `docs/privacy.md` y `docs/backlog.md` actualizados.

## Change Log
- 2026-09-29: creación, a partir de T-008 de `docs/backlog.md`. Decisiones del usuario: adoptar
  Crashlytics; trabajar contra `kcalcula-ia-dev` primero.
- 2026-09-29: incorporados los hallazgos de PV-08 (`researcher`,
  `docs/research/2026-09-29-app-check-cuotas.md`): cuota de Play Integrity confirmada suficiente,
  requisito de vinculación a Play Console con rol Owner, App Attest sin cuota publicada pero sin
  soporte en Simulador, TTL por defecto sin cambios, y nuevo AC14 para verificar que el proveedor de
  depuración no pueda quedar activo en una build de release.
- 2026-09-30: el usuario aprobó implementar lo que no depende del Checklist de beta ("implementa lo
  que puedas"). Status → `Implementing`.

## Review
Informe del reviewer:
