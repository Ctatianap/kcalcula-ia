---
name: write-spec
description: Crea o actualiza una SPEC verificable en specs/ a partir de una tarea o idea del usuario. Úsala para toda funcionalidad, cambio de comportamiento, integración, migración o bug complejo (Standard y Strict Path), y cuando una SPEC existente necesite cambios por una contradicción descubierta al implementar.
---

# SKILL: write-spec

## Purpose
Convertir intención en un contrato implementable y verificable antes de escribir código.

## When to use
- Tarea clasificada como Standard o Strict Path.
- La implementación reveló una contradicción o hueco en una SPEC.
No la uses para Fast Path.

## Inputs
- Descripción de la tarea (del usuario o de `docs/backlog.md`).
- `specs/_TEMPLATE.md`, `docs/architecture.md`, `docs/privacy.md`, SPECs relacionadas.

## Procedure
1. Determina el path. Es **Strict** si toca `nutrition_core`, prompts o esquemas de IA, el catálogo
   nutricional o datos que salen del dispositivo.
2. Siguiente ID: el número más alto en `specs/` + 1. Archivo: `specs/SPEC-NNN-slug-en-espanol.md`.
3. Copia `specs/_TEMPLATE.md` y complétalo. Reglas:
   - **Requisitos** numerados (R1…), uno por comportamiento.
   - **Criterios de aceptación** (AC1…) observables: entrada concreta → resultado concreto.
     Cada AC indica cómo se verifica: `[unit]`, `[widget]`, `[integration]`, `[eval]` o `[manual]`.
     Prohibido: "funciona bien", "rápido", "intuitivo" sin métrica o comportamiento observable.
   - **Edge cases**: entrada vacía, sin red, timeout del proveedor, respuesta inválida de IA,
     cantidades vagas, alimento no encontrado, lo que aplique.
   - **Seguridad y privacidad**: qué datos salen del dispositivo (si cambia, Strict + `docs/privacy.md`).
   - **Out of Scope** explícito para frenar la expansión del alcance.
   - Si falta información que cambia el diseño, déjala en `Open Questions`; no la inventes.
4. Status: `Draft`. Presenta al usuario un resumen: objetivo, requisitos, AC y preguntas abiertas.
5. Espera. Solo el usuario cambia el Status a `Approved`.

Para modificar una SPEC aprobada: edita, añade una línea en `Change Log` (fecha, qué cambió, por qué),
vuelve a `Draft` y pide aprobación.

## Validation
- [ ] Cada requisito está cubierto por al menos un AC.
- [ ] Cada AC es verificable y tiene tipo de verificación.
- [ ] Hay edge cases y Out of Scope.
- [ ] Definition of Done observable.
- [ ] Ningún AC depende de valores nutricionales generados por IA.

## Output
Archivo de SPEC en `Draft` y un resumen en chat con las preguntas abiertas.

## Failure conditions
- La tarea tiene interpretaciones materialmente distintas → pregunta antes de escribir.
- La tarea contradice una invariante de `CLAUDE.md` → detente y explícalo al usuario.
