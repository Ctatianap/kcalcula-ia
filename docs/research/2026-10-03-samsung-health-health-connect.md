# Samsung Health, Health Connect y HealthKit (PV-12)

Pregunta: ¿Cómo puede KCalcula IA (Flutter, Android e iOS, sin cuentas, datos solo en el dispositivo)
leer automáticamente el "Total de calorías quemadas" diario de Samsung Health (reloj Galaxy + teléfono
Motorola con Android 16), y quizá peso, pasos y calorías activas, y opcionalmente escribir la nutrición
registrada? ¿Por qué vía (Samsung Health Data SDK, Health Connect o ambas), con qué permisos, qué
requisitos de publicación, qué paquete Flutter, qué precisión tiene el dato y qué implica en privacidad?

Decisión que desbloquea: fase F4 de `docs/backlog.md` (integración con ecosistemas de salud): elección de
vía de integración, alcance de tipos de datos, texto del aviso de "estimación" y cambios en
`docs/privacy.md` / declaraciones de tienda.

Fecha de consulta de todas las fuentes: 2026-10-03.

## CONFIRMADO

### 1. Samsung Health Data SDK

- El antiguo "Samsung Health SDK for Android" está obsoleto: "Samsung Health Android SDK has been
  depricated as of 31 July, 2025" (sic), y remite a usar Samsung Health Data SDK. —
  https://developer.samsung.com/health/android/overview.html (2026-10-03)
- Versiones del Samsung Health Data SDK: v1.0.0 beta1 (2024-10-21, solo lectura), beta2 (2025-02-26,
  añade escritura de glucosa, presión y nutrición y exige "access code" para probar escrituras),
  v1.0.0 (2025-07-31), **v1.1.0 (2026-03-12, la más reciente)**. —
  https://developer.samsung.com/health/data/release-note.html (2026-10-03)
- Requisitos: Samsung Health 6.30.2 o superior; Android 10 (API 29) o superior; Java 17; no funciona en
  emuladores. **"It is available on all Samsung smartphones and also non-Samsung Android smartphones"**
  (es decir, sirve en un Motorola con Samsung Health instalado). —
  https://developer.samsung.com/health/data/overview.html (2026-10-03)
- Proceso de publicación: la lectura se prueba activando "Developer Mode for Data Read" en Samsung Health;
  la escritura requiere un "access code" que se obtiene solicitando partnership. El modo desarrollador
  "is ONLY intended for testing or debugging your app. It is NOT for app users." Para distribuir:
  "Please submit partner request before your app distribution. Your app's information including the app
  package name and signature (SHA-256) will be registered in the Samsung Health's system after an
  approval." Sin aprobación, "the app using the Samsung Health Data SDK works only with the developer mode
  turned on." — https://developer.samsung.com/health/data/process.html y
  https://developer.samsung.com/health/data/guide/developer-mode.html (2026-10-03)
  → **Sí: para publicar (incluso solo lectura) se necesita aprobación de Samsung como partner.**
- Tipos de datos (clase `DataType`): StepsType, HeartRateType, SleepType, ExerciseType, BloodOxygenType,
  BloodGlucoseType, BloodPressureType, SkinTemperatureType, ActivitySummaryType, FloorsClimbedType,
  BodyCompositionType, WaterIntakeType, NutritionType, EnergyScoreType, UserProfileDataType,
  SleepApneaType, IrregularHeartRhythmNotificationType, BodyTemperatureType, ExerciseLocationType; y
  metas (StepsGoalType, ActiveCaloriesBurnedGoalType, NutritionGoalType, etc.). —
  https://developer.samsung.com/health/data/api-reference/-shd/com.samsung.android.sdk.health.data.request/-data-type/index.html (2026-10-03)
- **`ActivitySummaryType`** (solo lectura, solo por agregación) expone `TOTAL_CALORIES_BURNED` ("To get
  the total calories burned"), `TOTAL_ACTIVE_CALORIES_BURNED`, `TOTAL_ACTIVE_TIME` y `TOTAL_DISTANCE`,
  agregando datos de varios dispositivos Samsung sin duplicar. Es el equivalente programático más directo
  del "Total de calorías quemadas" que hoy la usuaria copia a mano. —
  https://developer.samsung.com/health/data/api-reference/-shd/com.samsung.android.sdk.health.data.request/-data-type/-activity-summary-type/index.html (2026-10-03)
- **`BodyCompositionType`** (lectura y escritura): `WEIGHT` (kg, obligatorio), `HEIGHT`,
  `BASAL_METABOLIC_RATE` ("in kilocalories per day"), grasa corporal, masa muscular, etc. —
  https://developer.samsung.com/health/data/api-reference/-shd/com.samsung.android.sdk.health.data.request/-data-type/-body-composition-type/index.html (2026-10-03)
- **`NutritionType`** (lectura y escritura): `CALORIES`, `PROTEIN`, `CARBOHYDRATE`, `TOTAL_FAT`,
  `MEAL_TYPE`, `TITLE` y opcionales (sodio, azúcar, fibra, colesterol, grasas saturadas/trans, vitaminas
  A y C, calcio, hierro, potasio). —
  https://developer.samsung.com/health/data/api-reference/-shd/com.samsung.android.sdk.health.data.request/-data-type/-nutrition-type/index.html (2026-10-03)
- El SDK es nativo (Android/Kotlin-Java); no se encontró un paquete Flutter oficial de Samsung (ver
  NO CONFIRMADO).

### 2. Health Connect (Android)

- Disponibilidad: en Android 14+ Health Connect es parte del framework de Android; en Android 13 o
  inferior hay que instalar la app de Health Connect desde Play. SDK mínimo Android 8 (API 26); la app
  Health Connect requiere API 28+. Se comprueba con `HealthConnectClient.getSdkStatus(context)`. —
  https://developer.android.com/health-and-fitness/guides/health-connect/develop/get-started (2026-10-03)
  En Android 14+ se accede desde Ajustes > Seguridad y privacidad > Controles de privacidad > Health
  Connect. — https://support.google.com/android/answer/12201227?hl=en (2026-10-03)
- Tipos y permisos (todos existen, lectura y escritura):
  `TotalCaloriesBurnedRecord` (`android.permission.health.READ_/WRITE_TOTAL_CALORIES_BURNED`, intervalo),
  `ActiveCaloriesBurnedRecord` (`READ_/WRITE_ACTIVE_CALORIES_BURNED`),
  `BasalMetabolicRateRecord` (`READ_/WRITE_BASAL_METABOLIC_RATE`, instantáneo, unidad de potencia),
  `WeightRecord` (`READ_/WRITE_WEIGHT`), `StepsRecord` (`READ_/WRITE_STEPS`),
  `NutritionRecord` (`READ_/WRITE_NUTRITION`, intervalo, `mealType` obligatorio).
  Permisos adicionales: `android.permission.health.READ_HEALTH_DATA_HISTORY` (datos de más de 30 días
  antes de conceder el permiso) y `android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND`. —
  https://developer.android.com/health-and-fitness/guides/health-connect/plan/data-types (2026-10-03)
- Manifiesto: además de los `uses-permission`, una actividad que maneje
  `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` (Android 13−) y un `activity-alias` con
  `android.intent.action.VIEW_PERMISSION_USAGE` + categoría `android.intent.category.HEALTH_PERMISSIONS`
  protegido por `android.permission.START_VIEW_PERMISSION_USAGE` (Android 14+), que muestre la política
  de privacidad. Por defecto solo se leen datos hasta 30 días antes de conceder el permiso. —
  https://developer.android.com/health-and-fitness/guides/health-connect/develop/get-started (2026-10-03)
- Agregados disponibles: `TotalCaloriesBurnedRecord.ENERGY_TOTAL`,
  `ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL`, `BasalMetabolicRateRecord.BASAL_CALORIES_TOTAL`. La
  documentación dice que solo los tipos de Actividad y Sueño se deduplican por prioridad de apps. —
  https://developer.android.com/health-and-fitness/health-connect/aggregate-data (2026-10-03)
- **Samsung Health ↔ Health Connect** (blog oficial de Samsung Developer, 2025-02-18): Samsung Health
  sincroniza con Health Connect desde la versión 6.22.5 (octubre 2022). Tabla de tipos: Steps →
  `StepsRecord`; Exercise → `ExerciseSessionRecord`; **"Exercise calories" → `TotalCaloriesBurnedRecord`**;
  Nutrition → `NutritionRecord`; Weight → `WeightRecord`; Basal metabolic rate →
  `BasalMetabolicRateRecord`; también glucosa, SpO2, presión, distancia, FC, potencia, velocidad, VO2max,
  sueño, grasa corporal, altura. No aparece `ActiveCaloriesBurnedRecord`.
  **Cita clave: "The Health Connect's total calories burned, distance, power, speed, and VO2max in the
  table above are matched with the Samsung Health exercise tracker's data. The Samsung Health's activity
  tracker data are not synchronized with Health Connect."**
  Dirección: "When Samsung Health has new or updated data, it writes the data to Health Connect. When
  Health Connect has updated data, Samsung Health retrieves it." Frecuencia: los datos del reloj llegan a
  Samsung Health cuando el reloj se reconecta, cuando se abre la pantalla principal de Samsung Health o al
  deslizar para refrescar. —
  https://developer.samsung.com/health/blog/en/accessing-samsung-health-data-through-health-connect (2026-10-03)
  Y: "For battery life reasons, the timing and frequency of data synchronization between the Galaxy Watch
  and Samsung Health follows its own policy." — https://developer.samsung.com/health/health-connect-faq.html (2026-10-03)
- **Consecuencia directa:** el "Total de calorías quemadas" diario que la usuaria ve en Samsung Health
  (actividad de todo el día + basal) **no llega a Health Connect**; por Health Connect solo llegan las
  calorías de las sesiones de ejercicio registradas.

#### Requisitos de Google Play para Health Connect
- Pasos para publicar: revisar la política de datos de usuario y la de "Permissions and APIs that access
  sensitive information" (requisitos adicionales de Health Connect); completar la sección **Data safety**;
  completar el **Health apps declaration form** (declarar cada tipo de dato de Health Connect, elegir la
  función de salud — p. ej. "Nutrition and weight management", "Activity and fitness" — y justificar cada
  permiso; se repite si cambian los tipos). "Request the minimum data types needed and provide a valid use
  case for each request." La política de privacidad publicada en Play debe ser la misma que se muestra en
  Health Connect. — https://developer.android.com/health-and-fitness/health-connect/publish (2026-10-03)
- Política: usos permitidos incluyen "fitness and wellness"; prohibido transferir o vender datos a
  terceros (anunciantes, brokers), usarlos para anuncios o para solvencia crediticia; acceso humano
  restringido; exige política de privacidad completa. "Data accessed through Health Connect Permissions
  is regarded as personal and sensitive user data subject to the User Data policy". —
  https://support.google.com/googleplay/android-developer/answer/9888170 y
  https://support.google.com/googleplay/android-developer/answer/16679511?hl=en (2026-10-03)
- Política de privacidad: enlace en Play Console y enlace o texto dentro de la app, en URL pública,
  activa, sin geobloqueo y no PDF. — https://support.google.com/googleplay/android-developer/answer/16679511?hl=en (2026-10-03)
- Data safety: "Collect" = transmitir datos fuera del dispositivo; "User data accessed by your app that
  is only processed locally on the user's device and not sent off device does not need to be
  disclosed." — https://support.google.com/googleplay/android-developer/answer/10787469 (2026-10-03)
  (El Health apps declaration form sí es obligatorio aunque los datos no salgan del dispositivo.)

### 3. iOS / HealthKit

- HealthKit tiene `HKQuantityTypeIdentifier.activeEnergyBurned` (energía activa) y
  `basalEnergyBurned` (energía en reposo); no existe un identificador de "total"; se obtiene sumando ambos
  (inferencia, ver NO CONFIRMADO). — https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/activeenergyburned
  y https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/basalenergyburned
  (2026-10-03; el cuerpo de la página no se pudo leer con la herramienta, confirmado por resultados de
  búsqueda que citan esas URLs). `dietaryEnergyConsumed` y demás `dietary*` existen (mismo origen).
- App Store Review Guidelines 5.1.3(i): no se pueden usar ni divulgar datos de HealthKit para
  publicidad, marketing o minería de datos; "You must disclose the specific health data that you are
  collecting from the device." 5.1.3(ii): no escribir datos falsos o inexactos en HealthKit y no guardar
  información personal de salud en iCloud. 2.5.1: HealthKit debe usarse para salud y fitness e
  integrarse con la app Salud. — https://developer.apple.com/app-store/review/guidelines/ (2026-10-03)
- Samsung Health existe en iOS (App Store, v1.15.3 del 2025-04-20) pero solo es compatible con Gear S2/S3/
  S4, Gear Fit2/Fit2 pro, Gear Sport, Galaxy Fit/Fitⓔ/Fit2, Galaxy Watch Active2 y Galaxy Watch3; puede
  leer pasos de Apple Health; la ficha no indica que escriba en Apple Health. —
  https://apps.apple.com/us/app/samsung-health/id1224541484 (2026-10-03)
  → Para usuarios de iPhone, la fuente práctica es HealthKit (Apple Watch u otras apps que escriban allí).

### 4. Paquete Flutter `health`

- Versión estable actual en pub.dev: **13.3.2**, publicada hace ~50 días (≈ mediados de agosto 2026);
  publicador verificado **carp.dk**; 160 pub points; plataformas Android e iOS. Versiones previas:
  13.3.1 (~7 meses), 13.3.0 (~8 meses), 13.2.1 (~11 meses). Envuelve HealthKit en iOS y Health Connect en
  Android. — https://pub.dev/packages/health y https://pub.dev/packages/health/versions (2026-10-03)
- Cambios recientes: 13.3.2 devuelve UUID al escribir y sube el mínimo de iOS a 15.0; 13.3.0 actualiza a
  `androidx.health.connect:connect-client:1.2.0-alpha02`. —
  https://pub.dev/packages/health/changelog (2026-10-03)
- Tipos: en `dataTypeKeysAndroid` están `TOTAL_CALORIES_BURNED`, `ACTIVE_ENERGY_BURNED`,
  `BASAL_ENERGY_BURNED`, `STEPS`, `WEIGHT`, `NUTRITION`; en `dataTypeKeysIOS` también están
  `TOTAL_CALORIES_BURNED` y los `DIETARY_*` (`DIETARY_ENERGY_CONSUMED`, `DIETARY_PROTEIN_CONSUMED`,
  `DIETARY_CARBS_CONSUMED`, `DIETARY_FATS_CONSUMED`, etc.). **Los `DIETARY_*` no están en la lista de
  Android**; en Android la nutrición va por `NUTRITION` (NutritionRecord). —
  https://raw.githubusercontent.com/carp-dk/carp-health-flutter/main/lib/src/heath_data_types.dart y
  https://pub.dev/documentation/health/latest/health/HealthDataType.html (2026-10-03)
- Escritura de nutrición: método `writeMeal`, "writing meals on iOS (Apple Health) & Android". —
  https://pub.dev/packages/health (2026-10-03)
- Configuración Android: `MainActivity` debe extender `FlutterFragmentActivity`; permisos opcionales de
  historial y segundo plano soportados. iOS mínimo 15.0. — https://pub.dev/packages/health (2026-10-03)
- Repositorio: https://github.com/carp-dk/carp-health-flutter con 201 issues y 34 PR abiertos al
  2026-10-03.
- **El paquete `health` no integra el Samsung Health Data SDK**: solo Health Connect y HealthKit (según
  su descripción en pub.dev).

### 5. Precisión

- Samsung (soporte oficial): los datos de calorías "take into account a person's basal metabolic rate
  (BMR), which is calculated using the information in your profile" y la cifra "does not mean the exact
  burnt calories during exercise and is not the same as the true burnt calorie data" (página de Gear Fit2
  Pro). — https://www.samsung.com/hk_en/support/mobile-devices/why-is-the-burnt-calorie-data-on-gear-fit2-pro-different-from-that-on-health-machines/ (2026-10-03)
- Samsung Health: "The calories you burn includes your basal metabolism calculated based on the profile
  you registered." — https://www.samsung.com/za/support/mobile-devices/how-do-i-use-the-samsung-health-features/ (2026-10-03)
  → El total depende de que el perfil (peso, altura, edad, sexo) en Samsung Health esté actualizado.
- Shcherbina et al., J Pers Med 2017 (60 voluntarios, calorimetría indirecta; Apple Watch, Basis Peak,
  Fitbit Surge, Microsoft Band, Mio Alpha 2, PulseOn, Samsung Gear S2): "No device achieved an error in EE
  below 20 percent." Conclusión: los dispositivos de muñeca "poorly estimate EE, suggesting caution in
  the use of EE measurements as part of health improvement programs." —
  https://pmc.ncbi.nlm.nih.gov/articles/PMC5491979/ (2026-10-03)

### 6. Privacidad

- Health Connect: "Your data is stored locally, on your device, and you're in control of which apps have
  access to your data on Health Connect". — https://support.google.com/android/answer/12201227?hl=en (2026-10-03)
- HealthKit: datos en la clase de protección "Protected Unless Open"; cuando una app no tiene permiso de
  lectura "all queries return no data—the same response that an empty database would return". La
  sincronización con iCloud la hace el sistema (cifrado de extremo a extremo con 2FA). —
  https://support.apple.com/guide/security/protecting-access-to-users-health-data-sec88be9900f/web (2026-10-03)
- Por tanto, leer de Health Connect / HealthKit y usar el dato solo en el dispositivo **no transmite nada
  fuera del dispositivo por parte de la app** (la transmisión ocurriría solo si la app luego lo enviara,
  p. ej. al backend). Para Data safety de Play no se declara como "collected" si no sale del dispositivo
  (ver punto 2). Ley 1581: los datos de salud son datos sensibles (art. 5) y su tratamiento requiere
  autorización explícita (art. 6); ver `docs/research/2026-09-28-ley-1581-consentimiento.md`.

## NO CONFIRMADO / CONTRADICTORIO

- **Si Samsung acepta hoy solicitudes de partnership para el Health Data SDK.** Las páginas oficiales
  (process, developer-mode) describen el proceso sin indicar suspensión. Fuentes secundarias (foros de
  Samsung Developers y Samsung Community, sin fecha verificada) dicen que el programa de partners estuvo
  cerrado durante años; podrían referirse al SDK antiguo. — https://forum.developer.samsung.com/t/partner-app-program/5983
  (no se pudo leer el contenido), https://us.community.samsung.com/t5/Samsung-Apps-and-Services/Please-open-new-Partner-Registrations-for-Samsung-Health-App/td-p/2327110
  (secundaria). Tampoco se encontraron criterios de elegibilidad (tipo de empresa, país, volumen). Hay que
  comprobarlo enviando la solicitud o consultando a Samsung.
- **Si `ActivitySummaryType.TOTAL_CALORIES_BURNED` coincide exactamente** con la cifra "Total de
  calorías quemadas" que muestra la app Samsung Health (misma fuente, mismo corte de día, incluye basal).
  Es muy probable por la descripción, pero no lo dice la documentación; se valida con la usuaria en modo
  desarrollador.
- **Cómo calcula Health Connect el agregado `ENERGY_TOTAL`.** Una fuente secundaria (PR en GitHub,
  https://github.com/Gr0mi4/ohealth-insights/pull/6) afirma que Health Connect rellena los minutos sin
  registros con energía derivada del metabolismo basal, de modo que el agregado puede ser en gran parte
  sintético. La página oficial de agregados no lo menciona. Si se usa Health Connect, hay que verificarlo
  antes de mostrar el total como "medido".
- Si Samsung Health escribe `ActiveCaloriesBurnedRecord` en Health Connect: no aparece en la tabla
  oficial de Samsung; no confirmado en ningún sentido.
- Si Samsung Health **lee** la `NutritionRecord` escrita por otras apps en Health Connect y la muestra:
  el blog dice que "Samsung Health retrieves" datos actualizados de Health Connect, pero no detalla tipos.
- Mapeo exacto del paquete `health` en Android: a qué record de Health Connect corresponden
  `BASAL_ENERGY_BURNED` (Health Connect tiene `BasalMetabolicRateRecord`, que es una tasa, no energía) y
  cómo se calcula `TOTAL_CALORIES_BURNED` en iOS (HealthKit no tiene identificador "total"). No se leyó
  el código nativo.
- **Mantenimiento del paquete `health`:** contradictorio. pub.dev muestra 13.3.2 publicada hace ~50 días,
  pero el fork `health_bridge` (fuente interesada, secundaria) afirma "The upstream package has been
  inactive since early 2026 with 18 unmerged PRs and multiple production-breaking bugs". —
  https://github.com/ytsni/health_bridge (2026-10-03). El README de `health` dice que en Android el teléfono
  necesita Health Connect instalado "(which is currently in beta) and have access to the internet"; ese
  texto parece desactualizado y no se verificó por qué requeriría internet.
- No se encontró paquete Flutter oficial de Samsung para el Health Data SDK; usarlo implicaría un
  platform channel propio (no verificado si existe un paquete comunitario mantenido).
- Meta-análisis O'Driscoll et al. (Br J Sports Med 2020, "How well do activity monitors estimate energy
  expenditure?"): solo leído vía resúmenes de búsqueda (PubMed y el PDF no se pudieron leer):
  heterogeneidad alta, error variable según actividad, la FC + acelerometría reduce el error. —
  https://pubmed.ncbi.nlm.nih.gov/30194221/ (2026-10-03, no leído directamente). La cifra "10–20 % de
  error" de blogs y foros no tiene fuente primaria verificada.
- No se encontró un estudio de validación específico de relojes Galaxy recientes (Watch4 en adelante)
  para gasto energético total diario.
- Versión estable de la librería Jetpack `androidx.health.connect:connect-client`: la guía muestra
  `1.2.0-alpha06`; no se verificó la estable (el paquete Flutter la gestiona).

## Implicaciones para el proyecto

- El dato que la usuaria quiere (promedio de 7 días del "Total de calorías quemadas" de Samsung Health)
  **no está disponible por Health Connect**: Samsung solo envía las calorías de ejercicio
  (`TotalCaloriesBurnedRecord`), no las del activity tracker diario. Por Health Connect sí llegan peso,
  pasos, metabolismo basal (si hay báscula/medición) y nutrición.
- El dato exacto sí existe en el Samsung Health Data SDK (`ActivitySummaryType.TOTAL_CALORIES_BURNED`)
  y funciona en teléfonos no Samsung, pero **publicar exige aprobación de Samsung como partner**, sin
  garantía ni criterios públicos, y requiere código nativo (no hay paquete Flutter oficial). Hasta la
  aprobación, solo sirve en modo desarrollador (no para usuarios).
- Cualquier vía es Strict Path (decide qué datos entran a la app y puede afectar al cálculo de
  mantenimiento en `nutrition_core`); además exige actualizar `docs/privacy.md`, texto de consentimiento
  (dato sensible, Ley 1581) y, en Android, el Health apps declaration form de Play.
- Si la nutrición de la app se escribe en Health Connect/HealthKit, App Store 5.1.3(ii) prohíbe escribir
  datos inexactos: encaja con el invariante "sin inventar precisión" solo si se escriben valores
  confirmados y se excluyen o marcan los de baja confianza (decisión del equipo).
- El aviso de "estimación" puede citar a Samsung ("no es la cifra real de calorías quemadas", depende del
  perfil) y a Shcherbina 2017 (ningún reloj de muñeca bajó del 20 % de error en gasto energético).
- En iOS: el equivalente es activo + basal de HealthKit; los Galaxy Watch modernos no funcionan con
  iPhone, así que el caso Samsung es solo Android.

## Recomendación (no vinculante)

- **Opción A — Health Connect (+ HealthKit) vía paquete `health`.**
  Pros: sin aprobación de terceros (solo la declaración de Play), un paquete Flutter para ambas
  plataformas, peso/pasos/BMR/nutrición y escritura de comidas, datos locales.
  Contras: **no trae el total diario de Samsung Health** (solo calorías de ejercicio), así que no resuelve
  el caso principal de la usuaria; agregado `ENERGY_TOTAL` con posible relleno sintético sin verificar;
  dudas sobre mantenimiento del paquete.
- **Opción B — Samsung Health Data SDK (nativo, platform channel).**
  Pros: entrega exactamente `TOTAL_CALORIES_BURNED` y `TOTAL_ACTIVE_CALORIES_BURNED` diarios, más peso,
  BMR y nutrición; funciona en Motorola.
  Contras: requiere partnership de Samsung para publicar (estado del programa incierto), código nativo a
  mantener, solo Android y solo usuarios de Samsung Health.
- **Opción C — ambas, por fases.** Health Connect/HealthKit para peso, pasos y escritura de nutrición
  (publicable), y el SDK de Samsung para el total diario solo si Samsung aprueba la solicitud;
  mientras tanto se mantiene la entrada manual del "mantenimiento medido".
- Pasos baratos antes de decidir: (1) enviar la solicitud de partnership a Samsung para conocer su estado
  real; (2) en el Motorola de la usuaria, comprobar en Ajustes > Health Connect qué datos de Samsung
  Health aparecen realmente (calorías, peso, pasos) y comparar el agregado de Health Connect con la cifra
  de Samsung Health durante unos días; (3) prototipo en modo desarrollador del SDK de Samsung para validar
  que `ActivitySummaryType.TOTAL_CALORIES_BURNED` coincide con la app.
