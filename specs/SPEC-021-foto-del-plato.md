# SPEC-021: Foto del plato

## Status
Draft
Path: Strict (prompt y esquema de IA nuevos; una imagen nueva sale del dispositivo)

## Objective
Que la persona pueda fotografiar su plato y obtener un borrador de la comida (alimentos y tamaños
aproximados) que **siempre** se trata como Estimación y que debe confirmar antes de guardar.

## Context
Fase F2 de `docs/backlog.md`. Decisión 6 del rediseño (2026-10-03): "foto del plato = F2, como
Estimación y con confirmación obligatoria". Hoy la pestaña Foto de "¿Qué comiste?" es solo la tabla
nutricional (SPEC-004, `extractLabel`). Invariante 1: la IA estructura, nunca calcula. ADR-002: en
desarrollo la IA puede ser local (Ollama); en producción, Vertex AI. PV-02: el modelo recomendado
admite visión (`docs/research/2026-09-27-vertex-ai-functions.md`).

## User Story
Como persona que come fuera o sin tiempo de escribir, quiero tomar una foto del plato y corregir lo que
la app proponga, para registrar sin escribir todo.

## Requirements
- R1. **Entrada:** la pestaña Foto ofrece dos opciones: "Foto de la tabla nutricional" (SPEC-004, sin
  cambios) y "Foto del plato" (nueva), con cámara o galería y el mismo redimensionado en el
  dispositivo que la etiqueta.
- R2. **Callable nueva `parseMealPhoto`** con esquema `parsed_meal_photo.v1` (o `parsed_meal.v2` si se
  decide unificar; ver Open Questions): por ítem `mention`, `food_query`, `size` (pequeño/mediano/
  grande o nulo), `quantity` y `unit` solo si se ven claramente (p. ej. "2 huevos"), `is_vague`.
  **Sin campos de nutrientes, calorías, gramos estimados ni confianza.** Prompt versionado
  `parse_meal_photo.v1.md`, validación zod, un reintento y `ai-invalid-output`.
- R3. **Confianza:** todos los ítems de una foto del plato son "Estimación" por regla (nueva fila en
  la tabla de Confianza de `docs/architecture.md`), aunque la base de cantidad sea `unit_portion`.
- R4. **Confirmación obligatoria:** el detalle muestra el aviso "Calculado a partir de una foto:
  revisa los alimentos y las cantidades." y "Guardar" se habilita solo después de que la persona toque
  "Ya revisé" (o edite algún ítem).
- R5. Mismo flujo de "Analizando" y de error de SPEC-012, con un consejo propio para la foto ("toma la
  foto desde arriba, con todo el plato a la vista").
- R6. **Privacidad:** la imagen sale del dispositivo hacia el proveedor de IA solo para estructurarla;
  el backend no la guarda ni la registra (invariante 5). Se actualizan `docs/privacy.md` y la política
  (nueva versión, re-consentimiento).
- R7. **Evals:** dataset de fotos de platos colombianos (cantidad mínima en Open Questions) con la
  lista esperada de alimentos; métricas de validez de esquema (100 %) y de alimentos identificados.

## Acceptance Criteria
- AC1. Con el proveedor falso, una foto que devuelve "arroz" (mediano) y "pollo" (sin tamaño) abre el
  detalle con esos ítems resueltos por el catálogo y la comida en "Estimación" `[integration]`.
- AC2. El esquema `parsed_meal_photo.v1` rechaza cualquier campo de nutrientes, calorías o gramos
  estimados por la IA (`additionalProperties: false`) `[unit, functions]`.
- AC3. En el detalle de una foto, "Guardar" está deshabilitado hasta tocar "Ya revisé" o editar un
  ítem; el aviso de R4 es visible `[widget]`.
- AC4. Una respuesta inválida dos veces → `ai-invalid-output` y la pantalla de error con el consejo de
  la foto `[unit + widget]`.
- AC5. Los logs del backend para `parseMealPhoto` contienen solo metadatos (requestId, versión de
  prompt, modelo, latencia, tokens, validez, código) `[unit, functions]`.
- AC6. Evals sobre el dataset de R7: validez de esquema 100 % y la métrica de alimentos identificados
  con su baseline guardado `[eval]`.
- AC7. Política nueva que menciona la foto del plato; quien aceptó la anterior vuelve al onboarding
  `[widget + integration]`.
- AC8. La pestaña Foto muestra "Foto de la tabla nutricional" y "Foto del plato"; la primera sigue
  llevando a la confirmación de etiqueta (SPEC-004) `[widget]`.

## Technical Constraints
- Invariantes 1, 4, 5, 6 y 7. Skill `ai-pipeline` (prompts inmutables, esquemas versionados, evals
  contra baseline). Tamaño máximo de imagen igual al de `extractLabel` salvo decisión en contra.
- Las kcal salen del catálogo y de `nutrition_core`, nunca de la IA.

## Components / Files Affected
- `functions/src/ai/` (callable, esquema, prompt, adaptadores Vertex/Ollama/fake), `evals/`.
- `app/lib/infra/ai_client/`, `app/lib/features/capture/` (opción nueva), `app/lib/features/review/`
  (aviso y confirmación), `packages/nutrition_core` (regla de confianza por origen "foto del plato").
- `docs/architecture.md`, `docs/privacy.md`, política de privacidad.

## Dependencies
- SPEC-004 (redimensionado y permisos de cámara), SPEC-005 (evals), SPEC-012 (flujo de análisis).

## Edge Cases
- Foto sin comida, borrosa u oscura → "No encontré alimentos en la foto" con consejos.
- Foto de una tabla nutricional en la opción del plato (y al revés) → se sugiere la otra opción.
- Sin red / timeout del proveedor → pantalla de error de SPEC-012.
- Platos mixtos (bandeja paisa, sancocho) → la IA lista componentes; los no encontrados quedan "No
  encontrado en la base".
- Permiso de cámara denegado → mensaje de SPEC-004.

## Security & Privacy
- **Sí sale un dato nuevo:** la foto del plato, hacia el proveedor de IA configurado. Strict +
  `docs/privacy.md` + política nueva + re-consentimiento.

## Tests Required
- Unit (functions): AC2, AC4, AC5. Unit (nutrition_core): regla de confianza. Widget: AC3, AC4, AC7.
  Integration: AC1, AC7. Eval: AC6. Manual: fotos reales en el teléfono.

## Out of Scope
- Estimar gramos o volumen desde la imagen, reconocer marcas, varias fotos por comida, video,
  procesamiento de la imagen en el dispositivo con un modelo local.

## Open Questions
- ¿Esquema propio (`parsed_meal_photo.v1`) o `parsed_meal.v2` compartido con el texto? (Recomendado:
  propio, para no tocar el baseline del texto.)
- ¿La IA puede proponer `size` para cada alimento o solo cuando sea evidente? Afecta al prompt y a la
  métrica de evals.
- Tamaño del dataset de evals (recomendado: 30 fotos) y quién toma las fotos (deben ser propias o con
  licencia; nunca fotos de terceros sin permiso).
- Modelo y costo por imagen en Vertex: POR VERIFICAR con el subagente `researcher` antes de fijarlos.

## Definition of Done
- AC1–AC8 con evidencia · analyze, tests y evals sin regresión · reviewer PASS enlazado ·
  `docs/privacy.md`, política y arquitectura actualizados · aprobación de la usuaria antes de
  fusionar (Strict).

## Change Log
- 2026-10-04: creación a partir de F2 y de la decisión 6 del rediseño.

## Review
Informe del reviewer: pendiente.
