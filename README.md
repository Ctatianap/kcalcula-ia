# Calorías IA

App móvil (Flutter, iOS/Android) para registrar lo que comes hablando, escribiendo o fotografiando
la tabla nutricional. La IA interpreta; los números salen de fuentes nutricionales y de un cálculo
reproducible. Mercado inicial: Colombia. Datos del usuario solo en el dispositivo.

## Mapa del repo
| Ruta | Qué es |
|---|---|
| `CLAUDE.md` | Instrucciones maestras para Claude Code (invariantes, workflow, comandos) |
| `.claude/` | Subagentes, skills, hooks y permisos |
| `docs/architecture.md` | Componentes, flujos, reglas de confianza y cálculo |
| `docs/decisions/` | ADRs |
| `docs/privacy.md` | Qué datos salen del dispositivo y controles |
| `docs/backlog.md` | Backlog ordenado por dependencias |
| `docs/research/` | Ítems POR VERIFICAR y notas de investigación |
| `docs/environment-adapter.md` | Cómo se traduce el proyecto a Claude Code |
| `specs/` | SPECs (fuente de verdad de cada cambio) |
| `evals/` | Datasets y resultados de evaluación de IA |

## Prerrequisitos (los instalas tú)
Flutter SDK (canal estable), Node.js LTS, Firebase CLI, Google Cloud CLI (`gcloud`), git,
Claude Code, y un dispositivo o emulador Android (y Xcode si desarrollas en iOS).
Cuenta de Firebase con plan de pago por uso (necesario para Cloud Functions y Vertex AI) y alertas
de presupuesto activadas.

## Primeros pasos
1. Crea una carpeta vacía, copia dentro el contenido de este paquete y ejecuta `git init`.
2. Abre Claude Code en la raíz y pega la primera instrucción del final de la Factory (T-000 + T-001).
3. Revisa y aprueba `specs/SPEC-001-registro-por-texto.md` (cambia su Status a `Approved`).
4. Pide la implementación de SPEC-001.

## Primera instrucción para Claude Code
```text
Lee CLAUDE.md, README.md, docs/architecture.md y docs/backlog.md.

Ejecuta T-000 como Fast Path: crea la app Flutter en app/ (Android e iOS), el paquete Dart puro
packages/nutrition_core con un test mínimo, y functions/ en TypeScript con un test mínimo.
Enlaza nutrition_core a la app como dependencia de ruta. Verifica las versiones estables actuales
de lo que instales.

Todo paso que requiera consolas de Firebase o Google Cloud, cuentas, facturación o comandos
interactivos (crear el proyecto, plan de pago, habilitar Vertex AI, firebase init,
flutterfire configure, gcloud auth application-default login, token de depuración de App Check)
dámelo como checklist numerada y espera mi confirmación.

En paralelo, usa el subagente researcher para resolver PV-01 a PV-04 de
docs/research/POR-VERIFICAR.md.

No empieces SPEC-001. Al terminar, dame el handoff y un resumen de las verificaciones que
cambien algo en SPEC-001.
```
