# SPEC-026: Editar, borrar y repetir comidas guardadas

## Status
Implementing
Path: Standard (cambia comidas guardadas en `user.db`; recalcula con `nutrition_core` sin reglas
nuevas; no sale ningún dato)

## Objective
Que la persona pueda arreglar comidas ya guardadas (cantidades, ingredientes, tipo, fecha y hora),
borrarlas y repetirlas hoy. Buscar en el historial pasó a SPEC-036.

## Context
Fase F3 de `docs/backlog.md` ("historial avanzado"). Hoy una comida guardada no se puede editar ni
borrar (SPEC-012 y SPEC-013 lo dejaron fuera de alcance); solo existe "Borrar todos mis datos". Cada
comida guarda una instantánea de valores (`docs/architecture.md`, Modelo de datos).

## User Story
Como persona que se equivocó al registrar, quiero corregir o borrar esa comida en el historial, para
que mis promedios sean reales.

## Requirements
- R1. **Abrir una comida guardada** desde Hoy o Historial: el "Detalle de comida" en modo edición, con
  sus ítems, cantidades, tipo, fecha y hora.
- R2. **Editar:** −/+ de gramos, quitar ítems, "Añadir ingrediente" (SPEC-018), tipo de comida y
  fecha/hora (no futura). Al guardar se reemplaza la comida en una transacción; los ítems editados se
  recalculan con el catálogo actual y `nutrition_core`; los no tocados conservan su instantánea.
  `updated_at` cambia.
- R3. **Borrar una comida** con confirmación ("¿Borrar el almuerzo de las 13:00?").
- R4. **Duplicar en otro día:** "Repetir hoy" desde una comida antigua (equivale a una reciente de
  SPEC-017).
- R5. *(Movido a SPEC-036: buscar en el historial.)*
- R6. Hoy, Historial, Progreso, la racha y la exportación reflejan los cambios al volver.
- R7. **Mismas acciones que al registrar:** en modo edición, cada ingrediente tiene el menú ⋮ de
  SPEC-033/034 ("Usar etiqueta", "Escribir los valores", "Elegir de mis productos", "Quitar") y la
  cantidad en porciones para productos personales.

## Acceptance Criteria
- AC1. Editar el huevo de 100 g a 150 g en una comida de ayer y guardar → la comida conserva su `id`,
  el ítem tiene 150 g y sus kcal de `nutrition_core`; el día de ayer en el Historial muestra el total
  nuevo `[integration]`.
- AC2. Mover una comida de las 13:00 de ayer a las 8:00 de hoy → aparece en Hoy y desaparece de ayer;
  una fecha futura no se permite `[widget + integration]`.
- AC3. Borrar con confirmación quita la comida y sus ítems; cancelar no borra nada `[integration]`.
- AC4. Un ítem no tocado conserva su instantánea aunque el catálogo haya cambiado; uno editado usa el
  catálogo actual `[unit]`.
- AC5. *(Movido a SPEC-036.)*
- AC6. Un fallo de escritura muestra un mensaje en español y deja la comida como estaba (SPEC-009)
  `[widget]`.
- AC7. "Repetir hoy" desde una comida antigua abre el detalle con sus alimentos y gramos y guarda una
  comida nueva con la hora actual; al volver, Hoy, Historial, Progreso y la racha muestran los cambios
  `[integration]`.
- AC8. En modo edición, "Elegir de mis productos" en un ingrediente lo cambia a ese producto y, al
  guardar, la comida conserva su `id` con el ingrediente nuevo; los demás conservan su instantánea
  `[widget + integration]`.

## Technical Constraints
- Invariantes 3, 4 y 8. Errores como SPEC-009. Confianza de la comida recalculada por reglas
  (regla del 15 %) al guardar.

## Components / Files Affected
- `app/lib/infra/storage/` (actualizar y borrar comida, búsqueda), `app/lib/features/review/` (modo
  edición), `app/lib/features/history/`, `app/lib/features/diary/`.

## Dependencies
- SPEC-012, SPEC-013, SPEC-017, SPEC-018.

## Edge Cases
- Quitar todos los ítems: "Guardar" deshabilitado; para eliminar se usa "Borrar comida".
- Producto personal borrado desde que se registró la comida: el ítem se puede ajustar en gramos con su
  instantánea, pero no recalcular con valores nuevos.
- Editar mientras otra pantalla tiene la comida cargada: al volver se recarga.

## Security & Privacy
- No sale ningún dato del dispositivo.

## Tests Required
- Unit: AC4. Widget: AC2, AC6, AC8. Integration: AC1–AC3, AC7, AC8. Manual: recorrido en el teléfono.

## Out of Scope
- Historial de cambios (versiones de una comida), editar desde la exportación, borrar por rango de
  fechas, deshacer un borrado.

## Open Questions
- Ninguna. Resueltas por la usuaria (2026-10-08): no se ofrece "Actualizar con la base actual" (los
  ítems no tocados conservan su instantánea); la búsqueda (SPEC-036) no filtra por tipo de comida.

## Definition of Done
- AC1–AC4 y AC6–AC8 con evidencia · analyze y tests verdes · reviewer PASS enlazado · arquitectura actualizada
  (edición de comidas guardadas).

## Change Log
- 2026-10-04: creación a partir de F3 ("historial avanzado").
- 2026-10-08: **Approved por la usuaria** ("aprobada"). Antes de implementar se propusieron y ella
  confirmó ("sí, confirmo las cuatro"): sin "Actualizar con la base actual"; la búsqueda no filtra por
  tipo; R7/AC8 nuevos (mismas acciones de SPEC-033/034 al editar); R5/AC5 (buscar en el historial)
  pasan a SPEC-036. Status → Implementing.
- 2026-10-08: implementada.
  - Repositorio: `getMealWithItems`, `updateMeal` (transacción, mismo `id`, `updated_at`) y
    `deleteMeal`.
  - `ReviewController.forEdit`: cada ítem guarda su `savedSnapshot` hasta que se edita; un producto
    borrado se arma con la instantánea. `setEatenAt`, `deleteEditedMeal`; `register` actualiza en vez de
    crear.
  - `draftFromMeal` (compartido con Recientes) para "Repetir hoy".
  - Ruta `AppRoutes.editMeal`; tocar una comida en Hoy o Historial la abre. Modo edición del Detalle:
    "Editar comida", fecha y hora con "Cambiar", "Borrar comida", "Guardar cambios" y "Repetir hoy".
- 2026-10-08: reviewer CHANGES_REQUESTED (1 MAJOR de evidencia, 10 MINOR); corregidos (ver Review).
  422/422.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/review/edit_meal_test.dart` › "AC1: huevo de 100 g a 150 g…" (mismo `id`, 150 g, kcal 143 × 1,5 y total del día). Integración con `MyApp`: `app/test/integration/edit_meal_flow_test.dart` › "SPEC-026 AC1/AC7/R6…" (Historial de ayer 143 → tocar la comida → + (100 → 105 g) → "Guardar cambios" → Historial de ayer 150 kcal; los 150 g del AC están en el test del controlador) y "SPEC-026 R1/R6…" (desde Hoy) |
| AC2 | ✅ | `edit_meal_test.dart` › "AC2: mover a hoy a las 8:00…" (repositorio), "AC2: una fecha futura no se permite" (`validateEatenAt`), "AC2: \"Cambiar\" abre el calendario" y "AC2: hoy con una hora posterior a la actual…" (widget: mensaje y la fecha no cambia). El calendario no ofrece días futuros (`lastDate` = hoy). Que la comida movida esté en el día nuevo lo prueba el test del controlador con `mealsForDay` (la misma lectura que usa Hoy); no hay integración con `MyApp` que mueva una comida |
| AC3 | ✅ | mismo archivo › "AC3: borrar con confirmación…" (comida e ítems borrados; "¿Borrar el almuerzo de las 13:00?") y "AC3: cancelar no borra nada" |
| AC4 | ✅ | mismo archivo › "AC4…": con el catálogo cambiado (huevo 200 kcal), el huevo no tocado guarda 143 y "Huevo"; la arepa editada usa el catálogo actual. Caso borde: "un producto borrado se puede ajustar con su instantánea" |
| AC5 | — | Movido a SPEC-036 |
| AC6 | ✅ | mismo archivo › "AC6…" (`updateMeal` falla → "No pude guardar la comida…", sin texto de SQLite, comida en 100 g) y "AC6: si borrar falla…" ("No pude borrar la comida…"). Caso borde: "la comida ya no existe" ("Esa comida ya no existe.") |
| AC7 | ✅ | mismo archivo › "AC7…": "Repetir hoy" → Detalle → "Guardar" → comida nueva a la hora actual con los mismos gramos; la de ayer sigue igual. Integración con `MyApp` ("SPEC-026 AC1/AC7/R6…"): después de "Repetir hoy", Hoy muestra la comida, la racha dice "2 días seguidos registrando", Historial de hoy 150 kcal y Progreso "miércoles 7 de octubre: 150 kcal" y "jueves 8 de octubre: 150 kcal". "R4: una comida de hoy no ofrece…" y "R4: con cambios sin guardar, \"Repetir hoy\" se desactiva" |
| AC8 | ✅ | mismo archivo › "AC8…": "Elegir de mis productos" en el huevo → "Guardar cambios" → mismo `id`, el huevo es el producto y la arepa conserva su instantánea (proteína 6,5 g; el catálogo daría 6,509) |
| Docs | ✅ | `docs/architecture.md` (Modelo de datos: edición de comidas guardadas; tablas de SPEC-034) |
| Tests | ✅ | app: analyze sin avisos, 423/423; ningún test existente cambió |
| Manual | ⏳ | Editar, borrar y repetir una comida en el teléfono |

## Review
Revisión (2026-10-08, subagente `reviewer`, sobre `57b9fbf`): **CHANGES_REQUESTED**.
- [MAJOR] Sin evidencia de que Historial (AC1), Hoy, Progreso y la racha (AC7/R6) muestren los cambios.
  Corregido: integración con `MyApp` que edita una comida de ayer desde Historial y la repite hoy, y
  comprueba Historial, Hoy, la racha y Progreso.
- MINOR corregidos: widget de hora futura (AC2); AC8 distingue instantánea de catálogo (proteína);
  "¿Borrar la cena…?" con artículo por tipo (`mealWithArticle`); constante fuera del comentario de
  R12; `firstDate` para comidas de más de 5 años; "Repetir hoy" desactivado con cambios sin guardar;
  `catalog_version` documentado en `docs/architecture.md`; test de `updated_at`; tests de error al
  borrar y de comida que ya no existe.
- MINOR al backlog: `_snapshotFood` (instantánea → por 100 g en la app) se suma a T-035.

Re-revisión (2026-10-08, sobre `59e8cd5`): **PASS**. MAJOR y MINOR anteriores resueltos; AC1–AC4 y
AC6–AC8 con evidencia. 4 MINOR, corregidos después: `hasChanges` se marca solo en los métodos que
cambian datos (`_changed()`; no `setShowInGrams` ni elegir el mismo tipo) con test; redacción de la
evidencia de AC1 y AC2; el test del calendario no depende del idioma (`okButtonLabel`).
