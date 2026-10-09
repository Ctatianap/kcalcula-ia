# Evals de IA — Calorías IA (SPEC-005)

Mide qué tan bien `parseMeal` y `extractLabel` cumplen su esquema (`parsed_meal.v1` /
`label_extraction.v1`) contra datasets reales, sin cambiar los prompts. Evaluar no es lo mismo que
modificar: si un resultado sugiere que un prompt necesita ajustarse, eso es una SPEC futura
(`vN+1`, skill `ai-pipeline`), no este runner.

## Datasets

- `datasets/parse_meal.v1.jsonl` — 50 frases en español colombiano, cada una con `expected_items`
  (alimento, cantidad, unidad esperados por ítem). Los primeros 10 casos (s01-s10) son también las
  fixtures deterministas de `functions/src/ai/fake.ts`.
- `datasets/extract_label.v1/` — 47 fotos reales de etiquetas nutricionales colombianas
  (`images/*.jpg`) + `cases.jsonl` con la transcripción humana de cada una (`expected`) y qué
  campos ni una persona pudo leer con confianza (`human_unreadable_fields` — esos campos no se
  puntúan, comparar la IA contra un dato que un humano tampoco pudo confirmar no sería justo).

## Correr un eval

Sin costo (proveedor `fake`, solo valida el mecanismo — el fake no tiene fixtures para todas las
frases, así que su "detección de alimentos" es baja a propósito, no es un baseline real):
```
cd functions && AI_PROVIDER=fake npm run evals:parse-meal
```

Con el modelo local (gratis, ver `docs/decisions/ADR-002-ia-local-vs-vertex.md` — requiere
`ollama serve` corriendo y `ollama pull gemma4:e4b` ya hecho):
```
cd functions && AI_PROVIDER=ollama OLLAMA_MODEL=gemma4:e4b npm run evals:parse-meal -- --save
cd functions && AI_PROVIDER=ollama OLLAMA_MODEL=gemma4:e4b npm run evals:extract-label -- --save
```

Con Vertex AI real (**cuesta dinero real** — solo para cuando exista un proyecto GCP con Vertex AI
habilitado y `gcloud auth application-default login` ya hecho):
```
cd functions && AI_PROVIDER=vertex VERTEX_PROJECT_ID=<proyecto real> npm run evals:parse-meal -- --save
cd functions && AI_PROVIDER=vertex VERTEX_PROJECT_ID=<proyecto real> npm run evals:extract-label -- --save
```

`--save` guarda el reporte en `baselines/<dataset>__<proveedor>__<modelo>__<fecha>.json` — nunca
sobrescribe un baseline anterior (queda uno por corrida). Sin `--save`, el reporte solo se imprime.

## Cómo leer el reporte

- `schemaValidRate`: % de respuestas que pasaron la validación zod (`parsed_meal.v1` /
  `label_extraction.v1`). Debe ser 100% salvo error real del proveedor.
- `parse_meal` — `foodDetectionRate`: de los alimentos que el dataset esperaba, cuántos aparecen en
  la respuesta (emparejado por nombre normalizado, ver `results[].itemsFound` vs. `expectedFoods`
  para revisar caso por caso — el emparejamiento automático es aproximado, no exacto).
  `quantityUnitAccuracy`: de los alimentos sí detectados, en cuántos la cantidad y unidad
  coinciden exactamente con lo esperado.
- `extract_label` — `fieldAccuracy`: de los campos que sí se pudieron puntuar (excluye
  `human_unreadable_fields` de cada caso), cuántos coinciden con la transcripción humana.
  `hallucinatedFields`: casos donde la etiqueta NO imprimía un valor (esperado `null`) y la IA
  devolvió uno de todos modos — esto es exactamente lo que prohíben los invariantes 1/2 de
  `CLAUDE.md`; si este número no es 0, es una señal seria, no solo una métrica de precisión.
- `latencyP50Ms`/`latencyP95Ms`: tiempo de respuesta del proveedor.
- `results`: tabla completa caso por caso — siempre revisar esto además del resumen agregado, el
  emparejamiento automático puede fallar en casos límite (ver Edge Cases de SPEC-005).

## Umbrales de aceptación

No se fijan de antemano. Se corre el baseline, se documenta el resultado real en la SPEC
correspondiente, y el usuario decide el umbral con ese número delante (SPEC-005, R6).

## Reemplaza a

`run_smoke.ts` / `slice_smoke.jsonl` (SPEC-001) — mismos 10 casos base, ampliado a 50 con más
métricas y soporte para los 3 proveedores en vez de solo Vertex.
