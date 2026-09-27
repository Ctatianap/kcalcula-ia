---
name: ai-pipeline
description: Procedimiento para cambiar cualquier parte de la capa de IA en functions/src/ai/ - prompts, esquemas de entrada y salida (zod), adaptadores de proveedor (Vertex/Gemini, fake) - y para ejecutar evals y compararlas con el baseline. Úsala siempre que una tarea toque prompts, esquemas, modelos o parámetros de IA. Siempre es Strict Path.
---

# SKILL: ai-pipeline

## Purpose
Cambiar la capa de IA de forma medible y reversible, sin romper la invariante "la IA estructura,
nunca calcula".

## When to use
Cambios en `functions/src/ai/**`, en el modelo o sus parámetros, o en `evals/`.

## Estructura
```
functions/src/ai/
  provider.ts                 interfaz AiProvider (parseMeal, extractLabel)
  vertex.ts                   adaptador Gemini vía Vertex AI
  fake.ts                     adaptador determinista para tests (fixtures)
  schemas.ts                  esquemas zod versionados (parsed_meal.v1, label_extraction.v1)
  prompts/parse_meal.v1.md    prompts inmutables una vez usados
evals/
  datasets/                   casos de prueba (jsonl) e imágenes de etiquetas
  baselines/                  resultados de referencia por versión de prompt y modelo
```

## Reglas
1. **Prompts inmutables**: para cambiar un prompt crea `vN+1`; no edites uno ya evaluado.
2. **Esquemas versionados**: cambiar forma = nueva versión (`parsed_meal.v2`) y adaptación en la app.
3. `parsed_meal.*` **no puede tener** campos de nutrientes ni de calorías. `additionalProperties: false`.
4. `label_extraction.*` solo transcribe valores impresos y marca `unreadable_fields`; nunca completa
   valores faltantes.
5. La salida del modelo se valida siempre con zod. Si no es válida: un reintento; si falla de nuevo,
   se devuelve el error `ai-invalid-output`. Nunca se repara con heurísticas silenciosas.
6. Logs: solo `requestId`, versión de prompt, modelo, latencia, tokens, validez y código de error.
   Nunca el texto ni la imagen.
7. El modelo y la región vienen de configuración, no del código. Identificadores de modelo: POR VERIFICAR
   con el subagente `researcher` antes de fijarlos.

## Procedure
1. Crea la nueva versión del prompt o esquema; no modifiques la anterior.
2. Actualiza o añade fixtures en `fake.ts` y tests unitarios (validación, reintento, error).
3. `npm --prefix functions run build && npm --prefix functions test`.
4. Evals contra el emulador con el proveedor real:
   `npm --prefix functions run evals -- --dataset <archivo> --prompt <versión>` (se crea en la SPEC de evals;
   antes de eso, usa el smoke test de SPEC-001).
5. Compara con `evals/baselines/`. Métricas: validez de esquema (debe ser 100 %), detección de
   alimentos, extracción de cantidad y unidad, latencia p50/p95 y tokens promedio.
6. Guarda el resultado como nuevo baseline solo si el usuario aprueba el cambio.
7. Si cambia lo que se envía al proveedor: actualiza `docs/privacy.md`.

## Validation
- [ ] Versión nueva, la anterior intacta.
- [ ] Esquema sin campos nutricionales (en parse).
- [ ] Tests con el proveedor fake verdes.
- [ ] Evals sin regresión frente al baseline o regresión aceptada explícitamente por el usuario.
- [ ] Logs sin contenido del usuario.

## Output
Cambio versionado, reporte de evals comparativo en la SPEC o en la descripción del cambio.

## Failure conditions
- Validez de esquema < 100 % en evals → no fusionar.
- La mejora depende de que el modelo "estime calorías" → rechazar: viola la invariante 1.
