# SPEC-009: Errores de almacenamiento sin datos del usuario en Crashlytics

## Status
Draft
Path: Strict (cambia qué datos salen del dispositivo: el contenido de los reportes de fallos de
Crashlytics, SPEC-007)

## Objective
Que ningún fallo de `user.db` envíe a Crashlytics datos del usuario (alimentos, cantidades,
productos, perfil), y que la persona vea un mensaje en español en vez de un error técnico o una
pantalla colgada.

## Context
Backlog T-010, hallazgo del reviewer en SPEC-008. La base se abre con
`NativeDatabase.createInBackground`, y el texto de `SqliteException` (sqlite3 3.6.0,
`lib/src/exception.dart`) incluye la sentencia y sus **parámetros**. Todo error asíncrono que no se
captura llega a `PlatformDispatcher.instance.onError` (`app/lib/main.dart`), que llama a
`crashReporter.recordError(error, stack)`. Con consentimiento vigente, ese reporte sale a Firebase
Crashlytics con el mensaje completo.

SPEC-008 ya resolvió el problema en sus pantallas (perfil y objetivo). Revisión del código
(2026-10-03) del resto de escrituras y lecturas:

| Lugar | Operación | ¿Captura errores? |
|---|---|---|
| `review_screen.dart` `_register` → `ReviewController.register` | `registerMeal` (escritura: alimentos, gramos, nutrientes) | **No** |
| `label_confirmation_screen.dart` `_save` → `savePersonalProduct` | escritura (nombre del producto, valores de la etiqueta) | **No** (`try/finally` sin `catch`) |
| `review_screen.dart` `_loadController` | `getAllPersonalProducts` (lectura) | No; además la pantalla se queda cargando |
| `diary_screen.dart` (`FutureBuilder`) | `mealsForDay`, `getNutritionGoal` (lectura) | El error queda en el `snapshot`, pero la pantalla muestra el spinner para siempre |
| `app.dart` `_RootGate._checkConsent` | `getConsentState` (lectura) | No; la app se queda en el spinner inicial |
| Onboarding, Ajustes (borrar, exportar, revocar), perfil y objetivo | varias | Sí |

## User Story
Como persona que usa la app, quiero que si algo falla al guardar o leer mis datos se me diga en
español qué pasó y pueda reintentar, sin que mis datos de comida o de salud viajen en un reporte de
fallos.

## Requirements
- R1. **Defensa en profundidad en el reporte de fallos.** `CrashReporter` (`infra/crash_reporting`)
  nunca envía el mensaje de un error de almacenamiento. Si el error, o su causa encadenada, es
  `SqliteException`, `DriftRemoteException`, `DriftWrappedException`, `CouldNotRollBackException` o
  `InvalidDataException`, reporta en su lugar un `StorageFailure` sin texto del usuario: solo el tipo
  original y, si existe, el código numérico de resultado de SQLite, más el stack trace (que solo
  tiene nombres de funciones y archivos). Aplica tanto a `recordError` como a
  `recordFlutterFatalError`.
- R2. **Registrar una comida.** Si `registerMeal` falla, la pantalla de revisión muestra "No pude
  guardar la comida. Intenta de nuevo." y se queda en la revisión con los ítems intactos. La
  excepción no se relanza.
- R3. **Guardar un producto de etiqueta.** Si `savePersonalProduct` falla, la pantalla de
  confirmación muestra "No pude guardar el producto. Intenta de nuevo." y conserva lo escrito. La
  excepción no se relanza.
- R4. **Lecturas.** Si falla la lectura del diario, de los productos personales (revisión) o del
  consentimiento (arranque), la pantalla muestra "No pude leer tus datos. Intenta de nuevo." con un
  botón "Reintentar", en vez de quedarse cargando.
- R5. Ningún mensaje visible incluye el texto técnico de la excepción.

## Acceptance Criteria
- AC1. `recordError` con una `SqliteException` cuyo mensaje incluye "parameters: pollo, 150" envía
  un error cuyo `toString()` no contiene "pollo" ni "150", e indica el tipo y el código de resultado.
  Errores que no son de almacenamiento se envían igual que hoy `[unit]`.
- AC2. Lo mismo para una `DriftRemoteException` cuya causa remota es una `SqliteException`, y para
  `recordFlutterFatalError` con un `FlutterErrorDetails` cuya excepción es de almacenamiento
  `[unit]`.
- AC3. Revisión: con un repositorio que falla en `registerMeal`, tocar "Registrar" muestra el
  mensaje de R2, la pantalla sigue en revisión con los ítems y `takeException()` es nulo `[widget]`.
- AC4. Confirmación de etiqueta: con un repositorio que falla en `savePersonalProduct`, guardar
  muestra el mensaje de R3, no navega y `takeException()` es nulo `[widget]`.
- AC5. Diario, revisión y arranque con lecturas que fallan → mensaje de R4 y "Reintentar". Al
  reintentar con el repositorio ya sano, carga normal `[widget]`.
- AC6. Las suites existentes siguen verdes: el flujo normal no cambia `[unit + widget + integration]`.

## Technical Constraints
- Invariantes 5 y 6 de `CLAUDE.md`: nada nuevo sale del dispositivo; esta SPEC **reduce** lo que
  sale.
- Errores visibles en español, accionables y sin trazas (CLAUDE.md, Convenciones).
- Las features no se importan entre sí; la UI no usa Drift directamente. Los tipos de excepción de
  Drift o sqlite3 solo se nombran en `infra/crash_reporting`.

## Components / Files Affected
- `app/lib/infra/crash_reporting/crash_reporter.dart` (+ `storage_failure.dart`): saneamiento (R1).
- `app/lib/features/review/review_screen.dart` y `review_controller.dart` (R2, lectura de R4).
- `app/lib/features/capture/label_confirmation_screen.dart` y su controlador (R3).
- `app/lib/features/diary/diary_screen.dart` (R4).
- `app/lib/app.dart` `_RootGate` (R4).
- `docs/privacy.md`: la fila de Crashlytics aclara que los errores de almacenamiento se envían
  saneados.

## Dependencies
- SPEC-007 (Crashlytics), SPEC-008 (mismo patrón ya aplicado en perfil y objetivo).

## Edge Cases
- Un error de almacenamiento envuelto en otra excepción (causa encadenada) también se sanea (R1).
- Un error que no es de almacenamiento pero cuyo mensaje trae datos del usuario: fuera del alcance
  (ver Out of Scope); hoy no se conoce ningún caso.
- Sin consentimiento vigente, Crashlytics está desactivado (SPEC-007) y no se envía nada; el
  saneamiento aplica igual, por si se activa.
- Doble toque en "Registrar" durante un fallo: el botón se deshabilita mientras guarda, como hoy.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? **No.** Sale **menos**: los reportes de errores de
  almacenamiento ya no incluyen el mensaje de SQLite. Se actualiza `docs/privacy.md`.

## Tests Required
- Unit: AC1 y AC2, con un `CrashReporter` que envuelve un destino falso.
- Widget: AC3, AC4 y AC5, con repositorios que fallan.
- Suites completas: AC6.

## Out of Scope
- Revisar los mensajes de todos los demás tipos de excepción de la app.
- Reintentos automáticos o cola de escrituras pendientes.
- Cambios en el backend o en los logs de Cloud Functions (ya cumplen la invariante 5).
- Cifrado de `user.db` (PV-11).

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC6 con evidencia enlazada en esta SPEC.
- `flutter analyze` sin issues y `flutter test` verde.
- Reviewer: PASS enlazado.
- `docs/privacy.md` actualizado.
- Aprobación explícita de la usuaria antes de fusionar (Strict Path).

## Change Log
- 2026-10-03: creación a partir de T-010 de `docs/backlog.md`.

## Review
Informe del reviewer: pendiente.
