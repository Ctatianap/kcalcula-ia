# ENVIRONMENT ADAPTER: Claude Code

El Core Project (arquitectura, specs, responsabilidades, workflow) es independiente del entorno.
Este archivo traduce ese core a Claude Code. Si cambias de entorno, reemplaza solo lo que está aquí.

## Supported capabilities
| Capacidad | Uso en este proyecto |
|---|---|
| `CLAUDE.md` (se carga en cada sesión) | Instrucciones maestras: invariantes, workflow, comandos |
| Subagentes (`.claude/agents/*.md`, contexto aislado) | `reviewer`, `researcher` |
| Skills (`.claude/skills/<nombre>/SKILL.md`, carga bajo demanda) | `write-spec`, `nutrition-data`, `ai-pipeline` |
| Hooks (deterministas, en `.claude/settings.json`) | Bloqueo de comandos destructivos y secretos; confirmación para deploy/push/gcloud; formateo de Dart |
| Permisos (`allow` / `ask` / `deny`) | Comandos de test sin fricción; secretos denegados |
| Terminal, filesystem, git, web | Nativos |
| MCP | No se usa ninguno obligatorio (ver Tool map) |

## Project instructions location
`CLAUDE.md` en la raíz, versionado. Preferencias personales: `CLAUDE.local.md` (ignorado por git).

## Agent implementation
- Sesión principal = orquestador + spec + implementación (guiada por `CLAUDE.md`).
- `.claude/agents/reviewer.md`: tools `Read, Grep, Glob, Bash` (Bash solo para git de lectura, analyze y tests).
- `.claude/agents/researcher.md`: tools `WebSearch, WebFetch, Read, Write, Glob, Grep` (Write solo en `docs/research/`).
- Invocación explícita recomendada: "Usa el subagente reviewer sobre specs/SPEC-001-… en la rama spec-001-…".

## Skill implementation
Un directorio por skill con `SKILL.md` (frontmatter `name` y `description`). La descripción determina
cuándo se activa; si una skill no se activa cuando debe, mejora su `description`.

## Tool/MCP configuration
| Necesidad | Solución | Tipo | Prioridad | Consumidor |
|---|---|---|---|---|
| Build, test, analyze | `flutter`, `dart` | CLI | OBLIGATORIO | principal, reviewer |
| Control de versiones | `git` | CLI | OBLIGATORIO | principal, reviewer (lectura) |
| Backend local y despliegue | Firebase CLI + Emulator Suite | CLI | OBLIGATORIO | principal (deploy con confirmación) |
| Credenciales locales de Vertex | `gcloud auth application-default login` (lo ejecuta el usuario) | CLI | OBLIGATORIO | usuario |
| Verificación externa | WebSearch / WebFetch | Nativa | RECOMENDADO | researcher |
| PRs e issues | `gh` | CLI | OPCIONAL | principal |
| MCP de Dart/Flutter y de Firebase | POR VERIFICAR (PV-10) | MCP | OPCIONAL | principal |

## Persistence
La fuente de verdad está en el repo: specs, ADRs, `docs/`. Nada importante vive solo en el chat.
Al terminar cada tarea, la sesión cierra con el bloque de handoff de `CLAUDE.md`.

## Recommended project files
`CLAUDE.md`, `.claude/settings.json`, `.claude/hooks/*.mjs`, `.claude/agents/*.md`, `.claude/skills/*/SKILL.md`.

## Workflow differences
- Usa el modo de planificación de Claude Code para tareas Standard y Strict antes de editar.
- Una sesión por SPEC; `/clear` entre SPECs para no arrastrar contexto.
- El reviewer se invoca antes de cerrar; su informe se enlaza en la SPEC.

## Installation/configuration
1. Instala Claude Code según la documentación oficial (método de instalación vigente: POR VERIFICAR en la doc).
2. Node.js disponible en el PATH: los hooks se ejecutan con `node` (también lo requiere Firebase CLI).
3. Abre Claude Code en la raíz del repo; ejecuta `/permissions` y `/hooks` para confirmar que se cargaron (PV-09).
4. Prueba los hooks: pide `rm -r build` (debe bloquearse) y `firebase deploy` (debe pedir confirmación).

## Limitations
- Los hooks por coincidencia de texto se pueden eludir (variables, alias, scripts). Son una defensa
  adicional junto a las reglas `deny`, no una garantía absoluta.
- Los subagentes no ven la conversación principal: pásales rutas y contexto explícitos.
- Las skills se activan por juicio del modelo; en Strict Path, nómbralas explícitamente.
