# SPEC-036: Buscar en el historial

## Status
Review
Path: Standard (búsqueda de solo lectura sobre comidas guardadas; no sale ningún dato)

## Objective
Encontrar los días en que la persona comió un alimento.

## Context
Separada de SPEC-026 (R5/AC5) a pedido de la usuaria (2026-10-08, "sí, confirmo las cuatro"). Decisión
ya tomada: no filtra por tipo de comida.

## User Story
Como persona que quiere saber cuándo comió arepa, quiero buscarlo en el historial.

## Requirements
- R1. Campo "Buscar en tus comidas" en Historial que lista los días con comidas que contienen ese
  alimento (por `name_snapshot`, normalizado como la búsqueda de SPEC-018), del más reciente al más
  antiguo, hasta 50. Tocar un día lo abre en el calendario.
- R2. Sin resultados: "No encontré comidas con ese alimento."
- R3. No filtra por tipo de comida.

## Acceptance Criteria
- AC1. Buscar "arepa" lista los días con arepa, del más reciente al más antiguo `[widget]`.
- AC2. Sin resultados → el mensaje de R2 `[widget]`.
- AC3. "Arepa" y "arepá" dan lo mismo (normalización) `[unit]`.

## Technical Constraints
- La UI pasa por `infra/storage`. Errores como SPEC-009.

## Components / Files Affected
- `app/lib/infra/storage/`, `app/lib/features/history/`.

## Dependencies
- SPEC-013, SPEC-018, SPEC-026.

## Edge Cases
- Menos de 2 letras: no busca.
- Más de 50 días: los 50 más recientes.

## Security & Privacy
- No sale ningún dato del dispositivo.

## Tests Required
- Unit: AC3. Widget: AC1, AC2. Manual: buscar en el teléfono.

## Out of Scope
- Filtrar por tipo de comida, rango de fechas.

## Open Questions
- Ninguna.

## Definition of Done
- AC1–AC3 con evidencia · analyze y tests verdes · reviewer PASS enlazado.

## Change Log
- 2026-10-08: creación al separar R5/AC5 de SPEC-026. Pendiente de aprobación de la usuaria.
- 2026-10-08: **Approved por la usuaria** ("aprobada la SPEC-036"). Status → Implementing.
- 2026-10-08: implementada. `StorageRepository.searchMealDays` (comparación normalizada en Dart, regla
  de 2 letras de SPEC-018, hasta 50 días); campo "Buscar en tus comidas" en Historial que reemplaza el
  calendario mientras hay búsqueda; tocar un día lo abre en el calendario.
- 2026-10-08: reviewer PASS; MINOR corregidos (ver Review). 442/442.
- 2026-10-08: prueba manual hecha en el teléfono (ver Verificación). Status → Review.

## Verificación
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/features/history/history_search_test.dart` › "AC1: días con arepa…" (repositorio: orden, sin repetir) y "AC1: buscar \"arepa\" lista los días y tocar uno lo abre en el calendario" (widget) |
| AC2 | ✅ | mismo archivo › "AC2: sin resultados, el mensaje" |
| AC3 | ✅ | mismo archivo › "AC3: \"Arepa\" y \"arepá\" dan lo mismo" |
| Edge | ✅ | "menos de 2 letras…" (repositorio y pantalla: "Escribe al menos 2 letras."), "hasta 50 días", "borrar la búsqueda vuelve al calendario", "cada palabra por prefijo, como SPEC-018" ("queso arepa" → "Arepa de queso"; "pa" no encuentra "Arepa") |
| Tests | ✅ | app: analyze sin avisos, 442/442. Único cambio en un test existente: `catalog_search_test.dart` quita un import que quedó redundante al mover `isSearchableQuery` a `format/text_es.dart` |
| Manual | ✅ | 2026-10-08, hecha por Claude en el Motorola de la usuaria (versión de `6b5dc09`, por pedido de ella): "huevo" → 8 y 7 de octubre en ese orden; tocar el 7 lo abre en el calendario (903 kcal), limpia la búsqueda y cierra el teclado; "pizza" → "No encontré comidas con ese alimento."; la ✕ vuelve al calendario; sin demora al escribir |

## Review
Revisión (2026-10-08, subagente `reviewer`, sobre `fb4c85f`): **PASS**. AC1–AC3 y bordes con evidencia;
join, orden y límite correctos; sin Drift en la UI ni imports entre features. 7 MINOR:
- Comparaba por subcadena y no como SPEC-018: ahora cada palabra por prefijo (`matchesWordPrefixes`);
  test.
- Regla de 2 letras duplicada: `isSearchableQuery` vive en `format/text_es.dart` y la reexporta el
  catálogo; la usan el repositorio y la pantalla.
- Sin debounce (lee todos los ítems en cada tecla): aceptable en local; se observa en la prueba manual.
- Error sin "Reintentar" ni `liveRegion`: agregados.
- El campo desaparecía mientras cargaba el mes: ahora está fuera del `FutureBuilder`.
- El teclado quedaba abierto al abrir un día: `unfocus()`.
- Prueba manual pendiente.
