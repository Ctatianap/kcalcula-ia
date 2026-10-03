# Backlog inicial — Calorías IA

Ordenado por dependencias. Las SPEC se crean con la skill `write-spec` cuando llega su turno
(salvo SPEC-001, que ya existe).

Seguimiento de avance (para la skill `loop-impl`): las tareas con `spec_required: false` llevan
su propio campo `status` aquí (`done` | sin campo = pendiente). Las tareas con `spec_required: true`
no repiten el estado aquí — su SPEC vinculada (comentario `# specs/SPEC-NNN-*.md`) es la única fuente
de verdad de su `Status` (Draft/Approved/Implementing/Review/Done).

```yaml
- id: T-000
  title: Preparar repositorio y entorno
  objective: >
    Estructura base funcionando: app Flutter vacía que compila, paquete nutrition_core con un test,
    functions TypeScript con un test, emulador de Functions arrancando, git inicializado.
  dependencies: []
  spec_required: false   # Fast Path con checklist; el usuario hace los pasos de consola
  assigned_agent: sesión principal + usuario
  status: done
  acceptance_summary: >
    `flutter analyze`, `dart test` (nutrition_core) y `npm --prefix functions test` pasan;
    `firebase emulators:start --only functions` arranca; los comandos de CLAUDE.md existen.

- id: T-001
  title: Resolver verificaciones que bloquean SPEC-001
  objective: >
    Resolver PV-01, PV-02, PV-03 y PV-04 de docs/research/POR-VERIFICAR.md
    (licencia y formato TCAC, modelo Gemini y región, retención de datos de Vertex, región de Functions).
  dependencies: []
  spec_required: false
  assigned_agent: researcher
  status: done
  acceptance_summary: Notas en docs/research/ con fuentes; ítems actualizados.

- id: T-002
  title: SPEC-001 — Registro por texto de extremo a extremo (vertical slice)
  objective: texto → parseMeal → resolución → cálculo → revisión → registro → diario
  dependencies: [T-000, T-001]
  spec_required: true    # specs/SPEC-001-registro-por-texto.md (Done — reviewer PASS; AC11 corrido contra Vertex real el 2026-10-02)
  assigned_agent: sesión principal → reviewer
  acceptance_summary: Ver AC1–AC12 de SPEC-001.

- id: T-003
  title: Entrada por voz
  objective: Micrófono → STT del sistema operativo (es-CO) → mismo pipeline que el texto; medir calidad (PV-05).
  dependencies: [T-002]
  spec_required: true    # specs/SPEC-002-entrada-por-voz.md (Done — reviewer PASS; AC8 medido en Android, iOS pendiente aceptado)
  assigned_agent: sesión principal → reviewer
  acceptance_summary: Transcripción editable antes de enviar; permisos de micrófono manejados; fallback a texto.

- id: T-004
  title: Catálogo completo (Strict)
  objective: Pipeline TCAC + FDC + sinónimos es-CO + porciones domésticas con fuentes; cobertura de ~200 alimentos frecuentes.
  dependencies: [T-001, T-002]
  spec_required: true    # specs/SPEC-003-catalogo-completo.md (Done — reviewer PASS)
  assigned_agent: sesión principal (skill nutrition-data) → reviewer
  acceptance_summary: Build reproducible, validaciones del catálogo verdes, reporte de cobertura.

- id: T-005
  title: Foto de tabla nutricional (Strict)
  objective: extractLabel + validación Atwater + confirmación + cantidad consumida + producto personal reutilizable.
  dependencies: [T-002]
  spec_required: true    # specs/SPEC-004-foto-de-etiqueta.md (Done — reviewer PASS)
  assigned_agent: sesión principal (skill ai-pipeline) → reviewer
  acceptance_summary: "30 g = 140 kcal; comí 45 g → 210 kcal" y confianza Alta precisión.

- id: T-006
  title: Evals de IA (Strict)
  objective: Dataset de ~50 frases colombianas y ~20 etiquetas reales, runner, métricas y baseline.
  dependencies: [T-002, T-005]
  spec_required: true    # specs/SPEC-005-evals-de-ia.md (Done — reviewer PASS)
  assigned_agent: sesión principal (skill ai-pipeline) → reviewer
  acceptance_summary: Reporte reproducible; validez de esquema 100 %; umbrales fijados tras el baseline.

- id: T-007
  title: Privacidad y consentimiento (Strict)
  objective: Onboarding con consentimiento, declaración de edad, borrar todo, exportar, borrador de política.
  dependencies: [T-002]
  spec_required: true    # specs/SPEC-006-privacidad-consentimiento.md (Done — reviewer PASS)
  assigned_agent: sesión principal → reviewer; revisión legal humana
  acceptance_summary: No se puede usar la IA sin consentimiento; borrar todo deja user.db vacío.

- id: T-008
  title: Endurecimiento para beta
  objective: App Check con proveedores reales, alertas de presupuesto, maxInstances, estados de error, decisión sobre reporte de fallos.
  dependencies: [T-003, T-004, T-005, T-006, T-007]
  spec_required: true    # specs/SPEC-007-endurecimiento-beta.md (Done — reviewer PASS)
  assigned_agent: sesión principal → reviewer
  acceptance_summary: Checklist de beta completo; despliegue con confirmación humana.

# Post-MVP (fases del documento de producto)
- id: T-009
  title: Objetivos nutricionales configurables
  dependencies: [T-002]
  spec_required: true    # specs/SPEC-008-objetivos-nutricionales.md (Done — reviewer PASS; perfil, mantenimiento y objetivo)
- id: T-010
  title: Errores de almacenamiento sin datos del usuario en Crashlytics
  objective: >
    El guardado de comidas (review) y de productos personales no captura los fallos de user.db;
    el texto de SqliteException incluye los parámetros (alimentos, cantidades) y llegaría a
    Crashlytics vía PlatformDispatcher.onError. Capturar, mostrar mensaje en español y no relanzar,
    o filtrar SqliteException en el crash reporter. Hallazgo del reviewer en SPEC-008.
  dependencies: [T-008]
  spec_required: true
- id: F2
  title: Fase 2 — foto del plato, comidas frecuentes, confianza visual
- id: F3
  title: Fase 3 — corrección conversacional, marcas, historial avanzado
- id: F4
  title: Fase 4 — Samsung Health y ecosistemas de salud (requiere investigación previa)
- id: F5
  title: Fase 5 — análisis, tendencias, reportes
```
