# SPEC-008: Objetivos nutricionales configurables

## Status
Draft
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
  **mantenimiento** con la fórmula de OQ1. La sugerencia rellena el campo de kcal, que sigue
  siendo editable. El usuario decide si la guarda.
- R3. **La sugerencia no calcula macros.** Solo sugiere kcal; las metas de macros las escribe el
  usuario (ver OQ3).
- R4. **Presentación de la sugerencia.** Se muestra como estimación ("~2.150 kcal") junto con el
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
  se muestran como progreso.
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

## Acceptance Criteria
- AC1. Escribir 2000 en kcal y guardar → la meta queda en `user.db` y el diario muestra "/ 2.000
  kcal". Dejar kcal vacía → "Guardar" deshabilitado. Valores fuera del rango de OQ4 → mensaje en
  español en el campo y no se guarda `[widget]`.
- AC2. Metas de macros opcionales: guardar solo kcal y proteína 100 → el diario muestra progreso
  de kcal y de proteína, y no de carbohidratos ni de grasa `[widget]`.
- AC3. Estimación de energía: para cada caso de referencia (ver OQ1, al menos 4: dos por sexo y
  con niveles de actividad distintos, tomados **de la fuente citada**, no calculados de memoria),
  `estimateMaintenanceKcal(...)` devuelve el valor esperado de la fuente con tolerancia de ±1 kcal
  sin redondear `[unit, nutrition_core]`.
- AC4. Validación de entradas de la estimación: valores fuera de los rangos de OQ4, o un nivel de
  actividad desconocido, → error tipado, nunca un número `[unit, nutrition_core]`.
- AC5. "Calcular una sugerencia" con datos válidos rellena el campo de kcal con "~" + el valor
  presentado (redondeo half-up de `rounding.dart`), deja intactos los campos de macros (R3),
  muestra el texto fijo de R4 y no guarda nada hasta que el usuario toca "Guardar" `[widget]`.
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

## Technical Constraints
- Invariantes 3 (cálculo solo en `nutrition_core`, redondeo al presentar), 6 (nada nuevo sale del
  dispositivo) y 9 (no inventar: la fórmula y los factores de actividad vienen de una fuente
  verificada por `researcher`) de `CLAUDE.md`.
- La invariante 8 aplica por analogía: ningún coeficiente ni caso de referencia se escribe de
  memoria.
- Flutter: Riverpod; la UI no llama a Drift directamente (pasa por `infra/storage`); las features
  no se importan entre sí. La meta la leen `diary` y `settings` a través de `infra/storage`.

## Components / Files Affected
- `packages/nutrition_core/lib/src/energy_estimation.dart` (nuevo): fórmula de R2 y factores de
  actividad, con la fuente citada.
- `packages/nutrition_core/lib/src/goal_progress.dart` (nuevo): consumido, meta, restante o exceso
  (R6).
- `packages/nutrition_core/test/` (nuevos casos de referencia).
- `app/lib/infra/storage/app_database.dart`: tablas `nutrition_goals` (una fila) y
  `goal_estimation_inputs` (una fila, opcional); `schemaVersion` 3 → 4 con migración.
- `app/lib/infra/storage/storage_repository.dart`: leer y guardar la meta; `deleteAllUserData` y
  `exportUserData` (R10).
- `app/lib/features/settings/`: pantalla "Mi meta diaria" y entrada en Ajustes.
- `app/lib/features/diary/`: progreso (R6) y enlace (R7).
- `docs/privacy.md`: filas nuevas del inventario. `docs/architecture.md`: sección de objetivos y
  tablas nuevas del modelo de datos.

## Dependencies
- SPEC-001 (diario, totales del día), SPEC-006 (borrar todo y exportar).
- Investigación previa (`researcher`): PV-13 (fórmula y factores de actividad) antes de
  implementar R2, R3 y AC3.

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
- Unit (`nutrition_core`): AC3, AC4, AC6 con casos de referencia de la fuente citada.
- Widget: AC1, AC2, AC5, AC6 (presentación), AC7.
- Integration: AC8, AC9, AC10.
- Revisión de código y grep: AC11.
- Manual: recorrido completo en el Motorola (meta manual, sugerencia, progreso y borrado).

## Out of Scope
- Metas por objetivo (bajar o subir de peso, déficit o superávit calórico) y planes con fecha.
  R2 solo estima el **mantenimiento**.
- Sugerencia de macros (R3), metas de fibra, sodio u otros nutrientes.
- Historial de metas: cambiar la meta cambia la referencia de todos los días que se miren.
- Notificaciones, recordatorios, rachas, alertas o colores de "te pasaste".
- Reportes, tendencias o gráficos de varios días (F5).
- Sincronizar con Samsung Health u otros ecosistemas (F4).
- Unidades imperiales.

## Open Questions
- OQ1. **Fórmula de estimación** (PV-13, para el `researcher`): ¿qué ecuación usar para el gasto
  energético en reposo (p. ej. Mifflin-St Jeor) y qué factores de actividad? Necesita una fuente
  primaria o institucional citable, coeficientes exactos y al menos 4 casos de referencia
  calculados **por la fuente**, para AC3.
- OQ2. **Niveles de actividad:** ¿cuántos y con qué textos para el usuario en es-CO? Depende de
  la fuente de OQ1.
- OQ3. ¿Confirmas que la sugerencia es solo de kcal y los macros siempre los escribe el usuario?
  Sugerir macros exigiría otra fuente (rangos de distribución de macronutrientes) y más alcance.
- OQ4. **Rangos válidos:** meta de kcal, metas de macros, peso, estatura y edad. Propuesta para
  discutir: kcal 800–6.000; proteína, carbohidratos y grasa 0–1.000 g; peso 30–300 kg; estatura
  120–230 cm; edad 18–100 años (la app es solo para adultos, SPEC-006). Algún mínimo de kcal
  podría necesitar fuente y no ser solo una validación de entrada (ver OQ7).
- OQ5. ¿El consumido del progreso lleva "~" cuando alguna comida del día es estimación? Hoy
  "Total del día" no lo lleva.
- OQ6. ¿Guardar peso, estatura, edad y sexo exige cambiar la política de privacidad y volver a
  pedir consentimiento (SPEC-006, versión de la política)? Siguen sin salir del dispositivo, pero
  son datos de salud nuevos. Requiere decisión del usuario y, para publicar, revisión legal
  (PV-07).
- OQ7. **Seguridad:** ¿la app debe negarse a guardar una meta de kcal muy baja, o solo advertir?
  Hay riesgo en usuarios con trastornos alimentarios. Si se fija un umbral, necesita fuente
  (`researcher`); no se inventa.

## Definition of Done
- AC1–AC11 con evidencia enlazada en esta SPEC.
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

## Review
Informe del reviewer: pendiente.
