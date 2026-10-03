# SPEC-008: Perfil, mantenimiento y objetivo nutricional

## Status
Review
Path: Strict (cálculos nuevos en `packages/nutrition_core`: metabolismo basal, mantenimiento,
objetivo y reparto de macros; y datos personales de salud guardados en el dispositivo: peso,
estatura, fecha de nacimiento, sexo y nivel de actividad)

> **Versión 2 (2026-10-02).** Reemplaza la versión aprobada antes, que sugería el mantenimiento con
> la DRI 2023 y los macros con la Res. 3803. La usuaria la probó y pidió otro diseño: perfil
> editable, metabolismo basal y mantenimiento separados, objetivo aparte y macros en % de las kcal.
> Lo ya implementado que sigue valiendo (meta en `user.db`, progreso en el diario, borrar y
> exportar, política v3, manejo de errores) se reutiliza. La evidencia de la versión 1 está en el
> historial de git (commit `eb78daa`).

## Objective
Que la persona sepa en qué punto empieza (metabolismo basal y mantenimiento, calculados con su
perfil) y, en otra sección, elija un objetivo (bajar grasa, mantener, subir masa muscular). El
objetivo fija su meta diaria de kcal y reparte automáticamente proteína, carbohidratos y grasa en %
de esas kcal. El diario muestra el progreso frente a esa meta.

## Context
Backlog T-009 (post-MVP), depende de T-002. Enfoque **fitness**, decisión de la usuaria
(2026-10-02). Referencia de UX: https://fitgeneration.es/calculadora/harris-benedict/, sin su paso
de "objetivo", que aquí va en otra sección. Fuentes: `docs/research/2026-10-02-harris-benedict-actividad-objetivo.md`
(PV-14) y `docs/research/2026-10-02-formula-gasto-energetico.md` (PV-13).

Principio del producto: "sin inventar precisión". Todo lo calculado se presenta como estimación
("~"), con un aviso de que no es una recomendación médica.

## User Story
Como persona que entrena, quiero registrar mi perfil y ver mi metabolismo basal y mi
mantenimiento según mi nivel de actividad actual, y luego elegir un objetivo que me diga cuántas
kcal y cuánta proteína, carbohidratos y grasa comer, para seguir mi progreso diario. Si cambio de
peso o de temporada de actividad, todo se recalcula.

## Requirements

### Perfil
- R1. **Mi perfil** (desde Ajustes, desde "Mi objetivo" y, sin meta, desde el enlace del diario): sexo (femenino o masculino, lo usa la
  fórmula), fecha de nacimiento (se muestra la edad calculada), estatura (cm), peso (kg) y nivel de
  actividad. Todo es editable en cualquier momento. Rangos válidos: peso 30–300 kg, estatura
  120–230 cm, edad 18–100 años. Fuera de rango, mensaje en español y no se guarda.
- R2. **Niveles de actividad** (incluye el NEAT, el movimiento del día a día): 4 niveles, descritos
  por días de ejercicio a la semana. Cada uno usa un factor de actividad física (PAL) de EFSA 2013
  (decisión OQ10-B por delegación de la usuaria):
  - "Poca actividad": poco o nada de ejercicio, trabajo sentado (PAL 1,4).
  - "Actividad ligera": ejercicio 1–3 días por semana o mucho movimiento diario (1,6).
  - "Actividad moderada": ejercicio 3–5 días por semana (1,8).
  - "Actividad alta": ejercicio 6–7 días por semana o trabajo físico (2,0).

  Pasar de días de ejercicio a cada PAL es una decisión de producto, documentada como tal. El nivel
  se cambia por temporadas, desde el perfil.

### Punto de partida
- R3. **Metabolismo basal** (`nutrition_core`): Harris-Benedict original (Harris y Benedict, PNAS
  1918;4(12):373). Hombres: 66,4730 + 13,7516·peso + 5,0033·estatura − 6,7550·edad. Mujeres:
  655,0955 + 9,5634·peso + 1,8496·estatura − 4,6756·edad.
- R4. **Mantenimiento** = metabolismo basal × PAL del nivel de actividad. Es el método de FAO/OMS:
  gasto total = metabolismo basal × PAL.
- R5. **Pantalla "Mi punto de partida"** (parte del perfil): muestra "~1.423 kcal" de metabolismo
  basal y "~2.276 kcal" de mantenimiento, con una línea que explica cada uno. Se recalcula al
  instante cuando cambia el peso, la actividad o cualquier dato del perfil.

### Objetivo
- R6. **Pantalla "Mi objetivo"** (otra sección): requiere un perfil completo; si no lo hay, lleva
  al perfil. Opciones, cada una con las kcal que daría hoy:
  - "Bajar grasa (suave)": mantenimiento − 250 kcal.
  - "Bajar grasa": mantenimiento − 500 kcal.
  - "Mantener": el mantenimiento.
  - "Subir masa muscular (suave)": mantenimiento + 10 %.
  - "Subir masa muscular": mantenimiento + 20 %.

  Fuentes: 250–500 kcal/día para personas que entrenan (posición conjunta DC/AND/ACSM 2016) y 500
  kcal/día de AHA/ACC/TOS 2013; +10–20 % de Iraki et al. 2019.
- R7. **Macros en % de las kcal**, según el objetivo, calculados automáticamente en
  `nutrition_core`:

  | Objetivo | Proteína | Grasa | Carbohidratos |
  |---|---|---|---|
  | Bajar grasa (las dos opciones) | 30 % | 25 % | 45 % |
  | Mantener | 20 % | 25 % | 55 % |
  | Subir masa muscular (las dos opciones) | 20 % | 25 % | 55 % |

  Ajuste aprobado por la usuaria: con proteína al 25 %, el % crecía con las kcal y daba 2,3–2,7 g/kg
  al mantener o subir masa, por encima de su referencia de 1,5–2,0. Con el 20 % queda en ~1,8–2,2
  g/kg (ejemplo: 63 kg, mantenimiento 2.276 kcal).

  Los gramos se calculan como kcal × % ÷ (4, 9 o 4) (FAO 2003). Las tres filas están dentro de los
  AMDR vigentes (proteína 10–35 %, grasa 20–35 %, carbohidratos 45–65 %, NASEM 2024) y de la grasa
  ≥ 20 % de la posición conjunta 2016. **El punto elegido dentro de los rangos es una decisión de
  producto**, documentada como tal. La pantalla muestra también los g/kg que resultan, solo como
  dato.
- R8. **Meta diaria = el objetivo elegido.** Al confirmarlo se guarda como meta: objetivo, kcal y
  gramos de cada macro. El diario la usa (R11).
- R9. **La meta sigue al perfil.** Si la meta viene de un objetivo y no se editó a mano, se
  recalcula sola cuando cambian el peso, la actividad o el perfil, y el diario muestra la meta
  nueva. Si la persona edita las kcal a mano (R10), la meta queda fija y la pantalla de objetivo
  muestra: "Tu meta es manual. Con tu perfil actual, '{objetivo}' sería ~X kcal. [Usar este
  valor]".
- R10. **Meta manual:** la persona puede escribir sus kcal (800–6.000). Los macros se reparten con
  los % de su objetivo, o los de "Mantener" si no eligió ninguno. Por debajo de 1.200 kcal se
  advierte y no se bloquea (decisión de producto, ver PV-13).
- R11. **Progreso en el diario**, sin cambios respecto a la versión 1: "{consumido} / {meta} kcal ·
  quedan {restante}", una barra por kcal y por cada macro, tono neutro, "~" si hay comidas
  estimadas, y "N por encima de la meta" sin rojo. Sin meta, el enlace dice "Calcular mi meta".

### Datos
- R12. Perfil y meta en `user.db`, que pasa a v5 con migración (desde la v3 publicada y desde la v4
  que solo existió en builds de desarrollo). "Borrar todos mis datos" los
  elimina y "Exportar" los incluye. No salen del dispositivo: ni al backend, ni a la IA, ni a
  Crashlytics, ni a logs. Los fallos de escritura muestran un mensaje en español y no se relanzan
  (la excepción de SQLite trae los parámetros).
- R13. La política de privacidad v3 describe el perfil: qué datos son, que se guardan en el
  teléfono para calcular el punto de partida, que no salen de él y cómo borrarlos.
- R14. Aviso fijo en "Mi punto de partida" y en "Mi objetivo": "Son estimaciones generales, no una
  recomendación médica. Si tienes una condición de salud, consulta a un profesional."

## Acceptance Criteria
- AC1. Metabolismo basal: los 3 casos resueltos por la fuente (Harris y Benedict 1919, p. 230):
  hombre, 27 años, 172 cm, 77,2 kg → 1806; mujer, 22 años, 166 cm, 77,2 kg → 1597; mujer, 66 años,
  162 cm, 62,3 kg → 1242, con ±1 kcal `[unit, nutrition_core]`.
- AC2. Mantenimiento = basal × PAL para los 4 niveles (1,4 / 1,6 / 1,8 / 2,0), sobre el primer caso
  de AC1 `[unit, nutrition_core]`.
- AC3. Entradas fuera de rango, NaN o infinito → error tipado, nunca un número
  `[unit, nutrition_core]`.
- AC4. Objetivos: con mantenimiento 2.000 → 1.750 / 1.500 / 2.000 / 2.200 / 2.400 kcal
  `[unit, nutrition_core]`.
- AC5. Macros: 2.000 kcal con "Mantener" → proteína 100 g, grasa 55,6 g, carbohidratos 275 g; los
  gramos convertidos con 4/9/4 suman 2.000 ±0,01; las tres filas de R7 están dentro de los AMDR
  `[unit, nutrition_core]`.
- AC6. Perfil: guardar y editar; la edad se calcula a partir de la fecha de nacimiento; fuera de
  rango → mensaje y no se guarda `[widget]`.
- AC7. Al cambiar el peso o la actividad en el perfil, "Mi punto de partida" muestra el basal y el
  mantenimiento nuevos sin reiniciar la pantalla `[widget]`.
- AC8. Elegir un objetivo lo guarda como meta (kcal y gramos), y el diario muestra "/ {meta} kcal"
  y las tres barras de macros `[widget + integration]`.
- AC9. Con una meta que viene de un objetivo, cambiar el peso recalcula la meta y el diario la
  muestra. Con una meta editada a mano, no cambia y aparece la sugerencia de R9 `[integration]`.
- AC10. Meta manual de 1.199 kcal → se advierte y deja guardar; de 1.200 → no se advierte
  `[widget]`.
- AC11. Sin perfil, "Mi objetivo" lleva al perfil; sin meta, el diario muestra "Calcular mi meta"
  `[widget]`.
- AC12. Progreso del diario (texto, "~", por encima de la meta, barra sin color de alarma), como en
  la versión 1 `[unit + widget]`.
- AC13. "Borrar todos mis datos" vacía el perfil y la meta; "Exportar" los incluye; la migración
  a v5 (desde la v3 y desde la v4 de desarrollo) conserva comidas, productos y consentimiento
  `[integration]`.
- AC14. Un fallo al guardar el perfil o la meta muestra un mensaje en español; la excepción no se
  relanza ni llega a Crashlytics `[widget]`.
- AC15. Ninguna llamada a `infra/ai_client`, a Crashlytics, a `functions/` ni a logs recibe datos
  del perfil o de la meta `[revisión de código + grep]`.
- AC16. La política v3 menciona el perfil y vuelve a pedir el consentimiento a quien aceptó la v2
  `[widget + integration]`.

## Technical Constraints
- Invariantes 3 (todo cálculo en `nutrition_core`, sin redondear hasta presentar), 6 y 9 de
  `CLAUDE.md`. Cada coeficiente, PAL, ajuste y % cita su fuente o se marca como decisión de
  producto.
- Riverpod; la UI pasa por `infra/storage`; las features no se importan entre sí. Feature nueva o
  ampliada: `features/goals/` (perfil, punto de partida, objetivo, meta).

## Components / Files Affected
- `packages/nutrition_core/lib/src/`: `energy_estimation.dart` (Harris-Benedict y PAL),
  `goal_planning.dart` (objetivos y % de macros), `goal_progress.dart` y `goal_limits.dart`. El
  `macro_suggestion.dart` de la versión 1 se eliminó.
- `app/lib/infra/storage/`: tablas `user_profile` (fila única) y `nutrition_goals` (objetivo, kcal,
  macros en g, `is_manual`); `user.db` v5.
- `app/lib/features/goals/`: pantallas "Mi perfil" (con el punto de partida) y "Mi objetivo"
  (con la meta manual).
- `app/lib/features/diary/`: el enlace "Calcular mi meta".
- `app/assets/legal/privacy_policy_draft_es.md` (v3), `docs/privacy.md`, `docs/architecture.md`.

## Dependencies
- PV-13 y PV-14 resueltos. Ya se usan; no se requiere más investigación.

## Edge Cases
- Perfil incompleto: no se muestran el punto de partida ni el objetivo; se invita a completarlo.
- La persona cumple años: la edad (y el basal) se recalculan a partir de la fecha de nacimiento.
- Un objetivo que deja la meta fuera de 800–6.000 kcal → no se guarda y se avisa; puede escribirla
  a mano.
- Cambiar el objetivo reemplaza la meta (sin historial).
- Si al guardar el perfil la meta de un objetivo quedaría fuera de 800–6.000 kcal, se conserva la
  anterior y "Mi perfil" lo avisa.
- Con el paso del tiempo (cumpleaños), el basal y el mantenimiento en pantalla se recalculan solos;
  la meta guardada se actualiza la próxima vez que se guarde el perfil o se elija el objetivo. Si
  la edad sale de 18–100, "Mi objetivo" pide revisar el perfil.
- Fallo al leer `user.db` → mensaje en español en vez de quedarse cargando.
- Fallo de `user.db` → mensaje en español, sin relanzar (R12).

## Security & Privacy
- No sale ningún dato nuevo del dispositivo. Se guardan datos personales de salud (peso,
  estatura, fecha de nacimiento, sexo, actividad), necesarios para la función, con borrar todo y
  exportar. Se actualizan la política v3 y `docs/privacy.md`.

## Tests Required
- Unit (`nutrition_core`): AC1–AC5.
- Widget e integration: AC6–AC14 y AC16.
- Revisión y grep: AC15.
- Manual: recorrido completo en el Motorola.

## Out of Scope
- Historial de peso y gráficos (F5); historial de metas.
- Editar a mano los % de macros (se usan los del objetivo).
- Fechas límite, ritmo semanal de pérdida o ganancia, recordatorios.
- La escala de fitness 1,2–1,9 (sin fuente, OQ10); Harris-Benedict revisada (fuente primaria no
  leída); masa magra (Katch-McArdle o Cunningham), porque requiere % de grasa corporal.
- Unidades imperiales.

## Open Questions
- OQ10. ✅ Resuelta por delegación de la usuaria ("haz lo que recomiendes"): factores de actividad
  con PAL de EFSA 2013 (opción B, con fuente). Si prefiere la escala de fitness (opción A, sin
  fuente), es un cambio de dos líneas y de la documentación.

## Evidencia de Acceptance Criteria
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `packages/nutrition_core/test/energy_estimation_test.dart`, grupo "AC1" (3 casos de Harris y Benedict 1919, p. 230, ±1 kcal) |
| AC2 | ✅ | `energy_estimation_test.dart`, grupo "AC2" (4 PAL de EFSA 2013, con valores literales 2.528,79 / 2.890,05 / 3.251,30 / 3.612,56) |
| AC3 | ✅ | `energy_estimation_test.dart`, grupo "AC3" (rangos, NaN, infinito, edad 18–100) |
| AC4 | ✅ | `packages/nutrition_core/test/goal_planning_test.dart` ("AC4…") |
| AC5 | ✅ | `goal_planning_test.dart` (100 / 55,6 / 275 g; suma 4/9/4; repartos dentro de los AMDR) |
| AC6 | ✅ | `app/test/features/goals/goals_flow_test.dart` ("AC6/AC7…", "AC6: fuera de rango…", "carga el perfil guardado…") |
| AC7 | ✅ | `goals_flow_test.dart` ("AC6/AC7…": peso 63 → 70 y actividad ligera → alta, sin reiniciar la pantalla) |
| AC8 | ✅ | `goals_flow_test.dart` ("AC8…": diario → "Calcular mi meta" → objetivo → meta → "0 / 1.776 kcal" y 4 barras) + `app/test/features/diary/diary_goal_test.dart` |
| AC9 | ✅ | `goals_flow_test.dart`, grupo "AC9" (meta de un objetivo recalculada 1.776 → 1.883 y el diario muestra "/ 1.883 kcal"; meta manual fija, aviso y "Usar este valor"; recálculo fuera de rango → se conserva y se avisa) + `app/test/infra/storage/nutrition_goal_storage_test.dart` ("R9…") |
| AC10 | ✅ | `goals_flow_test.dart` ("AC10…") + `packages/nutrition_core/test/goal_limits_test.dart` |
| AC11 | ✅ | `goals_flow_test.dart` ("AC11: sin perfil…", "perfil que ya no es válido…", "R1: desde Mi objetivo se abre Mi perfil") + `diary_goal_test.dart` ("AC11: sin meta…") |
| AC12 | ✅ | `diary_goal_test.dart` (textos, "~", por encima de la meta, barra con el color del tema) + `goal_progress_test.dart` |
| AC13 | ✅ | `nutrition_goal_storage_test.dart` (borrar todo, exportar, migración v3 → v5 y v4 de desarrollo → v5) |
| AC14 | ✅ | `goals_flow_test.dart` ("AC14…" en perfil y en objetivo: `takeException()` nulo, sin "Sqlite") |
| AC15 | ✅ | Grep (2026-10-02): `app/lib/infra/ai_client`, `app/lib/infra/crash_reporting` y `functions/src` no mencionan perfil ni meta; `features/goals` no tiene `print`/`debugPrint`/`log`; los fallos de escritura no se relanzan (AC14) |
| AC16 | ✅ | `app/test/integration/onboarding_gate_flow_test.dart` ("SPEC-008 AC13…": v2 → onboarding con v3) + `app/test/features/legal/privacy_policy_text_test.dart` (sección del perfil) |

Verificado (2026-10-02, versión 2): `dart analyze` y `flutter analyze` sin issues; `nutrition_core`
62/62; app 124/124. Pendiente: recorrido manual en el teléfono.

## Definition of Done
- AC1–AC16 con evidencia enlazada en esta SPEC.
- `dart analyze` y `dart test` (`nutrition_core`) y `flutter analyze` y `flutter test` (app), todo
  verde.
- Reviewer: PASS enlazado.
- Recorrido manual en el teléfono documentado.
- `docs/privacy.md`, `docs/architecture.md` y la política v3 actualizados.
- Aprobación explícita de la usuaria antes de fusionar (Strict Path).

## Change Log
- 2026-10-02: creación a partir de T-009 de `docs/backlog.md`, con las decisiones del usuario sobre
  el origen de la meta (ambos), los nutrientes (kcal y macros opcionales) y el progreso (consumido /
  meta y restante, en tono neutro).
- 2026-10-02: el usuario delega en las respuestas recomendadas: OQ3–OQ6 resueltas y OQ7 a medias
  (advertir, no bloquear). R12, R13 y AC12–AC14 nuevos. Se lanza `researcher` para PV-13 (OQ1,
  OQ2 y el umbral de OQ7). El usuario confirma que la meta debe poder calcularse a partir de peso,
  edad, sexo y actividad física. La estatura queda incluida porque las ecuaciones candidatas la
  usan; lo confirma PV-13.
- 2026-10-02: el usuario cambia OQ3: la sugerencia incluye proteína, grasa y carbohidratos además
  de kcal. R2, R3, R4 y AC5 cambian; AC5b y OQ8 nuevos; PV-13 se amplía con el reparto de macros;
  los macros salen de Out of Scope.
- 2026-10-02: con la nota de PV-13, el usuario elige la fórmula DRI 2023 de NASEM (OQ1), los
  rangos colombianos de la Res. 3803 para los macros (OQ8) y la advertencia por debajo de 1.200
  kcal como decisión de producto (OQ7). R14, AC15 y OQ9 (verificación humana de las tablas) nuevos;
  AC3, AC5b y AC14 con valores concretos.
- 2026-10-02: **Approved por el usuario** ("aprobada", en el chat). Status → Implementing. La
  verificación humana de OQ9 sigue pendiente: los coeficientes de la DRI 2023 y los valores de la
  Res. 3803 no se escriben en el código hasta que esté hecha.

- 2026-10-02: al implementar se encontró un hueco: la DRI 2023 para adultos aplica desde los 19
  años y OQ4 aceptaba 18. El usuario aprueba: sugerencia de 19 a 100 años; a los 18, meta manual
  (OQ4 ajustada). También aprueba corregir en la política v3 la frase sobre la voz ("se transcribe
  en tu propio teléfono"), que la medición de SPEC-002 mostró inexacta en Android.

- 2026-10-02: reviewer CHANGES_REQUESTED. Corregidos: [MAJOR] fallos de escritura en `user.db`
  llegaban a Crashlytics con los parámetros de SQLite (ahora se capturan, mensaje en español, sin
  relanzar); NaN en la estimación; sugerencia fuera de 800–6.000 kcal (decisión: no rellenar y
  avisar, ver Edge Cases; tomada por delegación de la usuaria, "haz lo que recomiendes"); borrar los
  datos de la sugerencia los limpia también en memoria; separador de miles en kcal; test de widget
  del diario por encima de la meta; fila PV-13; ubicación de la pantalla en `features/goals/`. El
  riesgo de SQLite → Crashlytics en el flujo de revisión de comidas queda en `docs/backlog.md`
  (T-010), fuera de esta SPEC.

- 2026-10-02: reviewer PASS (re-revisión de 96d2837). Se aplicaron también sus 2 MINOR nuevos
  (el mensaje de error se limpia al editar; mensaje propio si la meta se guarda pero los datos de
  la sugerencia no). OQ9 registrada con la confirmación de la usuaria. Status → Review; falta el
  recorrido manual en el teléfono y la aprobación de la usuaria para fusionar (Strict Path).

- 2026-10-02: la usuaria no quedó conforme con el cálculo y pide uno como el de fitgeneration
  (Harris-Benedict, 5 niveles por días de ejercicio, objetivo bajar/mantener/ganar). Status Review →
  Draft con el cambio propuesto arriba; se lanza `researcher` (PV-14). La implementación con la DRI
  2023 queda en la rama hasta que se apruebe el cambio.

- 2026-10-02: **versión 2**, a partir de la nueva descripción de la usuaria: perfil editable
  (peso, actividad por temporadas), basal (Harris-Benedict 1918) y mantenimiento (× PAL de EFSA)
  separados, objetivo aparte (déficit o superávit con fuente), macros en % de las kcal según el
  objetivo y meta que se recalcula con el perfil. Status → Draft.

- 2026-10-02: **versión 2 aprobada por la usuaria** ("aprobada, con el ajuste de porcentajes"),
  con Mantener y Subir masa en 20 / 25 / 55 %. Status → Implementing.

- 2026-10-02: versión 2 implementada. Textos de actividad neutros en género ("Poca actividad",
  "Actividad ligera", "Actividad moderada", "Actividad alta") en vez de "Sedentaria"/"Activa", por
  delegación de la usuaria. Status → Review (falta el reviewer y el recorrido manual).

- 2026-10-02: `user.db` pasa a **v5** (no v4). La v4 existió solo en builds de desarrollo de la
  versión 1 (por ejemplo, el teléfono de pruebas), con otras tablas de meta. La migración desde la v4
  las reemplaza y conserva comidas, productos y consentimiento. Desde la v3 se crean las dos tablas
  nuevas.

- 2026-10-02: reviewer (v2) CHANGES_REQUESTED. Corregido: [MAJOR] el mantenimiento se calculaba
  en `ProfileController` (ahora llama a `estimateMaintenanceKcal`). MINOR: textos de la SPEC (R1,
  R2, R12, AC13, Components); aviso cuando la meta no se puede recalcular; perfil inválido con el
  tiempo; errores de lectura; numeración de comentarios y tests; PV-13; AC2 con valores literales;
  AC9 hasta el diario; enlace a "Mi perfil" desde "Mi objetivo". El paso a v5 y los textos de
  actividad neutros en género se decidieron por delegación de la usuaria ("haz lo que
  recomiendes").

## Review
Primera revisión (2026-10-02, subagente `reviewer`): **CHANGES_REQUESTED**.
- [MAJOR] Fallos de escritura en `user.db` llegaban a Crashlytics con los parámetros de SQLite.
- MINOR: fila PV-13 desactualizada; registro de OQ9; NaN y sugerencia fuera de rango; borrar los
  datos de la sugerencia no los quitaba de memoria; separador de miles; test de widget por encima
  de la meta; la simulación de v3 en AC10 (aceptada); ubicación de la pantalla.

Todo se corrigió en `96d2837`, salvo AC10, que se aceptó como está.

Re-revisión (2026-10-02, sobre `96d2837`): **PASS**. AC1–AC15 y AC5b cumplidos; `nutrition_core`
97/97 y app 130/130. Recalculó las 40 celdas de la DRI 2023 (≤ 0,5 kcal). Dos MINOR nuevos (el
mensaje de error no se limpiaba al editar; mensaje inexacto si fallaban solo los datos de la
sugerencia), corregidos después (app 132/132). OQ9 quedaba pendiente de la confirmación de la
usuaria, ya registrada.
