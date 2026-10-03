# SPEC-015: Registro de peso y tendencia

## Status
Draft
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

## Change Log
- 2026-10-03: creación a partir de T-016 y del diseño "kcalcula ia UI".

## Review
Informe del reviewer: pendiente.
