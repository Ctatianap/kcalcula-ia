# SPEC-022: Comidas frecuentes y favoritas

## Status
Done
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
- 2026-10-08: **Approved por la usuaria** ("aprobada"). Status → Implementing.
- 2026-10-08: implementada. Detalles menores:
  - Las favoritas guardan alimentos, gramos, cantidad tal como se expresó, base y confianza, **no**
    valores nutricionales: se calculan con el catálogo actual al abrirlas (R4).
  - Duplicada = mismos alimentos con los mismos gramos (la definición de SPEC-017), en cualquier orden.
  - En "¿Qué comiste?", mantener presionada una tarjeta abre una hoja con la acción ("Guardar como
    favorita" o "Quitar de favoritas"). Una favorita que no se puede abrir también se puede quitar.
  - En el detalle de una comida guardada, el botón se desactiva mientras haya cambios sin guardar (como
    "Repetir hoy").
  - El nombre por defecto es la lista de alimentos ("Huevo y Arepa"); el campo limita a 40 caracteres.
  - Tests de migración de SPEC-008/015/034 que comparaban la versión con 8 ahora esperan 9 (la versión
    vigente); no cambia lo que verifican.
  - app 488/488.
- 2026-10-08: reviewer PASS (manual pendiente). MINOR corregidos: la exportación incluye la cantidad tal
  como se expresó, la base y la confianza de cada alimento; las tarjetas de "¿Qué comiste?" tienen la
  pista "Mantén presionado para más opciones" y la acción "Más opciones" para el lector de pantalla;
  `saveFavoriteAction` en un solo lugar; el repositorio recorta el nombre a 40 caracteres y rechaza
  nombre vacío o sin alimentos; tests de esos casos y de los errores de guardar y quitar (SPEC-009).
  app 491/491.
- 2026-10-08: recorrido manual en el Motorola (Verificación). Status → Done.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/infra/food_resolution/frequent_and_favorite_meals_test.dart` › "AC1…" y "R1: empate…"; `app/test/features/capture/favorite_meals_flow_test.dart` › "AC1…" |
| AC2 | ✅ | `frequent_and_favorite_meals_test.dart` › "AC2…" |
| AC3 | ✅ | `favorite_meals_flow_test.dart` › "AC3…" (guardar con nombre, primero, duplicada, quitar); almacenamiento en `frequent_and_favorite_meals_test.dart` › "AC3 (almacenamiento)…" |
| AC4 | ✅ | `favorite_meals_flow_test.dart` › "AC4…" (fake que falla si se llama a la IA; hora actual) |
| AC5 | ✅ | `frequent_and_favorite_meals_test.dart` › "AC5…" (migración v8 → v9, exportar, borrar todo) |
| AC6 | ✅ | `favorite_meals_flow_test.dart` › "AC6…" y la prueba de lógica |
| AC7 | ✅ | `favorite_meals_flow_test.dart` › "AC7…" |
| AC8 | ✅ | `app/test/features/diary/meal_long_press_test.dart` › "SPEC-022 AC8…" |
| Manual | ✅ | 2026-10-08, en el Motorola de la usuaria (versión de `cb3031e`): Hoy → mantener presionado el desayuno → "Guardar como favorita" → nombre "Desayuno de siempre" → "Guardada en favoritas."; en "¿Qué comiste?" sale primero en Favoritas (~345 kcal); al tocarla abre el detalle con los mismos alimentos y la hora actual (no se guardó); mantener presionada → "Quitar de favoritas" la saca ("Quitada de favoritas."). Frecuentes no aparece: no hay comidas repetidas 3 veces en 60 días en ese teléfono |

## Review
Revisión (2026-10-08, subagente `reviewer`, sobre `78aa1f8`): **PASS**. AC1–AC8 con evidencia; las
favoritas no guardan valores nutricionales y se calculan con `nutrition_core` y el catálogo actual;
fronteras entre features respetadas; migración desde v8 y versiones viejas; borrar todo y exportar;
errores en español sin texto de SQLite; nada sale del dispositivo; `docs/privacy.md` y
`docs/architecture.md` al día. MINOR corregidos (Change Log). Recorrido manual hecho después (Verificación).
