# SPEC-019: Racha de días registrados

## Status
Done
Path: Standard (cuenta días con registros; no es un cálculo nutricional)

## Objective
Mostrar en "Hoy" cuántos días seguidos lleva la persona registrando lo que come, en tono neutro.

## Context
Backlog T-020 (opcional). Diseño: contador con ícono de llama junto al saludo en "Hoy" (lienzo
https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD).

## User Story
Como persona que intenta ser constante, quiero ver cuántos días seguidos llevo registrando.

## Requirements
- R1. **Racha:** número de días seguidos, hasta hoy, con al menos una comida registrada. Si hoy aún no
  hay registros, la racha cuenta hasta ayer (no se "rompe" hasta que termina el día).
- R2. Se muestra en el encabezado de "Hoy" como una píldora con ícono y número, con etiqueta
  semántica "N días seguidos registrando".
- R3. **Tono neutro:** sin mensajes de pérdida, castigos ni notificaciones. Con racha 0, la píldora
  muestra 0 sin texto adicional.
- R4. La regla vive en una función pura (en la app o en `nutrition_core`), con tests.

## Acceptance Criteria
- AC1. Registros hoy, ayer y anteayer → 3; registros ayer y anteayer (hoy vacío) → 2; registros hoy y
  anteayer (ayer vacío) → 1; sin registros → 0 `[unit]`.
- AC2. La píldora muestra el número y su etiqueta semántica `[widget]`.
- AC3. Ningún texto de la pantalla menciona perder la racha `[revisión]`.

## Technical Constraints
- Días por fecha local de `eaten_at`. Sistema visual de SPEC-010.

## Components / Files Affected
- `app/lib/features/diary/` (píldora y lectura), función de racha y su test.

## Dependencies
- SPEC-011.

## Edge Cases
- Cambio de zona horaria o de hora: se usa la fecha local de cada comida.
- Racha muy larga (más de 365): la lectura se limita a los últimos 400 días.

## Security & Privacy
- No sale ningún dato del dispositivo.

## Tests Required
- Unit: AC1. Widget: AC2. Revisión: AC3.

## Out of Scope
- Logros, medallas, notificaciones o recordatorios.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC3 con evidencia; analyze y tests verdes; reviewer PASS.

## Evidencia
| AC | Evidencia |
|----|-----------|
| AC1 | `app/test/features/diary/streak_test.dart` › grupo "AC1: racha" (hoy/ayer/anteayer → 3; ayer y anteayer → 2; hoy y anteayer → 1; sin registros → 0; varias comidas el mismo día, cambio de mes y año, tope de 400) |
| AC2 | mismo archivo › "AC2: la píldora muestra el número y su etiqueta semántica" y "R3: con racha 0 la píldora muestra 0 sin texto adicional" |
| AC3 | mismo archivo › "AC3: ningún texto de la app habla de perder la racha" (revisa todos los textos entre comillas de `app/lib`); revisión del diff: no hay mensajes, notificaciones ni castigos |

Manual: recorrido en el teléfono (usuaria).

## Change Log
- 2026-10-03: creación a partir de T-020 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.
- 2026-10-03: implementada (autorización única de la usuaria para el lote). Detalles menores:
  - Función pura `streakDays` en `app/lib/features/diary/streak.dart` (no es un cálculo
    nutricional), por fecha de calendario local y con tope de 400 días.
  - Lectura liviana: `StorageRepository.mealTimesSince` trae solo `eaten_at` de los últimos 400
    días (sin ítems).
  - Píldora (primero entre el saludo y Ajustes; luego en la línea de la fecha, ver abajo): llama (`local_fire_department_outlined`) en el acento y el
    número en el color de texto, fondo `surface`; etiqueta "N días seguidos registrando" ("1 día
    seguido registrando" en singular). Sin colores de alarma ni textos de pérdida.
  Status → Review.
- 2026-10-03: reviewer **PASS** (commit 9b7811e; app 307/307), sin BLOCKER ni MAJOR. MINOR atendidos
  antes de fusionar:
  - la píldora pasó a la línea de la fecha (en un `Wrap`): junto al saludo le quitaba ancho y, con
    texto ×2 en 360 px, "Buenas" se partía a mitad de palabra; test en 360 px ×2 que mide el
    ancho del saludo;
  - el test de AC3 revisa también textos entre comillas dobles y triples, sin comentarios;
  - el comentario de `streakDays` aclara que el cambio de hora queda cubierto por construcción
    (Colombia no tiene horario de verano).
  Fusionada en `develop` por la autorización única de la usuaria. Sigue en Review hasta el
  recorrido manual en el teléfono.
- 2026-10-07: recorrido manual en el teléfono (Motorola edge 50 pro, Android 16, build debug de
  `develop` en `dc92f55`). La usuaria lo dio por bueno ("si ya creo que el resto esta bien").
  Status Review → Done.

## Review
Informe del reviewer (2026-10-03, commit 9b7811e): **PASS**. AC1–AC3 con evidencia en
`streak_test.dart`; regla por fecha local con aritmética de calendario; píldora accesible con una
sola etiqueta; tono neutro. MINOR atendidos (ver Change Log).
