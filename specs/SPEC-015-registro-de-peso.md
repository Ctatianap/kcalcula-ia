# SPEC-015: Registro de peso y tendencia

## Status
Review
Path: Strict (dato personal de salud nuevo, con historial, guardado en el dispositivo)

## Objective
Que la persona registre su peso a lo largo del tiempo, vea su tendencia en Progreso y que el perfil y
la meta usen siempre el último peso.

## Context
Backlog T-016. Diseño: tarjeta "Peso · 62,0 kg · −0,4 kg esta semana" del artboard "Progreso" del
lienzo https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD. Hoy el peso es un solo valor en
`user_profile` (SPEC-008) y cambiarlo recalcula la meta (R9).

## User Story
Como persona que sigue un objetivo, quiero anotar mi peso cuando me peso y ver si va bajando, subiendo
o se mantiene.

## Requirements
- R1. **Tabla `weight_log`** en `user.db` (fecha, kg), con migración. Un registro por día: anotar dos
  veces el mismo día reemplaza el valor.
- R2. **Anotar peso** desde la tarjeta de Peso en Progreso (botón "Anotar peso", 30–300 kg, un
  decimal) y desde "Mi perfil": guardar el perfil con un peso distinto crea el registro de hoy.
- R3. **El perfil usa el último peso:** `user_profile.weight_kg` se mantiene igual al registro más
  reciente; al anotar desde Progreso se actualiza el perfil y se recalcula la meta como en SPEC-008
  R9 (una sola transacción).
- R4. **Tarjeta de Peso** en Progreso: último peso ("62,0 kg"), cambio frente al registro más cercano
  a 7 días antes ("−0,4 kg esta semana", o "sin cambios"; sin registro previo, no se muestra el
  cambio) y un gráfico de línea con los registros del periodo elegido (SPEC-014 R1). Tono neutro: sin
  colores de "bien" o "mal".
- R5. **Borrar un registro** de peso (desde la lista de registros del periodo), con confirmación.
- R6. **Privacidad:** el historial de peso nunca sale del dispositivo; "Borrar todos mis datos" lo
  elimina y "Exportar" lo incluye. Se actualizan `docs/privacy.md` y la política (sube de versión y
  pide de nuevo el consentimiento, como en SPEC-008 R13).
- R7. El cálculo del cambio vive en `nutrition_core` (o en un módulo puro de la app) sin redondear
  hasta presentar.

## Acceptance Criteria
- AC1. Anotar 62,0 hoy y 62,4 hace 7 días → la tarjeta muestra "62,0 kg" y "−0,4 kg esta semana";
  un solo registro → sin cambio `[unit + widget]`.
- AC2. Anotar dos veces el mismo día deja un solo registro con el último valor `[integration]`.
- AC3. Anotar peso desde Progreso actualiza el perfil y recalcula una meta de objetivo (no manual) en
  la misma transacción `[integration]`.
- AC4. Guardar el perfil con otro peso crea el registro de hoy `[integration]`.
- AC5. Borrar todo vacía `weight_log`; exportar lo incluye; migración desde v6 conserva todo
  `[integration]`.
- AC6. Fuera de rango (29,9 o 300,1) → mensaje y no se guarda `[widget]`.
- AC7. La política sube de versión, menciona el historial de peso y vuelve a pedir el consentimiento
  `[widget + integration]`.

## Technical Constraints
- Invariantes 3, 5 y 6. Errores de almacenamiento como en SPEC-009.

## Components / Files Affected
- `app/lib/infra/storage/` (tabla, migración, repositorio, borrar y exportar).
- `app/lib/features/progress/` (tarjeta y gráfico), `app/lib/features/goals/` (perfil).
- Política de privacidad, `docs/privacy.md`, `docs/architecture.md`.

## Dependencies
- SPEC-014 (Progreso), SPEC-008 (perfil y recálculo).

## Edge Cases
- Registro en una fecha futura: no se permite (la fecha es la de hoy).
- Borrar el registro más reciente: el perfil pasa al anterior y la meta se recalcula; si no queda
  ninguno, el perfil conserva su peso.
- Fallo de escritura: mensaje y sin relanzar (SPEC-009).

## Security & Privacy
- Dato de salud nuevo con historial, solo en el dispositivo. Se actualizan la política (nueva
  versión) y `docs/privacy.md`.

## Tests Required
- Unit: AC1 (cálculo del cambio). Widget: AC1, AC6, AC7. Integration: AC2–AC5, AC7.
- Manual: anotar peso en el teléfono y ver la tendencia.

## Out of Scope
- Anotar peso en fechas pasadas, IMC, metas de peso, fotos de progreso, importar de otras apps (F4).

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC7 con evidencia; analyze y tests verdes; reviewer PASS; docs y política actualizados;
  recorrido manual; aprobación de la usuaria antes de fusionar (Strict).

## Evidencia
| AC | Evidencia |
|----|-----------|
| AC1 | `packages/nutrition_core/test/weight_trend_test.dart` › "SPEC-015 AC1: cambio de la semana" (unit); `app/test/features/progress/weight_card_test.dart` › "AC1: 62,0 hoy y 62,4 hace 7 días…" y "AC1: un solo registro → sin cambio" (widget) |
| AC2 | `app/test/infra/storage/weight_log_storage_test.dart` › "AC2: anotar dos veces el mismo día deja un registro con el último valor" |
| AC3 | mismo archivo › "AC3: anotar peso actualiza el perfil y recalcula la meta de objetivo", "AC3: la meta manual no se recalcula", "AC3: todo en una transacción…" |
| AC4 | mismo archivo › "AC4: guardar el perfil con otro peso crea el registro de hoy" (con `ProfileController` real) |
| AC5 | mismo archivo › "AC5: borrar todo vacía weight_log y exportar lo incluye" y "AC5: migrar desde la v6 conserva todo y crea weight_log vacía" |
| AC6 | `weight_card_test.dart` › "AC6: \"29,9\" / \"300,1\" (y \"62,55\", \"abc\") fuera de rango → mensaje y no se guarda" |
| AC7 | `test/features/legal/privacy_policy_text_test.dart` › "SPEC-015 AC7: la política v4 menciona el historial de peso…"; `test/integration/onboarding_gate_flow_test.dart` › "…quien aceptó la v2/v3 vuelve a ver el onboarding con la v4" |

Edge cases: borrar el más reciente (perfil al anterior; sin registros conserva su peso), sin perfil,
borrar con confirmación, fallo de escritura sin relanzar, texto ×2 en 360 px. Manual: anotar peso en
el teléfono y ver la tendencia (usuaria).

## Change Log
- 2026-10-03: creación a partir de T-016 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.
- 2026-10-03: implementada (autorización única de la usuaria para el lote, incluidas las Strict).
  Detalles menores:
  - `weight_log` con la fecha local (00:00) como clave primaria: un registro por día por diseño.
    `user.db` pasa a v7.
  - "Registro más cercano a 7 días antes": se buscan registros entre 1 y 14 días antes del último;
    gana el más cercano a 7 días y, en empate, el más antiguo. Más de 14 días ya no es "esta
    semana": sin cambio. "Sin cambios" si el cambio redondeado a un decimal es 0.
  - El primer guardado de "Mi perfil" también crea el registro de hoy (no hay peso anterior con el
    que comparar); guardar sin cambiar el peso no crea otro.
  - El recálculo de la meta (`maintenanceForProfile`, `recalculatedGoal`, `goalValuesFor`) pasó de
    `features/goals` a `infra/storage/goal_sync.dart` para que Progreso lo use sin importar otra
    feature; `goal_calculation.dart` lo reexporta. `parseDecimal` y `weightRangeMessage` pasaron a
    `ui/number_input_es.dart` por la misma razón.
  - Si la meta de objetivo no se puede recalcular (fuera de 800–6.000), el peso se guarda y se avisa
    con un mensaje, como en SPEC-008.
  - La tarjeta de Peso se muestra siempre en Progreso (también sin comidas en el periodo); el
    gráfico aparece con 2 o más registros en el periodo; la lista de registros del periodo va de
    más reciente a más antiguo, cada uno con "Borrar".
  - Política v4 (nueva sección "Tu historial de peso") y el texto de confirmación de "Borrar todos
    mis datos" ahora nombra perfil, meta e historial de peso.
  Status → Review.
- 2026-10-03: reviewer **PASS** (commit 8a84ba8; nutrition_core 91/91, app 248/248), sin BLOCKER ni
  MAJOR. MINOR atendidos antes de fusionar:
  - si el último registro tiene más de 7 días frente a hoy, la tarjeta muestra "Último registro:
    <fecha>" en lugar de "… esta semana" (test);
  - accesibilidad: "Peso" es encabezado, el cambio se lee con palabras ("Bajaste 0,4 kg esta
    semana") y el gráfico con un resumen (registros, primero, último, mínimo y máximo); el detalle
    queda en la lista accesible (test);
  - diálogos con contenido desplazable: con texto ×2 el de "Anotar peso" se desbordaba 8 px; el test
    de texto grande ahora cubre el gráfico en "Mes", el diálogo y la confirmación de borrado;
  - `mounted` antes de cada mensaje que sigue a un `await`;
  - `docs/privacy.md`: la fila de exportación nombra perfil, meta e historial de peso.
  - **Decisión de producto para que la usuaria la confirme en el recorrido:** la referencia del
    cambio se busca solo entre 1 y 14 días antes del último registro (más atrás no es "esta
    semana").
  - Aceptado: el recálculo de la meta vive en `infra/storage/goal_sync.dart`; si crece, irá a un
    módulo de dominio compartido.
  Fusionada en `develop` por la autorización única de la usuaria (incluidas las Strict). Sigue en
  Review hasta el recorrido manual en el teléfono.

## Review
Informe del reviewer (2026-10-03, commit 8a84ba8): **PASS**. AC1–AC7 con evidencia
(`weight_trend_test.dart`, `weight_log_storage_test.dart`, `weight_card_test.dart`, política y
onboarding); AC3 verificado como una sola transacción con rollback real; migración v6→v7 aditiva;
privacidad y política v4 actualizadas, sin datos nuevos fuera del dispositivo. MINOR atendidos (ver
Change Log).
