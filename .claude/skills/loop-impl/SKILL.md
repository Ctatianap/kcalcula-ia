---
name: loop-impl
description: Avanza docs/backlog.md una tarea a la vez siguiendo exactamente el workflow de CLAUDE.md (Fast/Standard/Strict Path). Fast Path se implementa directo; Standard/Strict se draftea con la skill write-spec y SIEMPRE se detiene a esperar la aprobación explícita del usuario — nunca la salta, ni siquiera en modo autónomo o dentro de /loop. Úsala para retomar el backlog sin tener que re-explicar el proyecto cada vez.
---

# SKILL: loop-impl

## Purpose
Que avanzar el backlog no dependa de que el usuario re-describa cada tarea: cada invocación
retoma exactamente donde quedó la anterior, respetando los mismos gates de aprobación que ya
exige CLAUDE.md.

## Inputs
- `docs/backlog.md` (orden y dependencias).
- Para tareas con `spec_required: true`: la SPEC vinculada (comentario `# specs/SPEC-NNN-*.md`
  en la línea `spec_required` de esa tarea) — su `Status` es la única fuente de verdad de avance.
  Para tareas con `spec_required: false`: el campo `status: done` en la propia tarea.

## Procedure

1. **Elige la tarea.** Lee `docs/backlog.md` en orden. Una tarea es candidata si:
   - No tiene `status: done` (Fast Path) ni una SPEC vinculada en `Status: Done` (Standard/Strict).
   - Todas sus `dependencies` sí están `done`.
   Toma la primera candidata en el orden del archivo. Si no hay ninguna (todo hecho, o todo
   bloqueado por dependencias o por una aprobación pendiente): repórtalo y detente — no hay nada
   que hacer en esta invocación.

2. **Fast Path** (`spec_required: false`):
   - Impleméntala directo: sin SPEC, analyze + tests de los paquetes tocados.
   - Marca `status: done` en su entrada de `docs/backlog.md` y commitea.
   - Continúa con la siguiente tarea candidata en la misma invocación.

3. **Standard/Strict** (`spec_required: true`) — según el estado de su SPEC:
   - **No existe todavía**: invoca la skill `write-spec` para crearla en `Draft`. Añade el
     comentario `# specs/SPEC-NNN-slug.md` en su línea de `docs/backlog.md`. Presenta el resumen
     al usuario (objetivo, requisitos, AC, preguntas abiertas) y **detente aquí**.
   - **`Draft`**: ya está esperando aprobación de una invocación anterior. Repórtalo y detente
     sin tocarla — no reintentes escribirla de nuevo.
   - **`Approved`**: cambia su `Status` a `Implementing` (esto sí puedes hacerlo tú) y empieza a
     implementar siguiendo sus Requirements/AC, usando las skills `nutrition-data`/`ai-pipeline`
     si aplica.
   - **`Implementing`**: continúa donde quedó — revisa su Change Log y los tests ya existentes
     antes de escribir código nuevo, para no repetir trabajo de una invocación anterior.
   - **`Review`**: falta cerrarla. Si el informe del reviewer ya está enlazado y fue `PASS` y no
     quedan AC pendientes por causas externas (como un proyecto de Firebase/GCP que el usuario
     aún no crea): pregúntale si la cierra a `Done` o la deja así. Si quedó `CHANGES_REQUESTED`:
     corrige los hallazgos y vuelve a invocar al subagente `reviewer`.
   - Al terminar de implementar (antes de invocar al reviewer): corre analyze + tests de todos
     los paquetes tocados.

4. **Reporta siempre** con el handoff yaml de CLAUDE.md, incluso si la invocación se detuvo
   esperando aprobación — di explícitamente qué falta y qué necesitas del usuario para continuar.

## Restricciones (no negociables, heredadas de CLAUDE.md — esta skill no las relaja nunca)
- Nunca marques una SPEC como `Approved`: solo el usuario. Ni siquiera si el usuario pidió
  explícitamente "avanza todo lo que puedas" — esa instrucción autoriza a implementar Fast Path
  y a redactar Drafts, no a aprobarlos.
- Nunca implementes una SPEC que no esté `Approved`.
- Una SPEC a la vez, en su propia rama `spec-NNN-slug`.
- `firebase deploy`, `git push` y `gcloud` con efecto real requieren confirmación humana explícita
  en esa invocación puntual — no asumas que una confirmación anterior sigue vigente.
- Si la implementación revela una contradicción o hueco en la SPEC: detente, propón el cambio
  en la SPEC y espera aprobación. No reinterpretes en silencio.

## Uso con /loop
- Invocación directa (`Skill(loop-impl)` o el atajo que tenga configurado el usuario): avanza un
  solo paso (una tarea Fast Path completa, o hasta el próximo punto de aprobación de una
  Standard/Strict).
- Envuelta en el skill genérico `loop` (p. ej. para que se reintente sola cada cierto tiempo):
  como cada Standard/Strict se detiene a esperar aprobación explícita, el loop nunca avanza una
  SPEC sin que el usuario responda — en la práctica, si queda esperando aprobación, la siguiente
  vuelta de `loop` vuelve a reportar "esperando tu aprobación de SPEC-NNN" en vez de reintentar
  la redacción o de implementar de todos modos.

## Output
Handoff yaml (formato de CLAUDE.md) al final de cada invocación, más:
- Si quedó esperando aprobación de una SPEC: su resumen y la pregunta exacta que necesita del usuario.
- Si completó una tarea Fast Path: qué se hizo, resultado de tests, commit.
- Si no había ninguna tarea candidata: por qué (todo hecho, o qué bloquea a cada una pendiente).

## Failure conditions
- Ambigüedad real sobre qué tarea sigue (p. ej. dos candidatas sin dependencias entre sí y sin
  orden claro en el archivo): pregunta al usuario cuál prefiere antes de elegir.
- Una SPEC `Approved` cuya implementación exige una decisión de producto no cubierta por sus
  Requirements: detente y pregunta, no la inventes.
