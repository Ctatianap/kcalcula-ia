# SPEC-002: Entrada de una comida por voz

## Status
Draft
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
- R5. Se puede detener de dos formas, ambas soportadas: (a) botón manual de "detener", y (b) un
  timeout de silencio automático (~2 segundos sin habla detectada). En cualquiera de los dos
  casos, la transcripción final queda en el campo de texto, editable, exactamente como si el
  usuario la hubiera escrito — reutiliza `CaptureController.analyze(text)` sin ningún cambio.
- R6. El usuario puede editar la transcripción antes de presionar "Analizar" (ya existe el mismo
  `TextField`; esto solo lo prellena).
- R7. Errores manejados con mensaje en español y vuelta a estado inicial (nunca una traza técnica):
  sin permiso, reconocimiento no disponible en el dispositivo, error del plugin durante la escucha.
- R8. Sin telemetría nueva: no se envía a ningún backend si la transcripción fue editada o no. La
  medición de calidad (PV-05) es manual (ver AC8), no una función del producto.

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
  `evals/datasets/slice_smoke.jsonl`, en un dispositivo Android y uno iOS reales (no simulador/
  emulador, que no tienen micrófono real). Se documenta en una nota de investigación (actualiza
  PV-05) la transcripción real vs. el texto esperado por frase y el % de coincidencia,
  distinguiendo Android de iOS `[manual]`.

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

## Definition of Done
- AC1–AC8 con evidencia enlazada en esta SPEC.
- `flutter analyze` y todos los tests verdes.
- Reviewer: PASS enlazado.
- `docs/privacy.md` actualizado con el resultado real (no supuesto) de dónde procesa la voz cada
  plataforma.
- PV-05 de `docs/research/POR-VERIFICAR.md` actualizado con el resultado de AC8.

## Change Log
- 2026-09-28: creación, a partir de T-003 de `docs/backlog.md`.
- 2026-09-28: resuelta la Open Question de detener la escucha — R5 confirma botón manual y
  timeout de silencio (~2s), ambos soportados.

## Review
Informe del reviewer:
