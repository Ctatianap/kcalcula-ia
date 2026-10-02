# SPEC-002: Entrada de una comida por voz

## Status
Done
Path: Strict (el audio puede salir del dispositivo hacia los servidores de reconocimiento de voz
del sistema operativo — requiere actualizar `docs/privacy.md`, aunque nunca vaya a nuestro backend)

## Objective
Que el usuario pueda decir lo que comió en vez de escribirlo, usando el reconocimiento de voz del
sistema operativo, y que el resultado entre exactamente al mismo flujo que ya existe para texto
(SPEC-001): revisión, cálculo, confianza, registro.

## Context
Backlog T-003, depende de T-002 (SPEC-001, ya implementada — `Status: Review`, reviewer `PASS`,
solo pendiente el eval real de AC11, que no bloquea esta SPEC). Aplica D3 de
`docs/decisions/ADR-001-decisiones-iniciales.md` ("Reconocimiento de voz del sistema operativo":
costo cero, el audio no pasa por nuestro backend). Resuelve PV-05 de
`docs/research/POR-VERIFICAR.md` ("Calidad de `speech_to_text` en es-CO en Android e iOS;
¿reconocimiento en el dispositivo o en servidores del SO?") con una medición manual, no con
telemetría nueva (no hay backend para eso — invariante 5, "sin estado").

## User Story
Como persona que quiere registrar lo que comió sin escribir, quiero presionar un botón, decir
"dos huevos y una arepa pequeña" y ver el mismo resultado que si lo hubiera escrito, para que
registrar sea más rápido cuando tengo las manos ocupadas o prefiero hablar.

## Requirements
- R1. Botón de micrófono en `CaptureScreen`, junto al campo de texto existente (no lo reemplaza).
- R2. Al presionar, pide permiso de micrófono (y de reconocimiento de voz en iOS) si no se ha
  concedido. Si se deniega: mensaje en español y el campo de texto sigue disponible (fallback).
- R3. Usa el reconocimiento de voz del sistema operativo (es-CO) — Android `SpeechRecognizer` /
  iOS `SFSpeechRecognizer` vía un paquete Flutter que envuelva ambos (verificar versión estable
  actual al implementar, sin inventarla aquí). El audio no sale del dispositivo hacia nuestro
  backend; puede salir hacia los servidores del sistema operativo según el dispositivo (esto ya
  ocurre en cualquier app que use STT del SO, no es un dato nuevo que este proyecto envíe).
- R4. Mientras escucha, muestra la transcripción parcial en vivo en el mismo campo de texto de
  captura (no un campo separado).
- R5. Se puede detener de dos formas, ambas soportadas: (a) botón manual de "detener", y (b) el
  fin automático por silencio: en **Android** la app no fija un tiempo de silencio y deja que el
  reconocedor del sistema operativo decida cuándo terminó la frase (con 2 s fijados por la app,
  el reconocedor cortaba a mitad de frase — medido en AC8); en **iOS**, ~2 segundos sin habla
  detectada (pendiente de revisar con la medición de AC8 en iPhone). En cualquiera de los dos
  casos, la transcripción final queda en el campo de texto, editable, exactamente como si el
  usuario la hubiera escrito — reutiliza `CaptureController.analyze(text)` sin ningún cambio.
  Si el sistema operativo cierra la escucha por su cuenta (en Android el reconocedor puede
  decidir que la frase terminó aunque no haya pausa — medido en AC8), la app vuelve al estado
  "listo" (botón de micrófono) y conserva el texto en el campo; nunca se queda mostrando
  "escuchando" sin estar escuchando.
- R6. El usuario puede editar la transcripción antes de presionar "Analizar" (ya existe el mismo
  `TextField`; esto solo lo prellena).
- R7. Errores manejados con mensaje en español y vuelta a estado inicial (nunca una traza técnica):
  sin permiso, reconocimiento no disponible en el dispositivo, error del plugin durante la escucha.
- R8. Sin telemetría nueva: no se envía a ningún backend si la transcripción fue editada o no. La
  medición de calidad (PV-05) es manual (ver AC8), no una función del producto.
- R9. Volver a tocar el micrófono cuando el campo ya tiene texto **agrega** la nueva
  transcripción al final de ese texto, separada por un espacio; no lo reemplaza. Así el usuario
  puede dictar por partes si la escucha se cortó.
- R10. El campo de captura tiene un botón ✕ ("Borrar texto"), antes de los botones de cámara y
  micrófono, que vacía el campo. Solo se muestra cuando hay texto y la app no está escuchando. No
  pide confirmación y no cambia el comportamiento del micrófono ni de la cámara.

## Acceptance Criteria
- AC1. Con permiso concedido, tocar el botón de micrófono muestra un indicador de "escuchando"
  `[widget]`.
- AC2. Con un resultado simulado del plugin (mock), la transcripción parcial aparece en el campo
  de texto mientras "escucha" `[unit]`.
- AC3. Al detener, el texto final queda en el campo, editable, y el botón "Analizar" se habilita
  igual que con texto escrito a mano `[widget]`.
- AC4. Permiso de micrófono denegado → mensaje "Necesito permiso del micrófono para esto. Puedes
  escribir en su lugar." y el campo de texto sigue disponible `[widget]`.
- AC5. Reconocimiento de voz no disponible en el dispositivo → mismo fallback a texto, con mensaje
  claro, sin traza técnica `[widget]`.
- AC6. Error del plugin durante la escucha → mensaje en español, vuelve a estado inicial (se puede
  reintentar o escribir) `[unit]`.
- AC7. Flujo completo con un resultado de voz simulado (mock del plugin) → transcripción → editar
  → Analizar → revisión → registro llega al mismo resultado que si se hubiera escrito el mismo
  texto directamente (reutiliza `CaptureController`/`ReviewController` sin cambios) `[integration]`.
- AC8. Un humano dice en voz alta, en es-CO, las 10 frases de
  `evals/datasets/slice_smoke.jsonl` (hoy `s01`–`s10` de `evals/datasets/parse_meal.v1.jsonl`,
  que lo reemplazó en SPEC-005), en un dispositivo Android y uno iOS reales (no simulador/
  emulador, que no tienen micrófono real). Se documenta en una nota de investigación (actualiza
  PV-05) la transcripción real vs. el texto esperado por frase y el % de coincidencia,
  distinguiendo Android de iOS `[manual]`.
- AC9. Si el reconocedor reporta que terminó de escuchar (`done`) sin que el usuario toque
  "Detener", el estado vuelve a inactivo, el botón vuelve a ser el micrófono y la transcripción
  sigue en el campo; un resultado final que llegue después del `done` también queda en el campo
  `[unit + widget]`.
- AC10. Con "dos huevos" en el campo, tocar el micrófono y dictar "y una arepa" deja
  "dos huevos y una arepa" en el campo `[unit + widget]`.
- AC11. En Android, `listen` se llama sin tiempo de silencio (`pauseFor` nulo); en iOS, con 2 s
  `[unit]`.
- AC12. Con texto en el campo, tocar ✕ lo deja vacío y deshabilita "Analizar"; con el campo vacío
  o mientras escucha, el ✕ no aparece; después de limpiar, dictar empieza desde cero `[widget]`.

## Technical Constraints
- Invariantes 1, 3, 4 y 6 de `CLAUDE.md`: la voz no aporta nutrientes ni confianza (eso lo sigue
  haciendo `nutrition_core` sobre el mismo `parsed_meal.v1` de siempre); nada nuevo sale del
  dispositivo hacia nuestro backend.
- No se crea ningún esquema ni prompt de IA nuevo: la transcripción entra al `parseMeal` existente
  sin cambios.
- La UI de voz vive dentro de `features/capture`; no se importa desde `features/review` ni
  `features/diary`.

## Components / Files Affected
`app/lib/features/capture/capture_screen.dart` (botón de micrófono) ·
`app/lib/features/capture/voice_input_controller.dart` (nuevo: estados idle/listening/error,
envuelve el paquete STT) · `app/pubspec.yaml` (paquete STT) ·
`app/android/app/src/main/AndroidManifest.xml` (permiso de micrófono) ·
`app/ios/Runner/Info.plist` (`NSMicrophoneUsageDescription`,
`NSSpeechRecognitionUsageDescription`) · `docs/privacy.md` (nueva fila: audio de voz).

## Dependencies
T-002 (`CaptureScreen`/`CaptureController` ya existen y no cambian su contrato público).

## Edge Cases
- Permiso denegado permanentemente (el usuario debe ir a Ajustes del sistema): mensaje que lo diga.
- Sin micrófono disponible (poco común, pero posible según el entorno).
- Silencio total, no se detecta habla: mismo fallback que "no disponible", con mensaje claro.
- El usuario detiene la escucha con el campo vacío: no habilita "Analizar" (mismo comportamiento
  que un campo de texto vacío hoy).
- Limitación conocida (aceptada en la revisión del 2026-10-02): si el SO no arranca la escucha
  sin reportar error, la UI puede mostrar "Escuchando…" hasta que el usuario toque "Detener";
  `speech_to_text` 7.5.0 no expone si la escucha arrancó. Si `listen` lanza una excepción, sí se
  muestra el mensaje de error (R7).
- Un error del reconocedor que llega después de que la escucha ya se cerró (`done`, "Detener" o
  ✕) se ignora: no hay nada que el usuario pueda reintentar.

## Security & Privacy
- Sale del dispositivo: el audio, hacia los servidores de reconocimiento de voz del sistema
  operativo (Apple/Google), según el dispositivo y su configuración — no hacia nuestro backend.
  Esto ya ocurre hoy en cualquier app que use STT del SO; este cambio lo hace explícito en
  `docs/privacy.md` (fila "Audio de voz", ya existe como placeholder, se completa con lo real).
- Sin cambios en qué llega a `parseMeal`: sigue siendo solo texto, mismo límite de 1-500 caracteres.

## Tests Required
- Unit: `voice_input_controller_test.dart` — transiciones de estado (idle/listening/error) con un
  mock de la interfaz del plugin STT (AC2, AC6).
- Widget: `capture_screen_voice_test.dart` — botón de micrófono, indicador de escucha, fallback sin
  permiso, fallback sin disponibilidad (AC1, AC3, AC4, AC5).
- Integration: extiende el patrón de `capture_to_review_flow_test.dart` con un resultado de voz
  simulado en vez de texto tecleado (AC7).
- Manual: AC8 (dispositivos reales, no simulador).

## Out of Scope
Editar cantidades por voz en la pantalla de revisión, comandos de voz para otras acciones de la
app, corrección conversacional del resultado (Fase 3, F3), guardar o transcribir el audio para
otro propósito que no sea rellenar el campo de texto.

## Open Questions
- Paquete Flutter exacto para STT (se verifica su versión estable al implementar, no se fija aquí).

## Evidencia de Acceptance Criteria
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/capture/capture_screen_voice_test.dart` |
| AC2 | ✅ | `app/test/features/capture/voice_input_controller_test.dart` |
| AC3 | ✅ | `app/test/features/capture/capture_screen_voice_test.dart` |
| AC4 | ✅ | `voice_input_controller_test.dart` + `capture_screen_voice_test.dart` |
| AC5 | ✅ | `voice_input_controller_test.dart` + `capture_screen_voice_test.dart` |
| AC6 | ✅ | `app/test/features/capture/voice_input_controller_test.dart` |
| AC7 | ✅ | `app/test/integration/voice_to_review_flow_test.dart` |
| AC8 | ✅ Android · ⏳ iOS pendiente aceptado | Android (motorola edge 50 pro, Android 16, es-CO): 3 rondas documentadas en `docs/research/2026-10-01-voz-es-co-dispositivos.md`; versión final 8/10 exactas, 98 % de palabras correctas; sin red no hay reconocimiento (audio a servidores de Google). PV-05 y `docs/privacy.md` actualizados. **iOS: pendiente aceptado por el usuario (2026-10-02)** — no hay iPhone disponible para medir; queda abierto en PV-05 y en `docs/privacy.md`, y con él la validación de los ~2 s de silencio de R5 en iOS. Paquete: `speech_to_text` 7.5.0. |
| AC9 | ✅ | `voice_input_controller_test.dart` (done → inactivo con texto; final tardío; doble `done`) + `capture_screen_voice_test.dart`. Verificado en el Motorola con log de diagnóstico temporal (ya retirado) |
| AC10 | ✅ | `voice_input_controller_test.dart` + `capture_screen_voice_test.dart`. Verificado en el Motorola (prefijo "media ta" agregado al reintentar) |
| AC11 | ✅ | `voice_input_controller_test.dart`, grupo "AC11" (`silencePauseFor` y `startListening` con `debugDefaultTargetPlatformOverride` en Android e iOS) |
| AC12 | ✅ | `capture_screen_voice_test.dart`, grupo "AC12" (3 tests). Probado a mano en el Motorola por el usuario (2026-10-02) |

Verificado (2026-10-02, tras R5/R9/R10): `flutter analyze` sin issues; `flutter test` 93/93 verdes.
Verificado (2026-09-28, versión inicial): `flutter analyze` sin issues; `flutter test` 29/29 verdes (antes 19; suma las 10 nuevas
de esta SPEC más 0 regresiones).

## Definition of Done
- AC1–AC12 con evidencia enlazada en esta SPEC (AC8 en iOS: pendiente aceptado).
- `flutter analyze` y todos los tests verdes.
- Reviewer: PASS enlazado.
- `docs/privacy.md` actualizado con el resultado real (no supuesto) de dónde procesa la voz cada
  plataforma.
- PV-05 de `docs/research/POR-VERIFICAR.md` actualizado con el resultado de AC8.

## Change Log
- 2026-09-28: creación, a partir de T-003 de `docs/backlog.md`.
- 2026-09-28: resuelta la Open Question de detener la escucha — R5 confirma botón manual y
  timeout de silencio (~2s), ambos soportados.
- 2026-10-01: la medición de AC8 en un motorola edge 50 pro (Android 16) mostró que el
  reconocedor del SO cierra la escucha a mitad de frase sin pausa, y que la app no se enteraba
  (seguía en "escuchando") y al reintentar borraba el texto. Log de diagnóstico: parciales
  acumulativos correctos, luego `notListening` → `done` → resultado final. Aprobado por el usuario
  (opción A): R5 ampliado (cierre por el SO → estado listo, texto conservado), R9 nuevo (agregar
  en vez de reemplazar), AC9 y AC10 nuevos. La opción B (reanudar sola la escucha) se descartó por
  ahora. Status Review → Implementing.
- 2026-10-02: la ronda 2 de AC8 mostró que con el arreglo anterior seguían los cortes prematuros
  (s04 cortada en "media ta"). Experimento sin `pauseFor` en Android: 0 cortes en 5 intentos con
  voz, s05 exacta 2 de 2 (ver la nota de PV-05). Aprobado por el usuario: R5 cambia (Android sin
  tiempo de silencio fijado por la app; iOS mantiene ~2 s hasta medirlo) y AC11 nuevo.
- 2026-10-02: a pedido del usuario tras la ronda final de AC8 (con R9, dictar agrega al texto y
  hacía falta una forma de empezar de cero): R10 y AC12 nuevos, aprobados por el usuario.
- 2026-10-02: AC8 en iOS queda como pendiente aceptado por decisión del usuario. AC8 corrige la
  referencia a `slice_smoke.jsonl` (reemplazado en SPEC-005; mismas 10 frases). Status
  Implementing → Review.
- 2026-10-02: reviewer PASS (re-revisión). El usuario aprueba cerrar: Status Review → Done y
  fusión en `develop`. AC8 en iOS sigue como pendiente aceptado (PV-05 abierto para iOS).

## Review
Informe del reviewer (2026-09-28, subagente `reviewer`, rama `spec-002-entrada-por-voz`):

```
VERDICT: PASS
SPEC: SPEC-002
Tests: cd app && flutter analyze && flutter test → "No issues found!"; 29/29 tests verdes.

| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1-AC7 | ✅ | Ver tabla "Evidencia de Acceptance Criteria" arriba; el reviewer verificó cada test
  de primera mano (incluye el mensaje exacto de error y que nunca se filtra el errorMsg crudo
  del plugin en AC6).
| AC8 | ⏳ pendiente (aceptado) | Requiere Android e iPhone físicos, no simulable. No es un fallo.

Verificado además: sin dato nuevo hacia el backend propio (solo el audio puede salir hacia el SO,
según R3/D3); docs/privacy.md actualizado sin inventar el resultado de AC8; sin cambios a
parsed_meal.v1 ni prompts de IA; sin telemetría de calidad de transcripción (R8); permisos de
plataforma declarados en español; features/capture sigue sin importar otras features;
SpeechRecognizer/MicrophonePermission son interfaces propias usadas con fakes en los tests;
fixture_catalog.dart se comparte correctamente en los 4 sitios que antes duplicaban el esquema.

Hallazgos:
- [MINOR] voice_input_controller.dart — `reset()` no se usaba desde ningún sitio. Corregido:
  se eliminó (no hacía falta en ningún flujo real).
- [MINOR] capture_screen.dart — un resultado parcial de voz puede sobrescribir texto que el
  usuario escribiera a mano *durante* la escucha (no cubierto por ningún R/AC, que solo exigen
  edición *después* de detener). Documentado como comportamiento conocido, no se corrigió por
  estar fuera del alcance de esta SPEC.
- Sin BLOCKER ni MAJOR.
```

### Re-revisión (2026-10-02, subagente `reviewer`, rama `spec-002-entrada-por-voz`)

Primera pasada sobre los cambios de R5/R9/R10 y AC9–AC12: **CHANGES_REQUESTED**.
- [MAJOR] Si `listen` fallaba al empezar, la UI quedaba en "Escuchando…" sin escuchar (contradice R5/R7).
- [MINOR] Un final después de un error borraba el mensaje de error.
- [MINOR] Un resultado tardío podía volver a llenar el campo recién borrado con ✕.
- [MINOR] Un doble toque mientras inicia abría dos sesiones.
- [MINOR] La nota de PV-05 describía una sola configuración para todas las rondas.
- [MINOR] Los callbacks de `initialize` solo quedaban registrados en la primera llamada.

Corregidos en `f98a206`, con 5 tests nuevos.

Segunda pasada sobre `f98a206`: **PASS**.
- `flutter analyze` sin issues; `flutter test` 98/98.
- AC1–AC12 cumplen; AC8 en iOS como pendiente aceptado por el usuario.
- Sin cambios en `functions/`, `packages/`, `data/` ni `evals/`; ningún dato nuevo hacia el backend; sin restos de diagnóstico.

MINOR de la segunda pasada:
- Limitación de `started == false`: documentada en Edge Cases.
- Errores tardíos de una escucha ya cerrada: ahora se ignoran, con test (99/99).
- ✕ con un error visible lo limpia: comportamiento aceptado, sin test.
- `ensureGranted` o `initialize` que lancen una excepción: preexistente; la UI no queda en "escuchando".
