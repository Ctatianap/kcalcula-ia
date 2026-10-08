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
  spec_required: true    # specs/SPEC-009-errores-de-almacenamiento.md (Done — reviewer PASS)
# Rediseño de la UI (diseño "kcalcula ia UI", lienzo https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD,
# revisado el 2026-10-03). Decisiones de la usuaria sobre los choques con lo ya aprobado ("de acuerdo con
# todo"): (1) se mantiene Harris-Benedict + escala de fitness (el texto "Mifflin-St Jeor" del diseño es un
# error del diseño); (2) se mantienen los 5 objetivos de SPEC-008; (3) sin rojo/verde de alarma: estados
# del día con tonos neutros o intensidad del mismo color; (4) el perfil conserva fecha de nacimiento y
# mantenimiento medido; (5) sin sugerencias de alimentos ("Un par de huevos…") en el MVP; (6) foto del
# plato = F2, como Estimación y con confirmación obligatoria.
- id: T-011
  title: Sistema visual y navegación
  objective: >
    Tema global del diseño (paleta, tipografía Outfit embebida, tarjetas, botones, anillos de progreso)
    y navegación inferior Hoy / Historial / Progreso con botón + para registrar.
  dependencies: [T-008]
  spec_required: true    # specs/SPEC-010-sistema-visual.md
- id: T-012
  title: Rediseño de "Hoy"
  objective: Semana con anillos por día, anillo de kcal, anillos de macros y tarjetas por comida.
  dependencies: [T-011, T-009]
  spec_required: true    # specs/SPEC-011-rediseno-hoy.md
- id: T-013
  title: Rediseño del flujo de registro
  objective: >
    ¿Qué comiste? con pestañas Foto/Texto/Voz; Analizando con pasos visibles y Cancelar; Detalle con
    tipo de comida y sello "Base verificada"; Error de la IA con consejos y Reintentar.
  dependencies: [T-011]
  spec_required: true    # specs/SPEC-012-rediseno-registro.md
- id: T-014
  title: Historial (calendario)
  objective: Calendario del mes con el estado de cada día frente a la meta y el detalle del día elegido.
  dependencies: [T-011, T-009]
  spec_required: true    # specs/SPEC-013-historial.md
- id: T-015
  title: Progreso
  objective: Promedios de kcal y macros por semana, mes y 3 meses; días en meta (cálculo en nutrition_core).
  dependencies: [T-011, T-009]
  spec_required: true    # specs/SPEC-014-progreso.md — Strict (nutrition_core)
- id: T-016
  title: Registro de peso y tendencia
  objective: Registrar el peso con historial y mostrar su tendencia en Progreso; el perfil usa el último.
  dependencies: [T-015]
  spec_required: true    # specs/SPEC-015-registro-de-peso.md — Strict (dato de salud nuevo con historial)
- id: T-017
  title: Exportar en CSV y PDF
  objective: Formatos CSV (hoja de cálculo) y PDF (resumen para la nutricionista), con filtro por periodo.
  dependencies: [T-011]
  spec_required: true    # specs/SPEC-016-exportar-csv-pdf.md — Strict (archivo que sale del teléfono por decisión del usuario)
- id: T-018
  title: Comidas recientes
  objective: Repetir una comida registrada antes desde "¿Qué comiste?" (parte de F2).
  dependencies: [T-013]
  spec_required: true    # specs/SPEC-017-comidas-recientes.md
- id: T-019
  title: Búsqueda manual en el catálogo
  objective: Buscar y añadir alimentos del catálogo sin IA (desde el error de la IA y "Añadir" ingrediente).
  dependencies: [T-013]
  spec_required: true    # specs/SPEC-018-busqueda-manual.md
- id: T-020
  title: Racha de días registrados
  objective: Contador de días seguidos con registros, en tono neutro (opcional).
  dependencies: [T-012]
  spec_required: true    # specs/SPEC-019-racha.md
- id: T-021
  title: Barra inferior con texto muy grande
  objective: Que la barra Hoy/Historial/Progreso no se desborde con escala de texto 3,0 en 360 px (hallazgo del reviewer de SPEC-011; hoy se desborda 29 px).
  dependencies: [T-011]
  spec_required: false
  status: done  # hecho en la rama de SPEC-013 (el Historial lo mostraba con texto ×2); test en main_nav_test.dart
- id: T-022
  title: Borrar exportaciones temporales anteriores
  objective: >
    Los archivos de "Exportar mis datos" (JSON, CSV, PDF, con datos de salud) se quedan en el
    directorio temporal después de compartirlos. Borrar los anteriores al empezar una exportación
    nueva (hallazgo MINOR del reviewer de SPEC-016).
  dependencies: [T-017]
  spec_required: false
  status: done  # 2026-10-04: ExportService borra solo sus propios archivos (por nombre) al empezar; tests en export_cleanup_test.dart
- id: T-023
  title: Idioma español declarado en iOS
  objective: >
    `ios/Runner/Info.plist` no declara `CFBundleLocalizations` (es). Material ya está en es-CO
    (SPEC-016), pero los textos del sistema de iOS podrían seguir el idioma de desarrollo
    (hallazgo MINOR del reviewer de SPEC-016). Verificar en el teléfono antes de cambiarlo.
  dependencies: [T-017]
  spec_required: false
- id: T-024
  title: Normalizar "ü" en la búsqueda y la resolución
  objective: >
    `_normalize` (catálogo y resolver) quita tildes y "ñ" pero no "ü": "pingüino" se parte en dos
    términos de FTS (hallazgo MINOR del reviewer de SPEC-018).
  dependencies: [T-019]
  spec_required: true    # specs/SPEC-020-normalizar-dieresis.md — Strict (resolución de alimentos; antes anotada como Fast Path por error)
- id: T-025
  title: Coincidencia exacta con tildes en el catálogo
  objective: >
    `CatalogRepository.resolve` compara la consulta normalizada con `lower(name_es)`/`lower(term)`
    sin quitar tildes, "ñ" ni "ü": "Café" o "Plátano" nunca dan `matched` y la persona tiene que
    elegir entre un solo candidato (32 alimentos reales afectados). Hallazgo del reviewer de SPEC-020.
  dependencies: [T-024]
  status: done  # SPEC-028
  spec_required: true    # specs/SPEC-028-coincidencia-exacta-con-tildes.md — Strict (incluye T-026)
- id: T-026
  title: Normalizador de build_catalog con "ü"
  objective: >
    `data/build_catalog/lib/validators.dart` tiene su propia copia de `_normalize` sin "ü". Alinearla
    con `normalizeFoodText` cuando entre al catálogo un alimento con diéresis (o junto con T-025).
  dependencies: [T-024]
  status: done  # SPEC-028 (R3)
  spec_required: false   # cubierta por SPEC-028 (R3), junto con T-025
- id: T-027
  title: Vertex AI en el backend desplegado de desarrollo
  objective: >
    El backend desplegado en `kcalcula-ia-dev` usa `fake` (sin `AI_PROVIDER`), así que en el
    teléfono la IA solo reconoce las 10 frases de prueba. Pasar a `gemini-2.5-flash` en Vertex AI.
    Decisión de la usuaria del 2026-10-07 (adelanta ADR-002).
  dependencies: []
  status: done  # SPEC-029
  spec_required: true    # specs/SPEC-029-vertex-ai-en-dev.md — Strict (datos fuera del dispositivo, costo)
- id: T-028
  title: Medir gemini-2.5-flash sin razonamiento para bajar la latencia
  objective: >
    Con Vertex, leer una etiqueta tarda p50 8,5–12,1 s y p95 21–34 s según la corrida (SPEC-029,
    evals y baseline del 2026-10-07): el p95 ya se acerca a los 60 s del timeout.
    Probar `thinkingBudget: 0` en `vertex.ts` y comparar latencia, precisión y campos inventados
    con el baseline en `parse_meal` y `extract_label`. Con el reintento por salida inválida, una
    etiqueta lenta (máximo 37,6 s) puede pasar de los 60 s de `extractLabel` (reviewer de SPEC-029).
    Strict (parámetros del modelo, skill `ai-pipeline`).
  dependencies: [T-027]
  spec_required: true
- id: T-029
  title: Decimales con coma en "Confirmar etiqueta"
  objective: >
    `_NumberField` usa `double.tryParse`: "1,4" queda vacío y no deja guardar, sin explicación.
    Encontrado al probar SPEC-029 en el teléfono (2026-10-07).
  dependencies: []
  status: done  # SPEC-030
  spec_required: true    # specs/SPEC-030-decimales-con-coma-en-etiqueta.md — Standard
- id: T-030
  title: La IA mezcla valores de porción y de "por 100 g" en una etiqueta
  objective: >
    Al probar SPEC-029 con una etiqueta real ("mini palitos de queso") la usuaria vio en
    "Confirmar etiqueta" valores que parecen de la columna "por 100 g". Revisar con su foto si es
    un error del prompt `label_extraction.v1` (Strict, `ai-pipeline`) o de esa etiqueta.
  dependencies: [T-027]
  spec_required: true
- id: T-031
  title: "¿Cuánto comiste?" no se actualiza en pantalla al cambiar la porción
  objective: >
    En "Confirmar etiqueta", cambiar la porción actualiza `consumedQuantity` en el controlador
    (SPEC-004 R5) pero el campo sigue mostrando el valor anterior. Hallazgo del reviewer de
    SPEC-030, **confirmado en el teléfono** (2026-10-07): porción 27 → 30 y el campo sigue en 27.
    La app registraría 30 g mientras la persona ve 27: cambia la cantidad guardada.
  dependencies: []
  status: done  # SPEC-031
  spec_required: true    # specs/SPEC-031-cantidad-consumida-sigue-la-porcion.md — Standard
- id: T-032
  title: Cantidad en porciones y vista previa en "Confirmar etiqueta"
  objective: >
    Pedido de la usuaria (2026-10-07): decir "comí 3 porciones" en vez de gramos, ver la proteína,
    carbohidratos y grasa que se van a registrar, y que el botón deje claro que lleva a Revisar.
  dependencies: [T-031]
  status: done  # SPEC-032
  spec_required: true    # specs/SPEC-032-cantidad-en-porciones-y-vista-previa.md — Standard
- id: T-033
  title: Etiqueta y mis productos por ingrediente
  objective: >
    Pedido de la usuaria (2026-10-07): registrar una comida completa por texto o voz y, en el
    Detalle, usar la etiqueta de cada ingrediente o elegir un producto ya guardado (sin repetir
    fotos ni tokens), con la cantidad en porciones o g/ml.
  dependencies: [T-032]
  status: done  # SPEC-033
  spec_required: true    # specs/SPEC-033-etiqueta-y-mis-productos-por-ingrediente.md — Standard
- id: T-034
  title: Mis productos (ver, editar, borrar, nombres alternativos y prioridad al reconocer)
  objective: >
    Complemento de T-033: pantalla para gestionar los productos personales, darles nombres con que
    la persona los llama ("mi pan") y que tengan prioridad sobre el catálogo al reconocer el texto.
    Strict (cambia la resolución de alimentos).
  dependencies: [T-033]
  spec_required: true    # specs/SPEC-034-mis-productos.md — Strict
- id: T-035
  title: Conversión g → porciones en nutrition_core
  objective: >
    SPEC-032 (`label_confirmation_controller.dart`) y SPEC-033 (`ReviewController.portionsOf`) dividen
    gramos entre la porción en la app para mostrar porciones. Moverlo a `nutrition_core` con casos de
    referencia (hallazgo del reviewer de SPEC-033). Strict.
  dependencies: [T-033]
  spec_required: true
- id: F2
  title: Fase 2 — foto del plato (como Estimación, con confirmación obligatoria), comidas frecuentes (ver T-018), confianza visual
  # SPECs (Draft, 2026-10-04): specs/SPEC-021-foto-del-plato.md (Strict),
  # specs/SPEC-022-comidas-frecuentes-y-favoritas.md, specs/SPEC-023-confianza-visual.md
- id: F3
  title: Fase 3 — corrección conversacional, marcas, historial avanzado
  # SPECs (Draft, 2026-10-04): specs/SPEC-024-correccion-conversacional.md (Strict),
  # specs/SPEC-025-marcas.md (Strict), specs/SPEC-026-historial-avanzado.md
- id: F4
  title: Fase 4 — Samsung Health y ecosistemas de salud
  # SPEC (Draft, 2026-10-04, para cuando se retome): specs/SPEC-027-salud-conectada.md (Strict)
  status: pospuesta  # decisión de la usuaria (2026-10-03): sin integraciones con otras apps en el
                     # MVP; el mantenimiento medido sigue siendo manual (SPEC-008 R4). Investigación
                     # hecha: docs/research/2026-10-03-samsung-health-health-connect.md (PV-12).
- id: F5
  title: Fase 5 — análisis, tendencias, reportes
```
