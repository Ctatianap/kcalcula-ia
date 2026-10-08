# SPEC-022: Comidas frecuentes y favoritas

## Status
Draft
Path: Standard (reutiliza catálogo, cálculo y el flujo sin IA de SPEC-017; no cambia datos que salen)

## Objective
Que las comidas que la persona repite a menudo (o que marca como favoritas) estén a un toque, además de
las recientes.

## Context
Fase F2 de `docs/backlog.md` ("comidas frecuentes, ver T-018"). SPEC-017 ya muestra hasta 5 comidas
**recientes** y repite una sin IA con `MealDraft`; dejó fuera "favoritos fijados, renombrar comidas y
sugerencias por hora del día". Esta SPEC cubre frecuentes y favoritas.

## User Story
Como persona que desayuna casi siempre lo mismo, quiero tener esa comida a mano aunque no sea la última
que registré.

## Requirements
- R1. **Frecuentes:** en "¿Qué comiste?", una sección "Frecuentes" con hasta 5 comidas distintas
  (misma definición de "la misma comida" que SPEC-017) registradas **al menos 3 veces en los últimos
  60 días**, ordenadas por número de veces (empate: la más reciente primero). Una comida que ya está en
  Recientes no se repite en Frecuentes.
- R2. **Favoritas:** "Guardar como favorita" desde el detalle de una comida guardada (SPEC-026), desde
  el menú al mantener presionada una comida en Hoy o Historial (SPEC-037) y desde una tarjeta de
  Recientes/Frecuentes, con un nombre opcional (por defecto, los alimentos unidos con "y"). Las
  favoritas aparecen primero en "¿Qué comiste?", hasta 10, y se pueden quitar (mantener presionada →
  "Quitar de favoritas"). Los productos personales (SPEC-004/034) también pueden estar en una favorita.
- R3. **Tablas `favorite_meals` y `favorite_meal_items`** en `user.db` (nombre, fecha; por ítem: alimento
  o producto personal, mención, gramos y la cantidad tal como se expresó), con migración v8 → v9. Se
  borran con "Borrar todos mis datos" y se incluyen en "Exportar".
- R4. Tocar una frecuente o favorita abre el detalle con un `MealDraft` (SPEC-017): kcal del catálogo
  actual, tipo de comida por la hora, sin IA. Si un alimento ya no existe, la favorita se muestra con
  "Algún alimento ya no está en la base" y no se abre.
- R5. Sin frecuentes ni favoritas, las secciones no se muestran.

## Acceptance Criteria
- AC1. Con "huevo 100 g" registrado 4 veces y "arepa 115 g" 3 veces en 60 días (y otra comida 2
  veces), Frecuentes muestra huevo y luego arepa, y no la de 2 veces `[unit + widget]`.
- AC2. Una comida que está en Recientes no aparece también en Frecuentes `[unit]`.
- AC3. "Guardar como favorita" con nombre "Desayuno de siempre" la muestra primero en "¿Qué comiste?";
  quitarla la saca `[widget + integration]`.
- AC4. Tocar una favorita abre el detalle sin llamar a la IA (fake que falla si se llama) y guardar crea
  una comida nueva con la hora actual `[integration]`.
- AC5. Migración desde v8 conserva todo y crea las tablas de favoritas vacías; borrar todo las vacía;
  exportar las incluye `[integration]`.
- AC8. Mantener presionada una comida en Hoy → "Guardar como favorita" → aparece en Favoritas
  `[widget]`.
- AC6. Una favorita con un alimento que ya no existe se muestra con el aviso de R4 y no abre el detalle
  `[widget]`.
- AC7. Sin frecuentes ni favoritas, las secciones no aparecen `[widget]`.

## Technical Constraints
- Invariantes 1, 3, 4 y 8 (como SPEC-017: confianza de reglas guardada, kcal del catálogo actual).
- Errores de almacenamiento como SPEC-009.

## Components / Files Affected
- `app/lib/infra/storage/` (tabla, migración, consultas), `app/lib/infra/food_resolution/`
  (frecuentes), `app/lib/features/capture/`, `app/lib/features/history/` (botón de favorita).

## Dependencies
- SPEC-013, SPEC-017, SPEC-026, SPEC-034, SPEC-037.

## Edge Cases
- Más de 10 favoritas: no se permite añadir otra hasta quitar una (mensaje en español).
- Dos favoritas iguales: se avisa "Ya la tienes en favoritas".
- Nombre vacío o de más de 40 caracteres.

## Security & Privacy
- No sale ningún dato del dispositivo. Dato nuevo local (favoritas) → `docs/privacy.md` (inventario)
  y exportación.

## Tests Required
- Unit: AC1, AC2. Widget: AC1, AC3, AC6. Integration: AC3–AC5. Manual: recorrido en el teléfono.

## Out of Scope
- Sugerencias por hora del día, compartir favoritas, plantillas de días completos.

## Open Questions
- Ninguna. Resueltas con la opción recomendada (2026-10-08): umbral de frecuentes 3 veces en 60 días;
  hasta 10 favoritas; "Guardar como favorita" solo para comidas ya guardadas (no desde el detalle
  antes de guardar), para no guardar algo que la persona aún está corrigiendo.

## Definition of Done
- AC1–AC8 con evidencia · analyze y tests verdes · reviewer PASS enlazado · `docs/privacy.md` y
  arquitectura actualizados.

## Change Log
- 2026-10-04: creación a partir de F2 ("comidas frecuentes").
- 2026-10-08: actualizada antes de pedir aprobación: migración v8 → v9 (el esquema avanzó con SPEC-034),
  favorita también desde el menú de mantener presionada (SPEC-037) y con productos personales; tabla de
  ítems; preguntas abiertas resueltas con la opción recomendada. AC8 nuevo.

## Review
Informe del reviewer: pendiente.
