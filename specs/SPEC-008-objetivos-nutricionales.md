# SPEC-008: Objetivos nutricionales configurables

## Status
Implementing
Path: Strict (agrega un cálculo nuevo a `packages/nutrition_core`, la estimación de energía
diaria, y guarda en el dispositivo datos personales de salud nuevos: peso, estatura, edad, sexo y
nivel de actividad)

## Objective
Que el usuario tenga una meta diaria de kcal, y si quiere de proteína, carbohidratos y grasa. La
puede escribir él mismo o partir de una sugerencia que la app calcula. Además, el diario de hoy
muestra cuánto lleva frente a esa meta y cuánto le queda.

## Context
Backlog T-009 (post-MVP), depende de T-002 (SPEC-001, `Done`). Hoy el diario solo muestra
"Total del día: N kcal" (`app/lib/features/diary/diary_screen.dart`), sin ninguna referencia.

Decisiones del usuario (2026-10-02):
- **Origen de la meta:** las dos opciones. El usuario puede escribirla, o pedir una sugerencia
  calculada y luego cambiarla.
- **Nutrientes:** la meta de kcal es obligatoria; las de proteína, carbohidratos y grasa (en
  gramos) son opcionales. Son los cuatro valores que ya se guardan por ítem en `meal_items`.
- **Progreso:** "consumido / meta" y lo que queda, con una barra, en tono neutro. Sin colores de
  alarma ni mensajes de juicio.

Principio del producto: "sin inventar precisión". La sugerencia es una **estimación**, se presenta
como tal y nunca reemplaza la decisión del usuario.

## User Story
Como persona que registra lo que come, quiero fijar una meta diaria de calorías (y, si quiero, de
macros), escribiéndola yo o partiendo de una sugerencia, para ver de un vistazo cuánto llevo hoy
y cuánto me queda.

## Requirements
- R1. **Meta manual.** En Ajustes hay una pantalla "Mi meta diaria" donde el usuario escribe la
  meta de kcal (entero, obligatoria para guardar) y, de forma opcional, las metas de proteína,
  carbohidratos y grasa (en gramos, con un decimal como máximo). Cada meta opcional puede quedar
  vacía. Rangos aceptados: ver Open Questions OQ4. Fuera de rango → mensaje en español en el campo
  y no se guarda.
- R2. **Sugerencia calculada (opcional).** En la misma pantalla, el botón "Calcular una
  sugerencia" pide peso (kg), estatura (cm), edad (años), sexo (para la fórmula: femenino o
  masculino) y nivel de actividad. Con esos datos `nutrition_core` estima las kcal diarias de
  **mantenimiento** con las ecuaciones de gasto energético total de las DRI for Energy 2023 de
  NASEM (Tabla 5-5: una ecuación por sexo y nivel de actividad, OQ1), y a partir de ellas (y del peso, para la proteína) las
  metas de proteína, carbohidratos y grasa en gramos (R3). La sugerencia rellena los cuatro
  campos, que siguen siendo editables. El usuario decide si la guarda.
- R3. **La sugerencia incluye macros** (OQ3 y OQ8, decisiones del usuario del 2026-10-02).
  `nutrition_core` reparte las kcal sugeridas así:
  - **Proteína:** 1,11 g/kg de peso (RDA de la Res. 3803 de 2016, Tabla 12). Si eso queda por
    debajo del 14 % o por encima del 20 % de las kcal sugeridas, se ajusta a ese límite (rango de
    la Res. 3803, Tabla 1).
  - **Grasa:** 27,5 % de las kcal (la mitad del rango 20–35 % de la Res. 3803, Tabla 1).
  - **Carbohidratos:** el resto de las kcal. Con las dos reglas anteriores queda entre el 52,5 % y
    el 58,5 %, dentro del rango 50–65 %.

  Para pasar de kcal a gramos se usan 4 kcal/g de proteína, 9 de grasa y 4 de carbohidratos (FAO
  Food and Nutrition Paper 77, 2003). Las fuentes solo dan rangos, así que **el punto elegido dentro
  de ellos es una decisión de producto**, y se documenta y presenta como estimación, no como
  recomendación.
- R4. **Presentación de la sugerencia.** Se muestra como estimación ("~2.150 kcal", "~110 g de
  proteína") junto con el
  texto fijo: "Es una estimación general, no una recomendación médica. Si tienes una condición de
  salud, consulta a un profesional." No aparece ningún mensaje de juicio sobre el peso.
- R5. **Todo el cálculo vive en `nutrition_core`:** la estimación de energía (R2) y el progreso
  (R6), en Dart puro, sin redondear hasta presentar. Cada coeficiente de la fórmula y cada factor
  de actividad citan su fuente en el código y en los tests de referencia. Nada se escribe de
  memoria.
- R6. **Progreso en el diario.** Si hay meta guardada, el diario de hoy muestra para kcal
  "{consumido} / {meta} kcal", una barra de progreso y "quedan {restante}". Si el consumido supera
  la meta, muestra "{exceso} por encima de la meta" y la barra queda llena, en el mismo color, sin
  rojo. Lo mismo para cada macro que tenga meta, en gramos con un decimal. Los macros sin meta no
  se muestran como progreso. El consumido lleva "~" si alguna comida del día tiene confianza
  distinta de "Alta precisión" (OQ5, resuelta), igual que los demás valores estimados.
- R7. **Sin meta guardada**, el diario se ve como hoy ("Total del día: N kcal") más un enlace
  discreto, "Fijar una meta diaria", que abre la pantalla de R1.
- R8. **Persistencia local.** La meta y, si se usó la sugerencia, los datos de R2 se guardan en
  `user.db` (migración de esquema). La meta vigente aplica a cualquier día que se mire; no se
  guarda un historial de metas (ver Out of Scope).
- R9. **Los datos de R2 son opcionales y se pueden borrar.** Si el usuario nunca pide una
  sugerencia, no se guarda ningún dato de R2. Hay una acción "Borrar mis datos para la sugerencia"
  que los elimina sin tocar la meta.
- R10. **Borrar todo y exportar (SPEC-006).** "Borrar todos mis datos" también elimina la meta y
  los datos de R2. "Exportar mis datos" los incluye en el JSON.
- R11. **Nada sale del dispositivo.** La meta y los datos de R2 no se envían a ningún backend, ni
  al nuestro ni a la IA, y no aparecen en reportes de fallos ni en logs.
- R12. **Política de privacidad (OQ6, resuelta).** El texto de la política menciona los datos de R2
  (qué son, que solo se guardan si el usuario pide la sugerencia, que no salen del dispositivo y
  cómo borrarlos) y sube de versión. El mecanismo existente de SPEC-006/007 vuelve a pedir el
  consentimiento a quien aceptó una versión anterior.
- R13. **Meta de kcal baja (OQ7).** Si la meta de kcal que se va a guardar, escrita o sugerida, es
  menor de **1.200 kcal**, la app **advierte pero no bloquea**: "Esta meta es más baja de lo que
  se suele recomendar sin acompañamiento profesional." El 1.200 es una **decisión de producto**:
  PV-13 no encontró un piso institucional; las cifras de 1.200/1.500 de NHLBI y AHA/ACC/TOS son
  planes para bajar de peso. El mínimo aceptado de 800 kcal (OQ4) coincide con la frontera de las
  dietas muy bajas en calorías, que requieren supervisión médica (NIH 1993, ver la nota de PV-13).
- R14. **Niveles de actividad (OQ2).** Son los 4 de las DRI 2023, con textos en es-CO basados en
  los ejemplos de la Tabla 7-1 (velocidades pasadas a km/h). Propuesta, que se ajusta al
  implementar tras la verificación humana de la tabla:
  - "Poco movimiento": solo las actividades del día a día.
  - "Algo activo": el día a día y además unos 60–80 min de caminata (5–6 km/h).
  - "Activo": el día a día, 30–50 min de caminata y 45 min de bicicleta moderada, o equivalente.
  - "Muy activo": el día a día, 45 min de bicicleta moderada y unos 25 min de trote, o
    equivalente.

  Debajo, la nota: "Elige el que más se parezca a un día normal tuyo." La fuente advierte que no
  hay una forma precisa de autoclasificarse; por eso el resultado es una estimación (R4).

## Acceptance Criteria
- AC1. Escribir 2000 en kcal y guardar → la meta queda en `user.db` y el diario muestra "/ 2.000
  kcal". Dejar kcal vacía → "Guardar" deshabilitado. Valores fuera del rango de OQ4 → mensaje en
  español en el campo y no se guarda `[widget]`.
- AC2. Metas de macros opcionales: guardar solo kcal y proteína 100 → el diario muestra progreso
  de kcal y de proteína, y no de carbohidratos ni de grasa `[widget]`.
- AC3. Estimación de energía: para cada caso de referencia calculado **por la fuente** (DRI 2023:
  mujer de 22 años, 165 cm, 63 kg, "Algo activo" → 2.275 kcal; mujer de 70 años, 157 cm, 70 kg,
  "Poco movimiento" → 1.812 kcal; y al menos 8 filas de las Tablas 7-9 y 7-10 que cubran los dos
  sexos y los 4 niveles), `estimateMaintenanceKcal(...)` devuelve el valor de la fuente con una
  tolerancia de ±1 kcal `[unit, nutrition_core]`.
- AC4. Validación de entradas de la estimación: valores fuera de los rangos de OQ4, o un nivel de
  actividad desconocido, → error tipado, nunca un número `[unit, nutrition_core]`.
- AC5. "Calcular una sugerencia" con datos válidos rellena los campos de kcal, proteína,
  carbohidratos y grasa con "~" y los valores presentados (redondeo de `rounding.dart`), muestra
  el texto fijo de R4 y no guarda nada hasta que el usuario toca "Guardar" `[widget]`.
- AC5b. Reparto de macros (R3): 2.000 kcal y 63 kg → proteína 69,93 g (1,11 × 63; 13,99 % < 14 %,
  así que se ajusta a 14 % = 70,0 g), grasa 61,11 g (27,5 %) y carbohidratos 292,5 g. Además, un
  caso que active el tope del 20 % y uno sin ajuste. En todos, proteína × 4 + grasa × 9 +
  carbohidratos × 4 = kcal sugeridas (±0,01, sin redondear) `[unit, nutrition_core]`.
- AC6. Progreso: consumido 1.249,6 kcal y meta 2.000 → "1.250 / 2.000 kcal · quedan 750". La resta
  se hace sin redondear (750,4 → "750"). Consumido 2.150,2 y meta 2.000 → "150 por encima de la
  meta" y barra llena `[unit, nutrition_core]` + `[widget]`.
- AC7. Sin meta guardada → el diario muestra "Total del día: N kcal" y el enlace "Fijar una meta
  diaria", que abre la pantalla de meta `[widget]`.
- AC8. "Borrar mis datos para la sugerencia" elimina peso, estatura, edad, sexo y actividad y
  conserva la meta. "Borrar todos mis datos" deja vacías las tablas de meta y de datos de R2
  `[integration]`.
- AC9. "Exportar mis datos" incluye la meta y, si existen, los datos de R2 `[integration]`.
- AC10. La migración de `user.db` desde la versión 3 conserva comidas, productos personales y
  consentimiento, y crea las tablas nuevas vacías `[integration]`.
- AC11. Ninguna llamada a `infra/ai_client`, a Crashlytics ni a logs recibe la meta ni los datos de
  R2 `[unit + revisión de código, grep dirigido]`.
- AC12. Consumido con una comida "Estimación" → el progreso muestra "~1.250 / 2.000 kcal"; con todas
  las comidas en "Alta precisión" → sin "~" `[widget]`.
- AC13. La versión de la política sube y un usuario con consentimiento de la versión anterior ve
  de nuevo el onboarding; el texto nuevo menciona los datos de R2 `[widget + integration]`.
- AC14. Meta de 1.199 kcal → se muestra la advertencia de R13 y "Guardar" sigue habilitado; meta de
  1.200 → sin advertencia `[widget]`.
- AC15. La pantalla de sugerencia muestra los 4 niveles de R14 con sus textos y la nota debajo
  `[widget]`.

## Technical Constraints
- Invariantes 3 (cálculo solo en `nutrition_core`, redondeo al presentar), 6 (nada nuevo sale del
  dispositivo) y 9 (no inventar: la fórmula y los factores de actividad vienen de una fuente
  verificada por `researcher`) de `CLAUDE.md`.
- La invariante 8 aplica por analogía: ningún coeficiente ni caso de referencia se escribe de
  memoria.
- Flutter: Riverpod; la UI no llama a Drift directamente (pasa por `infra/storage`); las features
  no se importan entre sí. La meta la leen `diary` y `settings` a través de `infra/storage`.

## Components / Files Affected
- `packages/nutrition_core/lib/src/energy_estimation.dart` (nuevo): las 8 ecuaciones de la DRI
  2023 (2 sexos × 4 niveles), con la fuente citada.
- `packages/nutrition_core/lib/src/macro_suggestion.dart` (nuevo): reparto de macros (R3).
- `packages/nutrition_core/lib/src/goal_progress.dart` (nuevo): consumido, meta, restante o exceso
  (R6).
- `packages/nutrition_core/test/` (nuevos casos de referencia).
- `app/lib/infra/storage/app_database.dart`: tablas `nutrition_goals` (una fila) y
  `goal_estimation_inputs` (una fila, opcional); `schemaVersion` 3 → 4 con migración.
- `app/lib/infra/storage/storage_repository.dart`: leer y guardar la meta; `deleteAllUserData` y
  `exportUserData` (R10).
- `app/lib/features/settings/`: pantalla "Mi meta diaria" y entrada en Ajustes.
- `app/lib/features/diary/`: progreso (R6) y enlace (R7).
- `app/lib/infra/legal/privacy_policy.dart`: texto de la política y `privacyPolicyVersion` v2 → v3 (R12).
- `docs/privacy.md`: filas nuevas del inventario. `docs/architecture.md`: sección de objetivos y
  tablas nuevas del modelo de datos.

## Dependencies
- SPEC-001 (diario, totales del día), SPEC-006 (borrar todo y exportar).
- PV-13 resuelto (`docs/research/2026-10-02-formula-gasto-energetico.md`). Antes de implementar
  R2, R3 y AC3 falta la verificación humana de OQ9.

## Edge Cases
- El usuario guarda una meta y luego borra todos sus datos → el diario vuelve al estado de R7.
- Meta de kcal guardada sin metas de macros → solo progreso de kcal.
- Consumido 0 (día sin comidas) con meta → "0 / 2.000 kcal · quedan 2.000"; el texto actual
  "Todavía no registras nada hoy." se conserva debajo.
- Consumido exactamente igual a la meta → "quedan 0" (no "0 por encima").
- Los valores de las comidas son estimaciones ("~"): el progreso hereda esa incertidumbre. ¿Se
  muestra "~" en el consumido? Ver OQ5.
- Edad: la app solo sabe que el usuario declaró ser mayor de edad (SPEC-006); la edad de R2 se
  pide aparte y se valida con el rango de OQ4.
- Sexo: la fórmula lo usa como variable fisiológica. Si el usuario no quiere responderlo, puede
  escribir la meta a mano (R1); la sugerencia no se calcula sin ese dato.
- Datos de R2 incompletos → "Calcular" deshabilitado, sin cálculo parcial.
- Cambio de unidad (lb, pies) → fuera de alcance; solo kg y cm.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? **No** (R11).
- Sí se **guardan** datos nuevos en el dispositivo: la meta y los datos de R2. Peso, estatura,
  edad y sexo son datos personales de salud, sensibles con criterio conservador (ver
  `docs/privacy.md`, Principios). Se aplican minimización (R9: solo si el usuario pide la
  sugerencia, y se pueden borrar por separado), "borrar todo" y exportación (R10).
- Actualizar `docs/privacy.md` con las filas del inventario. Si hace falta cambiar la política y
  volver a pedir consentimiento, ver OQ6.

## Tests Required
- Unit (`nutrition_core`): AC3, AC4, AC5b, AC6 con casos de referencia de la fuente citada.
- Widget: AC1, AC2, AC5, AC6 (presentación), AC7.
- Integration: AC8, AC9, AC10.
- Revisión de código y grep: AC11.
- Manual: recorrido completo en el Motorola (meta manual, sugerencia, progreso y borrado).

## Out of Scope
- Metas por objetivo (bajar o subir de peso, déficit o superávit calórico) y planes con fecha.
  R2 solo estima el **mantenimiento**.
- Metas de fibra, sodio u otros nutrientes.
- Historial de metas: cambiar la meta cambia la referencia de todos los días que se miren.
- Notificaciones, recordatorios, rachas, alertas o colores de "te pasaste".
- Reportes, tendencias o gráficos de varios días (F5).
- Sincronizar con Samsung Health u otros ecosistemas (F4).
- Unidades imperiales.

## Open Questions
- OQ1. ✅ Resuelta (2026-10-02, decisión del usuario sobre PV-13): ecuaciones de gasto energético
  total de las DRI 2023 de NASEM. Se descartaron Mifflin-St Jeor (sin factores de actividad con
  fuente institucional ni casos resueltos) y FAO/OMS con la Res. 3803 (sin estatura y con la tabla
  de adultos ilegible). Nota: `docs/research/2026-10-02-formula-gasto-energetico.md`.
- OQ2. ✅ Resuelta: los 4 niveles de las DRI 2023 (R14).
- OQ3. ✅ Resuelta (2026-10-02, decisión del usuario): la sugerencia incluye kcal, proteína,
  carbohidratos y grasa (R3).
- OQ4. ✅ Resuelta (2026-10-02): kcal 800–6.000; proteína, carbohidratos y grasa 0–1.000 g; peso
  30–300 kg; estatura 120–230 cm; edad 18–100 años. Son validaciones de entrada (que el valor sea
  plausible), no recomendaciones. El aviso de meta baja es R13, aparte.
- OQ5. ✅ Resuelta (2026-10-02): sí, "~" en el consumido si alguna comida del día no es "Alta
  precisión" (R6, AC12).
- OQ6. ✅ Resuelta (2026-10-02): se actualiza la política y sube su versión, lo que vuelve a pedir
  el consentimiento (R12, AC13). Sigue pendiente la revisión legal antes de publicar (PV-07).
- OQ8. ✅ Resuelta (2026-10-02, decisión del usuario): rangos colombianos de la Res. 3803 (R3).
- OQ7. ✅ Resuelta (2026-10-02, decisión del usuario): advertir por debajo de 1.200 kcal, como
  decisión de producto, sin bloquear (R13).
- OQ9. **Verificación humana antes de implementar** (pendiente que dejó PV-13): comparar a ojo con
  las páginas originales las Tablas 5-4, 5-5, 7-1, 7-9 y 7-10 de las DRI 2023 y las Tablas 1 y 12
  de la Res. 3803. Las transcribió una herramienta que resume páginas, y los coeficientes y casos
  de AC3 salen de ahí. Puede hacerlo el usuario o el reviewer con acceso a los documentos.
  ✅ **Cerrada (2026-10-02).** (1) Comprobación de consistencia: las 8 ecuaciones de la Tabla 5-5
  reproducen las 40 celdas de las Tablas 7-9 y 7-10 con una diferencia máxima de 0,5 kcal, y los
  2 ejemplos resueltos del cap. 7 (2.275,37 y 1.811,94); ecuaciones y tablas vienen de capítulos
  distintos. (2) El usuario recibió los valores que la consistencia no cubre (Res. 3803: 1,11
  g/kg; 14–20 / 20–35 / 50–65 %; textos de la Tabla 7-1) con sus enlaces y respondió "listo,
  continúa".

## Definition of Done
- AC1–AC15 (incluido AC5b) con evidencia enlazada en esta SPEC.
- OQ9 hecha y registrada (quién comparó qué tablas y cuándo).
- `dart analyze` y `dart test` (nutrition_core); `flutter analyze` y `flutter test` (app), todo
  verde.
- Casos de referencia de AC3 con fuente citada.
- Reviewer: PASS enlazado.
- `docs/privacy.md` y `docs/architecture.md` actualizados; PV-13 resuelto en
  `docs/research/POR-VERIFICAR.md`.
- Aprobación explícita del usuario antes de fusionar (Strict Path).

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

## Review
Informe del reviewer: pendiente.
