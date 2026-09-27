# SPEC-001: Registro de una comida por texto, de extremo a extremo

## Status
Draft
Path: Strict (crea `nutrition_core`, el primer prompt y esquema de IA, el catálogo semilla y el primer dato que sale del dispositivo)

## Objective
Validar la arquitectura completa con el flujo más pequeño útil: el usuario escribe lo que comió, ve
los alimentos con cantidades, kcal y confianza, corrige si hace falta, registra, y lo ve en el
diario de hoy.

## Context
Vertical slice de `docs/backlog.md` (T-002). Aplica ADR-001 (D1, D2, D5, D6, D7) y
`docs/architecture.md`. La voz (T-003) reutilizará este pipeline sin cambios.

## User Story
Como persona que quiere registrar lo que come, quiero escribir "dos huevos revueltos y una arepa
pequeña con queso" y confirmar el resultado con un toque, para registrar mi comida en segundos
sin buscar alimentos uno por uno.

## Requirements
- R1. Pantalla de captura "¿Qué comiste?" con campo de texto (1–500 caracteres) y botón Analizar.
- R2. La app llama a la función callable `parseMeal` con `{ text, locale: "es-CO" }` a través de
  `infra/ai_client`, con App Check (proveedor de depuración en desarrollo).
- R3. `parseMeal` valida la entrada, usa el prompt `parse_meal.v1`, llama a `AiProvider` (Vertex/Gemini;
  modelo y región por configuración, según PV-02 y PV-04), valida la salida contra `parsed_meal.v1`
  con zod, reintenta una vez si es inválida y si no devuelve `ai-invalid-output`. Timeout de 10 s.
- R4. Esquema `parsed_meal.v1` (`additionalProperties: false` en todos los niveles):
  ```json
  {
    "schema_version": "parsed_meal.v1",
    "meal_type": "desayuno | almuerzo | cena | snack | null",
    "items": [{
      "mention": "string — fragmento literal del texto",
      "food_query": "string — nombre canónico en español",
      "quantity": "number | null",
      "unit": "g | ml | unidad | cucharada | cucharadita | taza | vaso | porcion | null",
      "size": "pequeno | mediano | grande | null",
      "preparation": "string | null",
      "is_vague": "boolean",
      "parent_index": "integer | null — índice del ítem al que se añade (aceite del huevo)"
    }]
  }
  ```
  Sin campos de calorías ni nutrientes (invariante 1).
- R5. `AiProvider` es una interfaz con dos implementaciones: `vertex` y `fake` (fixtures deterministas para tests).
- R6. Logs del backend solo con `requestId`, versión de prompt, modelo, latencia, tokens, validez y código de error.
- R7. Catálogo semilla: ~30 alimentos frecuentes (huevo, arepa, queso campesino, arroz blanco cocido,
  pechuga de pollo, aguacate, plátano maduro, papa, pan, café, leche entera, aceite vegetal, aceite de
  oliva, mantequilla, azúcar, manzana, banano, frijol, lenteja, carne de res, etc.) generado por
  `data/build_catalog` desde `data/curated/*.csv`, con sinónimos, porciones y unidades domésticas,
  siguiendo la skill `nutrition-data`. Valores importados de USDA FDC o transcritos de la TCAC con
  `source_ref` por fila; filas TCAC con `license_status = pending` si PV-01 no está resuelto.
- R8. Resolución de alimentos en el dispositivo con FTS5 sobre nombre y sinónimos: `matched`,
  `ambiguous` (≤ 3 candidatos) o `not_found`, según `docs/architecture.md`.
- R9. `nutrition_core` implementa: resolución de gramos por `quantity_basis`, cálculo por 100 g,
  confianza por ítem y por comida, y redondeo solo al presentar, exactamente como en `docs/architecture.md`.
- R10. Pantalla de revisión: por ítem, nombre, cantidad y gramos editables (botones −/+ y campo
  numérico), kcal, insignia de confianza, y total de la comida. Los ítems `ambiguous` muestran
  chips de candidatos; los `not_found` muestran "No encontrado" y un botón para quitarlos.
  Registrar está deshabilitado mientras haya ítems `ambiguous` o `not_found`.
- R11. Al registrar se guarda en `user.db` (Drift) la comida con una instantánea de los valores por
  ítem, `quantity_basis`, confianza y `catalog_version`.
- R12. Pantalla "Hoy": comidas agrupadas por tipo con kcal por comida, total de kcal y proteína,
  carbohidratos y grasa del día. Si `meal_type` es null, se asigna por hora local
  (05–10 desayuno, 11–15 almuerzo, 18–22 cena, resto snack) y es editable en la revisión.

## Acceptance Criteria
- AC1. Con el proveedor `fake` y el catálogo semilla, "dos huevos y una arepa" → la revisión muestra
  2 ítems con kcal iguales al cálculo de `nutrition_core` sobre los valores del catálogo `[integration]`.
- AC2. `parseMeal` con texto vacío o > 500 caracteres → error `invalid-argument` sin llamar al proveedor `[unit]`.
- AC3. Una salida del proveedor con un campo extra (por ejemplo `"kcal": 150`) → validación fallida,
  un reintento, y luego `ai-invalid-output` `[unit]`.
- AC4. Cálculo: alimento con 165 kcal/100 g y 150 g → 247,5 kcal internas, se muestra "248";
  el total de la comida se suma sobre valores sin redondear `[unit]`.
- AC5. Confianza por ítem: "150 g de pechuga" → Buena estimación; "2 huevos" (porción `unidad` con
  fuente) → Buena estimación; "arepa pequeña" → Estimación; "un poquito de queso" → Estimación con
  porción por defecto destacada `[unit]`.
- AC6. Confianza por comida: un ítem Estimación que aporta < 15 % de las kcal no baja el nivel de la
  comida; uno que aporta ≥ 15 % sí `[unit]`.
- AC7. Un ítem `ambiguous` muestra ≤ 3 candidatos y Registrar queda deshabilitado hasta elegir `[widget]`.
- AC8. Cambiar una cantidad con −/+ actualiza las kcal del ítem y el total sin llamadas de red `[widget]`.
- AC9. Tras Registrar, la comida aparece en "Hoy" con sus totales y persiste tras reiniciar la app `[integration]`.
- AC10. Los logs de `parseMeal` no contienen el texto de entrada (test sobre el logger) `[unit]`.
- AC11. Con Vertex real en el emulador, las 10 frases de `evals/datasets/slice_smoke.jsonl` producen
  salida válida contra el esquema 10/10, y la frase sin comida devuelve `items: []`. Se registran la
  latencia p50 y los alimentos detectados frente a `expected_foods` `[eval]` (manual o script).
- AC12. El reviewer compara 5 filas al azar del catálogo semilla contra su fuente citada y coinciden `[manual]`.

## Technical Constraints
- Invariantes 1, 3, 4, 5, 7, 8 y 9 de `CLAUDE.md`.
- `nutrition_core` no depende de Flutter ni de red. La UI no accede a Drift ni a Functions directamente.
- Modelo, región y parámetros de Vertex por configuración; ningún secreto en el repo (ADC en local).

## Components / Files Affected
`packages/nutrition_core/` · `app/lib/features/{capture,review,diary}/` · `app/lib/infra/{ai_client,catalog,storage}/`
· `functions/src/{index.ts, ai/provider.ts, ai/vertex.ts, ai/fake.ts, ai/schemas.ts, ai/prompts/parse_meal.v1.md}`
· `data/curated/*.csv` · `data/build_catalog/` · `data/SOURCES.md` · `app/assets/catalog/catalog.db` (generado)

## Dependencies
- T-000 (entorno), T-001 (PV-01 a PV-04 resueltos o con decisión explícita del usuario).
- Proyecto de Firebase con Vertex AI habilitado y `gcloud auth application-default login` hecho por el usuario.

## Edge Cases
- Texto sin comida ("hola, ¿cómo estás?") → "No encontré alimentos en lo que escribiste".
- Números en palabras y fracciones: "dos", "media taza", "un cuarto".
- Ingredientes añadidos ("revueltos con aceite") → ítem separado con `parent_index`.
- Alimento repetido en la misma frase → ítems separados, sin fusión automática.
- Unidad en ml sin densidad → 1 g/ml y confianza Estimación.
- Sin red o timeout → mensaje con reintento; el texto escrito se conserva.
- Cantidad editada a 0 → se pide quitar el ítem en lugar de registrar 0 g.

## Security & Privacy
- Sale del dispositivo: el texto de la comida → Cloud Function → Vertex AI. Ya está en
  `docs/privacy.md`; confirmar la fila con el resultado de PV-03.
- El consentimiento formal llega en T-007; hasta entonces el uso es solo de desarrollo.
- App Check aplicado en el emulador con el proveedor de depuración; límites de entrada; sin logs de contenido.

## Tests Required
- Unit (`nutrition_core`): gramos por cada `quantity_basis`, cálculo, redondeo, confianza por ítem y por comida.
- Unit (`functions`): validación de entrada, esquema, reintento, error, logs sin contenido (proveedor `fake`).
- Unit (build del catálogo): validaciones de la skill `nutrition-data`.
- Widget: revisión (ambiguos, edición, Registrar deshabilitado).
- Integration: captura → revisión → registro → Hoy, con `fake` y base en memoria; persistencia.
- Eval: smoke de AC11.
- Manual: flujo completo en un dispositivo Android contra el emulador de Functions.

## Out of Scope
Voz, etiquetas, foto del plato, editar comidas ya registradas, borrar comidas, objetivos,
comidas frecuentes, consentimiento y onboarding, despliegue a producción, catálogo completo.

## Open Questions
- ¿Nombre visible de la app? (No bloquea; se usa "Calorías IA" provisionalmente.)

## Definition of Done
- AC1–AC12 con evidencia enlazada en esta SPEC.
- `flutter analyze`, `dart analyze` y todos los tests verdes.
- Reviewer: PASS enlazado.
- `docs/architecture.md` y `docs/privacy.md` coherentes con lo implementado.
- Baseline inicial del smoke guardado en `evals/baselines/`.

## Change Log
- 2026-09-27: creación (VPF).

## Review
Informe del reviewer:
