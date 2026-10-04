# SPEC-024: Corrección conversacional

## Status
Draft
Path: Strict (prompt y esquema de IA nuevos; sale del dispositivo el texto de la corrección y la lista
de ítems sin nutrientes)

## Objective
Que la persona corrija el borrador de una comida diciendo o escribiendo qué estuvo mal ("no era arepa,
era pan integral", "el arroz fue una taza"), sin rehacer todo el registro.

## Context
Fase F3 de `docs/backlog.md`. Hoy, en el "Detalle de comida" (SPEC-012) se corrige a mano (−/+,
quitar, elegir candidato, "Añadir ingrediente" de SPEC-018) o con "Corregir", que vuelve al texto y
repite el análisis completo. Invariante 1: la IA estructura; aquí estructura **cambios**, nunca
valores nutricionales.

## User Story
Como persona que ve un error en el borrador, quiero decir la corrección con mis palabras y que la app
la aplique, para no empezar de nuevo.

## Requirements
- R1. **Entrada:** en el detalle, un campo "¿Algo no está bien? Cuéntamelo" (texto o voz, 1–300
  caracteres) con "Aplicar".
- R2. **Callable `correctMeal`** con esquema `meal_correction.v1`: recibe la corrección y la lista
  actual de ítems **solo con** `mention`, `food_query`, `quantity`, `unit` y `size` (sin nutrientes,
  sin gramos calculados, sin confianza) y devuelve operaciones: `replace(index, item)`, `add(item)`,
  `remove(index)`, `set_quantity(index, quantity, unit, size)`. Los ítems usan los campos de
  `parsed_meal.v1`. Sin nutrientes. Prompt versionado `correct_meal.v1.md`, zod, un reintento,
  `ai-invalid-output`.
- R3. **Aplicación local:** las operaciones se aplican en el dispositivo y cada ítem nuevo o cambiado
  se resuelve y calcula como siempre (catálogo + `nutrition_core`). La confianza se recalcula por
  reglas.
- R4. **Vista previa y deshacer:** antes de aplicar se muestra qué cambia ("Arepa → Pan integral");
  después, "Deshacer" vuelve al estado anterior.
- R5. Una operación con un índice que no existe invalida toda la respuesta (no se aplica a medias).
- R6. Privacidad: el texto de la corrección y la lista de ítems sin nutrientes salen hacia el proveedor
  de IA; el backend no los guarda ni los registra. `docs/privacy.md` y política actualizados.

## Acceptance Criteria
- AC1. Borrador "dos huevos y una arepa" + "no era arepa, era pan integral" con el proveedor falso
  devolviendo `replace(1, pan integral)` → la vista previa muestra "Arepa → Pan integral" y al aplicar
  el ítem 2 es el pan del catálogo con sus kcal de `nutrition_core` `[integration]`.
- AC2. "el arroz fue una taza" → `set_quantity` → los gramos salen de `household_units` × densidad, y
  la confianza baja a "Estimación" por regla `[unit + widget]`.
- AC3. El esquema `meal_correction.v1` rechaza campos de nutrientes, gramos o confianza
  (`additionalProperties: false`) y la petición nunca incluye nutrientes `[unit, functions + app]`.
- AC4. Respuesta con índice inexistente → no se aplica nada y se muestra "No pude aplicar esa
  corrección. Prueba a decirla de otra forma." `[unit + widget]`.
- AC5. "Deshacer" restaura exactamente el borrador anterior `[widget]`.
- AC6. Evals con al menos 20 correcciones en es-CO (dataset nuevo): validez de esquema 100 % y
  operaciones correctas con baseline guardado `[eval]`.
- AC7. Logs del backend solo con metadatos `[unit, functions]`.
- AC8. El campo de corrección acepta texto o voz; vacío o con más de 300 caracteres, "Aplicar" queda
  deshabilitado y el backend rechaza la petición (`invalid-argument`) `[widget + unit, functions]`.

## Technical Constraints
- Invariantes 1, 3, 4, 5, 6 y 7. Skill `ai-pipeline`.

## Components / Files Affected
- `functions/src/ai/` (callable, esquema, prompt, adaptadores), `evals/`.
- `app/lib/infra/ai_client/`, `app/lib/features/review/` (campo, vista previa, deshacer).
- `docs/architecture.md`, `docs/privacy.md`, política.

## Dependencies
- SPEC-012, SPEC-018 (añadir ítems), SPEC-002 (voz).

## Edge Cases
- Corrección que no cambia nada ("está bien") → la IA devuelve 0 operaciones → "No vi nada que
  cambiar".
- Sin red / timeout → mensaje de SPEC-012, el borrador queda igual.
- Corrección que pide un alimento no encontrado → el ítem queda "No encontrado en la base".
- Comida ya guardada: fuera de alcance (ver SPEC-026).

## Security & Privacy
- **Sí sale un dato nuevo:** el texto de la corrección y la lista de ítems (sin nutrientes). Strict +
  `docs/privacy.md` + política (nueva versión si el cambio es sustantivo).

## Tests Required
- Unit (functions): AC3, AC7. Unit (app): aplicación de operaciones, AC2, AC4. Widget: AC2, AC4, AC5.
  Integration: AC1. Eval: AC6. Manual: correcciones por voz en el teléfono.

## Out of Scope
- Corregir comidas ya guardadas, conversación de varios turnos, que la IA proponga cantidades en
  gramos.

## Open Questions
- ¿Se envía también el texto original de la comida como contexto? Mejora la precisión pero envía más
  datos (minimización).
- ¿Una sola corrección por vez o encadenadas antes de guardar?

## Definition of Done
- AC1–AC8 con evidencia · analyze, tests y evals sin regresión · reviewer PASS enlazado · docs y
  política actualizados · aprobación de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-04: creación a partir de F3 ("corrección conversacional").

## Review
Informe del reviewer: pendiente.
