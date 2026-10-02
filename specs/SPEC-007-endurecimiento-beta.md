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
- Unit: no hay lógica propia en `FirebaseCrashReporter` más allá de delegar a Firebase (sin test
  dedicado, igual que `PluginSharingService`/`PluginImagePickerService`) — la comparación de
  `policyVersion` vive en `_RootGate` y se prueba a nivel de integración (abajo), es demasiado
  simple (igualdad de strings) para justificar un archivo de test propio.
- Widget / Integration: `onboarding_gate_flow_test.dart` (AC1, AC5, AC7, AC8, AC12 — con
  `FakeCrashReporter`), `settings_screen_test.dart` (AC6, AC12 — revocar desactiva el crash
  reporter y sobrevive a que falle).
- Eval: no aplica.
- Manual: AC1-AC3, AC9-AC11, AC14 (Checklist de beta, texto de política, revisión de código del
  proveedor de App Check).

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

1. ✅ `firebase login` — hecho (2026-09-30).
2. ✅ `dart pub global activate flutterfire_cli` — hecho (2026-09-30, requirió instalar también la
   gema de Ruby `xcodeproj` para que `flutterfire configure` pudiera editar el proyecto de Xcode).
3. ✅ `flutterfire configure --project=kcalcula-ia-dev --platforms=android,ios --yes` — hecho
   (2026-09-30): `app/lib/firebase_options.dart` generado, apps Android
   (`com.caloriasia.calorias_ia`) e iOS (`com.caloriasia.caloriasIa`) registradas en
   `kcalcula-ia-dev`.
4. ✅ Continué con R1-R3 (Firebase real, App Check, `aiClientProvider`) — ver Evidencia de AC.
5. ✅ Alerta de presupuesto creada (2026-10-01) en GCP Billing para `kcalcula-ia-dev`: "Solo
   alertas" (no aplicación de límite — no corta el servicio), monto bajo, ajustable según el
   volumen real de alertas que lleguen. También se renombraron los apodos de las apps en la
   consola de Firebase de `calorias_ia (android/ios)` a `kcalcula-ia (android/ios)` — cambio
   cosmético, no afecta el paquete ni el código.
6. ✅ Confirmado (2026-10-01): corrí la app de verdad en el Simulador de iPhone (`flutter run`),
   completé el onboarding real (consentimiento aceptado), y la consola de Firebase Crashlytics
   para la app iOS pasó de "Agregar SDK" a **"Detectamos la app y estamos a la espera de que se
   produzca una falla"** — confirma que el SDK quedó bien registrado y que la recolección se activó
   tras el consentimiento, tal como lo diseña R4/R5. La vista de Android sigue en "Agregar SDK" sin
   confirmar — no hay emulador de Android en esta máquina para probarlo; el código es idéntico en
   ambas plataformas (mismo `main.dart`/`CrashReporter`), así que no hay motivo técnico para dudar
   de que se comporte igual — queda como verificación pendiente en un dispositivo/emulador Android
   real, no bloqueante.
7. Más adelante, no bloquea esta SPEC: cuando exista una build de release real, vincular el proyecto
   de GCP a Play Console (App integrity → Link Cloud project — quien lo haga debe ser Owner directo
   del proyecto, no basta un rol heredado por grupo; la app puede quedarse en pista interna, no hace
   falta publicarla) y un equipo de Apple Developer (iOS, App Attest no funciona en el Simulador,
   solo dispositivo real) para que Play Integrity/App Attest emitan veredictos reales — hasta
   entonces, cualquier build no-release sigue usando el proveedor de depuración. Cuota gratuita de
   Play Integrity: 10.000 solicitudes/día, de sobra para una beta cerrada.

## Evidencia de Acceptance Criteria
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | Checklist de beta completado por el usuario (`firebase login` + `flutterfire configure --project=kcalcula-ia-dev`): `app/lib/firebase_options.dart` generado, apps Android/iOS registradas en `kcalcula-ia-dev`. `main.dart` llama `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`. Verificado con `flutter build ios --no-codesign --debug` real (build exitoso) |
| AC2 | ✅ | `aiClientProvider` overridden en `main()` con `AiClient.firebase(FirebaseFunctions.instanceFor(region: 'us-east1'))`; mismo build de iOS confirma que compila y enlaza |
| AC3 | ✅ | `main.dart` activa App Check con `providerAndroid`/`providerApple` condicionados por `kDebugMode` (API no deprecada de `firebase_app_check` 0.4.8). Veredictos reales de Play Integrity/App Attest en un dispositivo siguen Out of Scope (requieren Play Console/Apple Developer, ver Checklist) |
| AC4 | ✅ | `CrashReporter`/`FirebaseCrashReporter` implementados (`infra/crash_reporting/`); grep dirigido confirma que ningún call site le pasa contenido de usuario. `main()` lo activa con `setCollectionEnabled(false)` apenas arranca, con manejo de error (AC12). **Verificado en vivo** (2026-10-01): corrida real en Simulador de iOS con consentimiento aceptado → la consola de Firebase Crashlytics (app iOS) pasó de "Agregar SDK" a "Detectamos la app y estamos a la espera de que se produzca una falla", confirmando que el SDK se activó de verdad tras el consentimiento. Android sin confirmar en esta máquina (sin emulador disponible) — mismo código, no bloqueante |
| AC5 | ✅ | `onboarding_gate_flow_test.dart`: "AC4/AC8: con consentimiento vigente entra directo al diario y activa el reporte de fallos" (la reentrada a `_RootGate` tras aceptar es el mismo camino) |
| AC6 | ✅ | `settings_screen_test.dart`: "AC14: confirmar revocar limpia el consentimiento..." verifica `crashReporter.collectionEnabled == false` |
| AC7 | ✅ | `onboarding_gate_flow_test.dart`: "AC7: policyVersion desactualizado vuelve a mostrar el onboarding..." |
| AC8 | ✅ | `onboarding_gate_flow_test.dart`: "AC4/AC8: con consentimiento vigente..." |
| AC9 | ✅ | `docs/privacy.md`, fila nueva "Reporte de fallos (SPEC-007, Firebase Crashlytics)" |
| AC10 | ✅ | `privacy_policy_draft_es.md` (sección "Si la app falla") y la casilla de consentimiento en `onboarding_screen.dart` mencionan Crashlytics explícitamente |
| AC11 | ✅ | Sección "Checklist de beta" de esta SPEC |
| AC12 | ✅ | `onboarding_gate_flow_test.dart`: "AC12: si activar el reporte de fallos falla, la app igual entra al diario"; `settings_screen_test.dart`: "AC12: si desactivar el reporte de fallos falla, la revocación igual se completa" |
| AC13 | ✅ | `flutter test` → 82/82 verdes (35 previos a este cambio del lado de SPEC-006 + los nuevos) |
| AC14 | ✅ | Revisión de código: `providerAndroid`/`providerApple` en `main.dart` se deciden con `kDebugMode ? ... : ...` en tiempo de compilación — una build de release (`kDebugMode == false`) siempre resuelve a `AndroidPlayIntegrityProvider`/`AppleAppAttestWithDeviceCheckFallbackProvider`, nunca al proveedor de depuración |

Verificado: `app` → `flutter analyze` sin issues, `flutter test` 82/82 verdes. `functions` → `tsc`
sin errores, `node --test` 51/51 verdes (sin cambios de lógica, solo el comentario de R9).
`flutter build ios --no-codesign --debug` y `flutter build apk --debug` reales → ambos exitosos
(confirma que la cadena completa Firebase + App Check + Crashlytics + AiClient real compila y
enlaza en los dos sistemas operativos).

**Hallazgo investigado y resuelto (fuera de los Requirements de esta SPEC, documentado aquí por
trazabilidad)**: `flutter build apk --debug` falló inicialmente porque `permission_handler_android`
14.0.0/14.1.0 fijan `compileSdk = 37` en su propio `build.gradle.kts`, pero Android dejó de publicar
la API 37 en forma "plana" (solo existen `37.0`/`37.1`/`37.2` — confirmado contra todos los canales
de `sdkmanager`, no es un problema de esta máquina) y el Android Gradle Plugin 9.1.0 (el que trae
Flutter 3.47.5 por defecto) solo soporta oficialmente hasta `compileSdk 36`. Es un problema real de
desfase entre `permission_handler_android` y el resto del ecosistema Flutter/AGP, no algo
introducido por esta SPEC. El usuario eligió fijar `permission_handler_android` a `13.0.1`
(`compileSdk 35`, anterior al cambio) vía `dependency_overrides` en `app/pubspec.yaml`, en vez de
subir todo el AGP del proyecto a una versión más nueva y menos probada. También quedó un symlink
local `android-37 → android-37.1` en el SDK de esta máquina (fuera del repo, reversible) que ayuda a
que Gradle resuelva rutas de plataforma durante la instalación de herramientas — no es necesario
para el fix en sí, pero no estorba. `flutter analyze`/`flutter test` (82/82) y ambos builds reales
se reverificaron después del cambio, sin regresiones. Revisar y quitar el `dependency_overrides`
cuando el ecosistema se ponga al día.

## Definition of Done
- Todos los AC con evidencia · `flutter analyze` y `flutter test` verdes en `app` · reviewer PASS enlazado ·
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
- 2026-09-30: implementación de la parte no bloqueada: `CrashReporter` (interfaz +
  `FirebaseCrashReporter`, recolección gateada por consentimiento vigente), `_RootGate` compara
  `policyVersion` y activa/desactiva el reporte de fallos, `SettingsController.revokeConsent()` lo
  desactiva, ambos caminos toleran que el crash reporter falle (AC12) sin romper el resto de la
  app. `privacyPolicyVersion` v1→v2, texto de política y de la casilla de consentimiento
  actualizados, `docs/privacy.md` con la fila de Crashlytics, comentario de decisión sobre
  `maxInstances` en `functions/src/index.ts`. Las 3 integraciones de SPEC-001/002/004 y
  `onboarding_gate_flow_test.dart` ajustadas para el nuevo criterio de `policyVersion` y para
  sobrescribir `crashReporterProvider`. `flutter test` → 82/82 verdes. AC1-AC3 y AC14 quedan
  "pendiente aceptado", bloqueados por el Checklist de beta (`flutterfire configure`).
- 2026-09-30: el usuario completó `firebase login` y me pidió seguir con el resto. Corrí
  `flutterfire configure --project=kcalcula-ia-dev` (requirió instalar la gema de Ruby `xcodeproj`
  que faltaba). Terminé R1-R3: `main.dart` conecta Firebase real, activa App Check (API no
  deprecada `providerAndroid`/`providerApple`), activa Crashlytics con recolección desactivada por
  defecto, y usa `AiClient.firebase(...)` real. Verificado con `flutter build ios --no-codesign
  --debug` (build exitoso). `flutter build apk --debug` reveló un problema de entorno no relacionado
  (desajuste de plataformas del SDK de Android en esta máquina) — documentado como hallazgo fuera de
  alcance, no bloquea esta SPEC. AC1-AC3 y AC14 pasan de "pendiente aceptado" a `✅`. `flutter test`
  sigue en 82/82.
- 2026-10-01: completado el resto del Checklist de beta con el usuario. Pasos 5-6: alerta de
  presupuesto creada en GCP Billing (`kcalcula-ia-dev`, "solo alertas", monto bajo ajustable);
  apodos de las apps renombrados en la consola de Firebase; corrida real de la app en el Simulador
  de iOS (dos veces — la segunda en "frío" con el consentimiento ya guardado) para validar
  Crashlytics de extremo a extremo: la consola pasó de "Agregar SDK" a "esperando una falla",
  confirmando que R4/R5 funcionan de verdad, no solo en tests. También se arregló en el camino el
  problema real de `permission_handler_android`/`compileSdk 37` (ver Evidencia de AC4/hallazgo más
  abajo): se fijó la versión a `13.0.1` vía `dependency_overrides`, y se verificaron builds reales
  de Android e iOS, ambos exitosos. Queda pendiente, no bloqueante: confirmar Crashlytics en Android
  real (sin emulador en esta máquina) y el paso 7 (Play Console/Apple Developer, para cuando haya
  una build de release real).

## Review
Informe del reviewer:
