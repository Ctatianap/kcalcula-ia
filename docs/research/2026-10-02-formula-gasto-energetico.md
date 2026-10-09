# Fórmula de gasto energético de mantenimiento y reparto de macronutrientes para adultos (PV-13)

Pregunta: ¿Qué ecuación institucional y citable sirve para sugerir (no prescribir) las kcal diarias
de mantenimiento de un adulto a partir de peso (kg), estatura (cm), edad (años), sexo y nivel de
actividad? ¿Con qué coeficientes exactos, qué niveles de actividad, qué casos de referencia
calculados por la propia fuente, qué umbral mínimo de kcal (si lo hay) y qué precisión? Ampliación
(pedida por el coordinador): ¿qué rangos de distribución de macronutrientes, qué recomendación de
proteína en g/kg, si alguna fuente da un reparto "por defecto" y qué factores kcal/g usar para
convertir % de energía a gramos?

Decisión que desbloquea: SPEC-008 (T-009) — OQ1 (fórmula), OQ2 (niveles de actividad y textos),
OQ4 (rangos/mínimos), OQ7 (umbral de seguridad de kcal), AC3 (casos de referencia con fuente) y la
nueva sugerencia de macros.

Fecha de consulta de todas las fuentes: 2026-10-02.

Nota de método: la herramienta de lectura web resume las páginas con un modelo pequeño. Los
coeficientes y tablas de abajo se pidieron "verbatim" y, cuando fue posible, se contrastaron
recalculando los ejemplos de la propia fuente (ver "Comprobación de consistencia"). Aun así,
antes de fijarlos en código conviene que una persona los compare visualmente con la página
original (sobre todo la Tabla 5-5 y la Tabla 7-1 de las DRI 2023, y la Tabla 12 de la Res. 3803).
Varios PDF (NHLBI, ICBF, minsalud.gov.co) no se pudieron leer con la herramienta disponible.

---

## CONFIRMADO

### 1. Ecuaciones de gasto energético

**A. DRI for Energy 2023 (National Academies of Sciences, Engineering, and Medicine, NASEM) —
ecuaciones de gasto energético total (TEE/EER), ya incluyen la actividad física**

- El informe *Dietary Reference Intakes for Energy* (NASEM, 2023), capítulo 5 "Development of
  Prediction Equations for Estimated Energy Requirements", Tabla 5-5, da ecuaciones de TEE para
  adultos de 19 años o más, por sexo y categoría de PAL (edad en años, estatura en cm, peso en kg,
  resultado en kcal/día):
  - Hombres 19+:
    - Inactive: TEE = 753.07 – (10.83 × edad) + (6.50 × estatura) + (14.10 × peso)
    - Low active: TEE = 581.47 – (10.83 × edad) + (8.30 × estatura) + (14.94 × peso)
    - Active: TEE = 1,004.82 – (10.83 × edad) + (6.52 × estatura) + (15.91 × peso)
    - Very active: TEE = –517.88 – (10.83 × edad) + (15.61 × estatura) + (19.11 × peso)
    - Desempeño del modelo: R² = 0.73; RMSE = 339 kcal/d; MAPE = 9.4 %; MAE = 266 kcal/d
  - Mujeres 19+:
    - Inactive: TEE = 584.90 – (7.01 × edad) + (5.72 × estatura) + (11.71 × peso)
    - Low active: TEE = 575.77 – (7.01 × edad) + (6.60 × estatura) + (12.14 × peso)
    - Active: TEE = 710.25 – (7.01 × edad) + (6.54 × estatura) + (12.34 × peso)
    - Very active: TEE = 511.83 – (7.01 × edad) + (9.07 × estatura) + (12.56 × peso)
    - Desempeño del modelo: R² = 0.71; RMSE = 246 kcal/d; MAPE = 8.7 %; MAE = 191 kcal/d
  — [NASEM 2023, cap. 5](https://www.nationalacademies.org/read/26818/chapter/7) (consultado 2026-10-02)
- Población de derivación (adultos): 5.456 observaciones de agua doblemente marcada (DLW), 19 años
  o más, edad media 52,6 años (DE 19,7). Incluye personas con peso normal y con sobrepeso/obesidad;
  según el informe, las pendientes no difirieron significativamente entre grupos de IMC (una sola
  ecuación para todo el rango de IMC). Incluye la submuestra SOLNAS: 380 participantes
  hispanos/latinos (ascendencia centroamericana, cubana, dominicana, mexicana, puertorriqueña y
  suramericana); la etnia no se usó como covariable.
  — [NASEM 2023, cap. 5](https://www.nationalacademies.org/read/26818/chapter/7) (consultado 2026-10-02)

**B. Mifflin-St Jeor (1990) — gasto energético en reposo (REE), sin actividad**

- Cita correcta: Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO. "A new predictive
  equation for resting energy expenditure in healthy individuals." **American Journal of Clinical
  Nutrition** 1990;51(2):241-247. DOI 10.1093/ajcn/51.2.241. (Ojo: se publicó en *Am J Clin Nutr*,
  no en *J Am Diet Assoc* como dice la pregunta.)
  — [Europe PMC, registro PMID 2305711](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:2305711&resultType=core&format=json) (consultado 2026-10-02)
- Coeficientes, transcritos del resumen del artículo original:
  - "REE = 9.99 x weight + 6.25 x height - 4.92 x age + 166 x sex (males, 1; females, 0) - 161"
  - "REE (males) = 10 x weight (kg) + 6.25 x height (cm) - 5 x age (y) + 5"
  - "REE (females) = 10 x weight (kg) + 6.25 x height (cm) - 5 x age (y) - 161"
  — [Europe PMC, PMID 2305711](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:2305711&resultType=core&format=json) (consultado 2026-10-02)
- Población: "498 healthy subjects, including females (n = 247) and males (n = 251), aged 19-78 y
  (45 +/- 14 y, mean +/- SD)"; "Normal-weight (n = 264) and obese (n = 234)"; REE medido por
  calorimetría indirecta. "The Harris-Benedict Equations derived in 1919 overestimated measured REE
  by 5%".
  — [Europe PMC, PMID 2305711](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:2305711&resultType=core&format=json) (consultado 2026-10-02)
- Respaldo institucional: la Academy of Nutrition and Dietetics (Evidence Analysis Library, guía
  *Adult Weight Management*, "Determination of Resting Metabolic Rate") recomienda: "Estimated
  energy needs should be based on RMR. If possible, RMR should be measured (e.g., indirect
  calorimetry). If RMR cannot be measured, then the Mifflin-St. Jeor equation using actual weight
  is the most accurate for estimating RMR for overweight and obese individuals." Calificación:
  Strong | Conditional. Población objetivo: adultos con sobrepeso u obesidad. La página no muestra
  fecha de la guía.
  — [andeal.org, AWM Determination of RMR](https://www.andeal.org/template.cfm?template=guide_summary&key=621) (consultado 2026-10-02)
- Revisión sistemática de la ADA (hoy Academy): Frankenfield D, Roth-Yousey L, Compher C. *J Am
  Diet Assoc* 2005;105(5):775-789, DOI 10.1016/j.jada.2005.02.005. Conclusión del resumen: de las
  cuatro ecuaciones más usadas (Harris-Benedict, Mifflin-St Jeor, Owen y WHO/FAO/UNU), "the
  Mifflin-St Jeor equation was the most reliable, predicting RMR within 10% of measured in more
  nonobese and obese individuals than any other equation, and it also had the narrowest error
  range". También: "No validation work concentrating on individual errors was found for the
  WHO/FAO/UNU equation" y "Older adults and US-residing ethnic minorities were underrepresented".
  — [Europe PMC, PMID 15883556](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:15883556&resultType=core&format=json) (consultado 2026-10-02)
  (Probablemente esta es la referencia "J Am Diet Assoc" que se tenía en mente.)

**C. FAO/OMS/UNU 2001 (publicado 2004) — tasa metabólica basal (BMR) solo por peso (Schofield)**

- *Human energy requirements*, Report of a Joint FAO/WHO/UNU Expert Consultation, Tabla 5.2
  "Equations for estimating BMR from body weight" (fuente: Schofield, 1985), adultos, kcal/día
  (peso en kg):
  - Hombres 18-30: 15.057 kg + 692.2 (DE 153) · 30-60: 11.472 kg + 873.1 (DE 167) · ≥60: 11.711 kg + 587.7 (DE 164)
  - Mujeres 18-30: 14.818 kg + 486.6 (DE 119) · 30-60: 8.126 kg + 845.6 (DE 111) · ≥60: 9.082 kg + 658.5 (DE 108)
  - (también en MJ/día: p. ej. hombres 18-30: 0.063 kg + 2.896)
  — [FAO, Human energy requirements, cap. 5](https://www.fao.org/4/y5686e/y5686e07.htm) (consultado 2026-10-02)
- No usa estatura. Frankenfield 2005 no encontró validación de error individual para esta ecuación
  (ver arriba).

**D. Colombia — Resolución 3803 de 2016 (MinSalud), RIEN**

- El texto compilado de la Res. 3803/2016 define el PAL (art. 3, num. 3.29) con tres categorías:
  Ligera (Sedentaria) 1,40–1,69; Moderada (Moderadamente activo) 1,70–1,99; Fuerte (Activo)
  2,00–2,40. Adopta como base científica las recomendaciones del comité FAO/OMS/UNU.
  — [Normograma Invima, Res. 3803/2016](https://normograma.invima.gov.co/compilacion/docs/resolucion_minsaludps_3803_2016.htm) (consultado 2026-10-02)
- En el texto HTML compilado **no aparecen ecuaciones de TMB con coeficientes ni una tabla de
  energía para adultos**; solo tablas para lactantes (Tabla 6), 1-18 años (Tabla 7), y adicionales
  de gestación y lactancia (Tablas 10-11). Ver NO CONFIRMADO sobre la "Tabla 8".
  — [Normograma Invima, Res. 3803/2016](https://normograma.invima.gov.co/compilacion/docs/resolucion_minsaludps_3803_2016.htm) (consultado 2026-10-02)

### 2. Niveles de actividad física (PAL)

**DRI 2023 (NASEM)**
- Rangos de PAL para adultos 19+ (Tabla 5-4): Inactive 1,00 ≤ PAL < 1,53; Low active
  1,53 ≤ PAL < 1,68; Active 1,68 ≤ PAL < 1,85; Very active 1,85 ≤ PAL < 2,50.
  — [NASEM 2023, cap. 5](https://www.nationalacademies.org/read/26818/chapter/7) (consultado 2026-10-02)
- Descripción funcional (cap. 5): Inactive = metabolismo basal "and a minimal level of physical
  activity"; Low active = "more ambulation, and some occupational and recreational activities";
  Active = "even more ambulation, and occupational or recreational activities"; Very active =
  "vigorous exertion in occupation or recreation".
  — [NASEM 2023, cap. 5](https://www.nationalacademies.org/read/26818/chapter/7) (consultado 2026-10-02)
- Ejemplos de actividad diaria por categoría (cap. 7, Tabla 7-1, adultos; "ADL" = actividades de
  la vida diaria):
  - Inactive (PAL ~1,4): "ADL only"
  - Low active (PAL ~1,6): "ADL + 60–80 minutes walking (3–4 mph)"
  - Active (PAL ~1,75): "ADL + 30–50 minutes walking (3–4 mph) + 45 minutes moderate cycling +
    40 minutes doubles tennis"
  - Very active (PAL ~2,05): "ADL + 45 minutes moderate cycling + ~25 minutes jogging (10 min/mile)
    + 60 minutes doubles tennis"
  — [NASEM 2023, cap. 7](https://www.nationalacademies.org/read/26818/chapter/9) (consultado 2026-10-02)
  (Transcripción hecha por la herramienta; verificar visualmente antes de traducir.)
- Advertencia de la propia fuente: "At present, it appears that a valid, reliable tool does not
  exist to enable accurate classification of an individual's PAL category."
  — [NASEM 2023, cap. 7](https://www.nationalacademies.org/read/26818/chapter/9) (consultado 2026-10-02)

**FAO/OMS/UNU 2001 (y Res. 3803/2016, que la adopta)**
- Tabla 5.3: Sedentary or light activity lifestyle 1,40–1,69; Active or moderately active
  1,70–1,99; Vigorous or vigorously active 2,00–2,40 (valores > 2,40 difíciles de sostener).
  Ejemplos de estilo de vida con PAL medio calculado: sedentario "36.7/24 = 1.53"; activo
  "42.2/24 = 1.76"; vigoroso "53.9/24 = 2.25". Ejemplos de personas: sedentario = oficinistas
  urbanos; moderado = obreros de construcción; vigoroso = jornaleros agrícolas con herramientas
  manuales o ~2 h diarias de actividad intensa (natación, baile).
  — [FAO, Human energy requirements, cap. 5](https://www.fao.org/4/y5686e/y5686e07.htm) (consultado 2026-10-02)

**Mifflin-St Jeor**
- El artículo de 1990 (según su resumen) solo da REE; **no define factores de actividad**.
  — [Europe PMC, PMID 2305711](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:2305711&resultType=core&format=json) (consultado 2026-10-02)
- La guía de la Academy consultada tampoco menciona multiplicadores de actividad.
  — [andeal.org](https://www.andeal.org/template.cfm?template=guide_summary&key=621) (consultado 2026-10-02)

### 3. Casos de referencia calculados por la fuente

**Mifflin-St Jeor:** en las fuentes leídas (resumen del artículo, Academy, Frankenfield 2005)
**no hay ejemplos resueltos**. No se inventan.

**DRI 2023 (NASEM): sí hay ejemplos resueltos y tablas calculadas por la fuente.**

- Ejemplos individuales (cap. 7):
  1. Mujer de 22 años, 165 cm, 63 kg, Low active → **2.275 kcal/día** (ecuación de mujer Low active).
     La fuente añade: ~68 % de mujeres con esas características tendrían un requerimiento real
     entre 2.034 y 2.516 kcal/d, y el 95 % entre 1.803 y 2.747 kcal/d.
  2. Mujer de 70 años, 157 cm, 70 kg, Inactive → **1.812 kcal/día** (SEPV = 241).
  (El tercer ejemplo del capítulo es un chico de 15 años: fuera del alcance, la app es 18+.)
  — [NASEM 2023, cap. 7](https://www.nationalacademies.org/read/26818/chapter/9) (consultado 2026-10-02)
- Tablas 7-9 (hombres EE. UU.) y 7-10 (mujeres EE. UU.), "Estimated Energy Requirements (EER) for
  Overall Population". Nota al pie: "Age used to predict EER is based on specific age: 19–30 y:
  25 y; 31–50 y: 40 y; 51–70 y: 60 y; > 70 y: 80 y; 19 y or older: 50 y." Es decir, cada fila es
  un caso de referencia completo (edad, estatura, peso, PAL → kcal):

  Hombres (Tabla 7-9):

  | Edad usada | Estatura (cm) | Peso (kg) | Inactive | Low active | Active | Very active |
  |---|---|---|---|---|---|---|
  | 25 | 176,1 | 81,4 | 2.775 | 2.988 | 3.177 | 3.516 |
  | 40 | 176,3 | 89,9 | 2.733 | 2.955 | 3.151 | 3.519 |
  | 60 | 174,9 | 88,7 | 2.491 | 2.709 | 2.907 | 3.258 |
  | 80 | 172,2 | 83,3 | 2.181 | 2.389 | 2.586 | 2.896 |
  | 50 | 175,4 | 87,2 | 2.581 | 2.799 | 2.994 | 3.345 |

  Mujeres (Tabla 7-10):

  | Edad usada | Estatura (cm) | Peso (kg) | Inactive | Low active | Active | Very active |
  |---|---|---|---|---|---|---|
  | 25 | 162,7 | 69,3 | 2.152 | 2.316 | 2.454 | 2.683 |
  | 40 | 162,5 | 75,0 | 2.112 | 2.278 | 2.418 | 2.647 |
  | 60 | 160,8 | 74,8 | 1.960 | 2.125 | 2.264 | 2.489 |
  | 80 | 156,8 | 69,7 | 1.737 | 1.896 | 2.035 | 2.249 |
  | 50 | 161,2 | 73,2 | 2.014 | 2.178 | 2.317 | 2.543 |

  (Las Tablas 7-13 y 7-14 traen lo mismo para población canadiense.)
  — [NASEM 2023, cap. 7](https://www.nationalacademies.org/read/26818/chapter/9) (consultado 2026-10-02)

- **Comprobación de consistencia** (no es un dato nuevo; solo verifica que la transcripción de
  ecuaciones y tablas concuerda): aplicando las ecuaciones de la Tabla 5-5 a las entradas de la
  fuente se obtiene, sin redondear, 2.275,37 (ej. 1 → 2.275), 1.811,94 (ej. 2 → 1.812),
  2.774,71 (H 25 a Inactive → 2.775), 2.708,52 (H 60 a Low active → 2.709), 3.151,41 (H 40 a
  Active → 3.151), 2.895,63 (H 80 a Very active → 2.896), 2.151,80 (M 25 a Inactive → 2.152),
  1.896,01 (M 80 a Low active → 1.896) y 2.489,17 (M 60 a Very active → 2.489). Todos coinciden
  con el valor publicado al redondear a entero. Las estaturas y pesos de las tablas están
  redondeados a un decimal, así que en tests conviene una tolerancia de ±1 kcal.

**FAO/OMS/UNU 2001:** trae tablas de requerimiento por peso con factores 1,45/1,60/1,75/1,90 ×
BMR (p. ej. Tabla 5.4, hombres 18-29,9 años: 50 kg → 8,8 / 9,7 / 10,6 / 11,5 MJ/día) y un
ejemplo poblacional (mujeres 20-30 años, 55 kg, PAL 1,85: "5.45 × 1.85 = 10.08 MJ/day
(2 410 kcal/day)"). Son resultados en MJ redondeados a un decimal y por peso solamente.
— [FAO, Human energy requirements, sec. 5.4](https://www.fao.org/4/y5686e/y5686e08.htm) (consultado 2026-10-02)

### 4. Umbral mínimo de kcal

- NHLBI (*Aim for a Healthy Weight*): "Eating plans containing 1,000–1,200 calories will help most
  women to lose weight safely"; planes de 1.200–1.600 kcal "are suitable for men and may also be
  appropriate for women who weigh 165 pounds or more or who exercise regularly". Son rangos de
  **plan para bajar de peso**, no un piso de seguridad. (Texto obtenido de los fragmentos del
  buscador que citan el PDF oficial; el PDF no se pudo leer completo con la herramienta.)
  — [NHLBI, publicación 05-5213 (PDF)](https://www.nhlbi.nih.gov/sites/default/files/publications/05-5213.pdf) (consultado 2026-10-02)
- Guía AHA/ACC/TOS 2013 de sobrepeso y obesidad: como uno de los métodos para reducir la ingesta,
  prescribir 1.200–1.500 kcal/d en mujeres y 1.500–1.800 kcal/d en hombres, ajustando según el
  peso, dentro de una intervención integral. Es una **prescripción para pérdida de peso**, no un
  mínimo. (Texto obtenido de fragmentos del buscador; el sitio de AHA devolvió 403 y PMC pidió
  CAPTCHA.)
  — [AHA/ACC/TOS 2013, Circulation](https://www.ahajournals.org/doi/10.1161/01.cir.0000437739.71477.ee) (consultado 2026-10-02)
- NIH, National Task Force on the Prevention and Treatment of Obesity, "Very low-calorie diets",
  *JAMA* 1993;270:967-974: los VLCD son dietas de "3350 kJ/d (800 kcal/d) or less" y "are generally
  safe when used under proper medical supervision in moderately and severely obese patients (body
  mass index [...] > 30)".
  — [Europe PMC, PMID 8345648](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:8345648&resultType=core&format=json) (consultado 2026-10-02)
- Conclusión: el único umbral con respaldo institucional explícito de "supervisión médica" que se
  encontró es **≤ 800 kcal/día** (VLCD). **No se encontró ninguna fuente institucional que fije
  1.200 kcal (mujeres) / 1.500 kcal (hombres) como mínimo que no se deba sugerir sin supervisión
  médica.** Esas cifras aparecen en guías como rangos de plan para adelgazar.

### 5. Precisión (para la advertencia de "estimación")

- DRI 2023: error estándar del valor predicho (SEPV) de **241 kcal/d en mujeres y 342 kcal/d en
  hombres**; error porcentual absoluto medio (MAPE) 8,7 % (mujeres) y 9,4 % (hombres). En el
  ejemplo de la mujer de 22 años (2.275 kcal), el 95 % de las personas con esas características
  tendría un requerimiento real entre 1.803 y 2.747 kcal/d. La fuente dice que comer el EER calculado
  "could result in weight maintenance [...], weight gain [...], or weight loss" según el
  requerimiento real, y recomienda calcular el EER y luego "monitor body weight over time and
  adjust energy intake as needed".
  — [NASEM 2023, cap. 5](https://www.nationalacademies.org/read/26818/chapter/7) y [cap. 7](https://www.nationalacademies.org/read/26818/chapter/9) (consultado 2026-10-02)
- Mifflin-St Jeor en personas con obesidad (Academy): predijo el RMR dentro del ±10 % del valor
  medido en el 70 % de los casos, con hasta 9 % de sobreestimaciones y 21 % de subestimaciones
  (nueve estudios transversales). Harris-Benedict: 39–64 % dentro del ±10 %.
  — [andeal.org](https://www.andeal.org/template.cfm?template=guide_summary&key=621) (consultado 2026-10-02)
- Frankenfield 2005: Mifflin-St Jeor es la ecuación con más probabilidad de quedar dentro del
  ±10 %, "but noteworthy errors and limitations exist when it is applied to individuals".
  — [Europe PMC, PMID 15883556](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:15883556&resultType=core&format=json) (consultado 2026-10-02)

---

## Macronutrientes (ampliación)

### 6. Rangos de distribución (% de la energía)

- **Colombia — Res. 3803/2016 (RIEN), Tabla 1** "Metas de ingesta de macronutrientes para la
  población colombiana expresadas en Rangos de Distribución Aceptable de Macronutrientes (AMDR)",
  columna ADULTOS: **Proteínas 14-20 %; Grasa total 20-35 %; Carbohidratos 50-65 %**. (Niños 1-3:
  10-20 / 30-40 / 50-65; niños 4-18: 10-20 / 25-35 / 50-65.) Definición (art. 3, num. 3.34): "rango
  de ingesta de una fuente de energía que se asocia con reducción en el riesgo de enfermedad
  crónica, mientras aporta cantidades adecuadas de nutrientes esenciales. Se expresa como porcentaje
  de la ingesta total de energía."
  — [Normograma Invima, Res. 3803/2016](https://normograma.invima.gov.co/compilacion/docs/resolucion_minsaludps_3803_2016.htm) (consultado 2026-10-02)
- **DRI (EE. UU./Canadá), AMDR vigentes para adultos:** proteína 10–35 %, carbohidratos 45–65 %,
  grasa 20–35 %.
  — [NASEM 2024, *Rethinking the AMDR for the 21st Century: A Letter Report*](https://www.nationalacademies.org/read/27957/chapter/5) (consultado 2026-10-02)
- **OMS/FAO 2003 (TRS 916), Tabla 6** "Ranges of population nutrient intake goals": grasa total
  15–30 %, carbohidratos totales 55–75 %, proteína 10–15 % (además: grasas saturadas < 10 %,
  azúcares libres < 10 %). Son **metas poblacionales** ("the population average intake that is
  judged to be consistent with the maintenance of health in a population"), no recomendaciones
  individuales.
  — [FAO/WHO, Diet, Nutrition and the Prevention of Chronic Diseases, cap. 5](https://www.fao.org/4/ac911e/ac911e07.htm) (consultado 2026-10-02)

### 7. Proteína en g/kg de peso

- **Colombia — Res. 3803/2016, Tabla 12** "Recomendaciones de ingesta de proteínas para la
  población colombiana": hombres y mujeres de 19-30, 31-50, 51-70 y > 70 años: **EAR 0,92 g/kg/día;
  RDA 1,11 g/kg/día; AMDR 14-20 %**. Nota: "Los valores de EAR y RDA han sido ajustados por calidad
  de proteína (digestibilidad 80% y cómputo aminoacídico 90%)."
  — [Normograma Invima, Res. 3803/2016](https://normograma.invima.gov.co/compilacion/docs/resolucion_minsaludps_3803_2016.htm) (consultado 2026-10-02)
- ¿Mínimo u objetivo? Una RDA es, por definición, la ingesta que cubre el requerimiento de casi
  todos (97–98 %) los individuos sanos; para proteína se describe como la ingesta más baja que
  cubre a casi todos, es decir, un **nivel de suficiencia (mínimo práctico), no un objetivo
  óptimo**. Esta caracterización viene de una revisión revisada por pares (fuente secundaria):
  Advances in Nutrition 2022, "Optimizing Protein Intake in Adults: Interpretation and Application
  of the RDA Compared with the AMDR".
  — [Advances in Nutrition 2022](https://advances.nutrition.org/article/S2161-8313(22)00716-5/fulltext) (consultado 2026-10-02, vía fragmento del buscador)
- Para usar el RDA en g/kg y el AMDR en % a la vez: son dos restricciones distintas; con pocas kcal
  y mucho peso, 1,11 g/kg puede superar el 20 % de la energía (o al revés). Ninguna fuente leída
  dice cuál prima.

### 8. ¿Reparto "por defecto"?

- **Ninguna de las fuentes leídas propone un único número por macro.** La Res. 3803/2016, las DRI
  (AMDR) y la OMS/FAO dan **rangos**. El informe NASEM 2024 sobre el AMDR tampoco recomienda un
  valor puntual dentro del rango.
  — [Res. 3803/2016](https://normograma.invima.gov.co/compilacion/docs/resolucion_minsaludps_3803_2016.htm); [NASEM 2024](https://www.nationalacademies.org/read/27957/chapter/5) (consultados 2026-10-02)
- Por tanto, cualquier punto concreto (p. ej. el centro de cada rango) sería una **decisión de
  producto**, no una recomendación de la fuente, y así debería explicarse.

### 9. Factores de conversión de energía (kcal/g)

- FAO, *Food energy – methods of analysis and conversion factors* (FAO Food and Nutrition Paper 77,
  Roma, 2003), sección 3.5.1 "The Atwater general factor system": "The energy values are 17 kJ/g
  (4.0 kcal/g) for protein, 37 kJ/g (9.0 kcal/g) for fat and 17 kJ/g (4.0 kcal/g) for
  carbohydrates." Alcohol: 29 kJ/g (7,0 kcal/g).
  — [FAO FNP 77, cap. 3](https://www.fao.org/4/y5022e/y5022e04.htm); [portada](https://www.fao.org/4/y5022e/y5022e00.htm) (consultados 2026-10-02)
- La Res. 3803/2016 (texto compilado) **no** trae factores kcal/g explícitos.
  — [Normograma Invima](https://normograma.invima.gov.co/compilacion/docs/resolucion_minsaludps_3803_2016.htm) (consultado 2026-10-02)
- Observación interna: el repo ya usa 4/4/9 en `data/SOURCES.md` y en la validación Atwater, sin
  cita primaria; esta referencia de FAO puede servir para ambos usos.

---

## NO CONFIRMADO / CONTRADICTORIO

- **Factores de actividad 1,2 / 1,375 / 1,55 / 1,725 / 1,9** que suelen acompañar a Mifflin-St Jeor
  en calculadoras: solo aparecen en sitios secundarios (calculadoras comerciales, blogs). **No se
  encontró fuente primaria ni institucional** para ellos. No usarlos.
- **Ejemplos resueltos de Mifflin-St Jeor:** no hay en las fuentes leídas. La calculadora de
  Medscape existe, pero es una herramienta de terceros, no la fuente.
- **Tabla de energía para adultos de la Res. 3803/2016 ("Tabla 8")**: un resultado del buscador
  dice que la Tabla 8 trae requerimientos para hombres de 18 años o más por estatura e IMC en
  kcal/kg con factores 1,45 y 1,60 × TMB, y que la guía metodológica de MinSalud usa
  ER = TMB × PAL. **No se pudo verificar**: el HTML de Invima no la muestra (quizá es imagen) y los
  PDF de [minsalud.gov.co](https://www.minsalud.gov.co/Normatividad_Nuevo/Resoluci%C3%B3n%203803%20de%202016.pdf),
  la [guía metodológica RIEN](https://www.minsalud.gov.co/sites/rid/Lists/BibliotecaDigital/RIDE/VS/PP/SNA/Guia-metodologica-rien-individuos.pdf)
  y el [resumen RIEN del ICBF](https://www.icbf.gov.co/sites/default/files/resumen_rien.pdf) no se
  pudieron leer con la herramienta. Requiere revisión humana del PDF.
- **Texto exacto de NHLBI y AHA/ACC/TOS 2013** sobre 1.000–1.200 / 1.200–1.600 y 1.200–1.500 /
  1.500–1.800 kcal: confirmado solo por fragmentos del buscador, no leído en la página.
- **RDA de proteína de EE. UU. (0,8 g/kg/día; EAR 0,66)**: confirmado solo por fuentes
  secundarias (revisiones revisadas por pares); el capítulo 10 de las DRI 2005 en NAP no mostró
  texto legible. Para Colombia rige el 1,11 g/kg/día de la Res. 3803 (ajustado por calidad).
- **Tabla 7-1 de las DRI 2023** (ejemplos de actividad por PAL): transcrita por la herramienta;
  verificar visualmente el texto y los valores de PAL aproximados (~1,4 / ~1,6 / ~1,75 / ~2,05).
- **Fecha de la recomendación de la Academy (EAL)**: la página no la muestra.
- **Contradicción de umbrales de PAL**: DRI 2023 (inactive < 1,53; low active 1,53–1,68 …) y
  FAO/Res. 3803 (ligera 1,40–1,69; moderada 1,70–1,99; fuerte 2,00–2,40) no coinciden: son
  sistemas distintos y no deben mezclarse.

## Implicaciones para el proyecto

- **Dos caminos coherentes y citables:**
  1. **DRI 2023 (NASEM)**: una ecuación por sexo y nivel de actividad que da directamente kcal de
     mantenimiento con peso, estatura, edad y sexo (las mismas entradas que pide SPEC-008), sin
     multiplicadores aparte. Trae casos resueltos por la fuente (2 individuales + 20 filas de
     tablas de adultos por sexo) para AC3, y cifras de error (SEPV, intervalos) para la advertencia.
     Incluye personas con sobrepeso/obesidad y una submuestra latina. Inconveniente: es una
     referencia de EE. UU./Canadá, no colombiana.
  2. **FAO/OMS/UNU 2001 + Res. 3803/2016**: es el marco que adopta Colombia (tres niveles de PAL),
     pero la BMR solo usa peso (la estatura sobraría), las tablas vienen en MJ redondeados y la
     tabla de adultos de la Res. 3803 no se pudo leer. Hoy no daría 4 casos de referencia
     verificados con las mismas entradas.
- **Mifflin-St Jeor** tiene el mejor respaldo clínico para REE (Academy, Frankenfield 2005), pero
  sin factores de actividad institucionales ni ejemplos resueltos **no cumple AC3** tal como está
  redactado, ni el invariante 8/9 para la parte de actividad.
- **Niveles de actividad (OQ2):** con DRI 2023 serían 4 niveles (inactive, low active, active,
  very active) con ejemplos concretos (minutos de caminata, etc.) que se pueden traducir a es-CO
  convirtiendo mph a km/h. La propia fuente advierte que no hay una herramienta fiable para que
  una persona elija su categoría: eso justifica presentar el resultado como estimación.
- **Umbral (OQ7):** no hay un piso institucional de 1.200/1.500 kcal. Lo único citable con
  "supervisión médica" es ≤ 800 kcal/d (VLCD, NIH 1993). Un umbral de 1.200/1.500 sería una
  decisión de producto apoyada en que esas cifras aparecen en guías como planes de adelgazamiento
  (NHLBI, AHA 2013), no una norma.
- **Macros:** para Colombia, la Res. 3803/2016 da rangos de adultos (P 14-20 %, G 20-35 %,
  CH 50-65 %) y RDA de proteína 1,11 g/kg/día; ninguna fuente fija un reparto único. Factores
  4/4/9 citables a FAO FNP 77 (2003).
- **Datos de salud:** peso, estatura, edad, sexo y actividad son datos sensibles; esto ya está en
  OQ6 de la SPEC y no cambia con esta nota.

## Recomendación (no vinculante)

- Usar las **ecuaciones de TEE de las DRI 2023 (NASEM, Tabla 5-5)** para la sugerencia de kcal de
  mantenimiento, con los **4 niveles** de PAL de la fuente y sus ejemplos de actividad (Tabla 7-1)
  traducidos a es-CO. Para AC3, usar como casos de referencia los dos ejemplos individuales del
  cap. 7 y filas de las Tablas 7-9/7-10 (con la edad de la nota al pie), con tolerancia ±1 kcal.
- Antes de codificar, que una persona compare visualmente las Tablas 5-4, 5-5, 7-1, 7-9 y 7-10
  con la página de NAP.
- En la advertencia de "estimación", citar la variabilidad de la fuente (p. ej. "para personas con
  tus datos, el requerimiento real puede variar en unos ±240 kcal (mujeres) / ±340 kcal (hombres)")
  y la recomendación de ajustar según la evolución del peso.
- Para OQ7, si se quiere un umbral duro, el único citable con supervisión médica es ≤ 800 kcal/d;
  cualquier advertencia en 1.200/1.500 debe documentarse como decisión de producto.
- Para macros, si se sugieren: usar los rangos de la Res. 3803/2016 (fuente colombiana) y explicar
  el punto elegido como decisión de producto; convertir con 4/4/9 (FAO FNP 77). Decidir de forma
  explícita qué hacer cuando 1,11 g/kg de proteína cae fuera del 14-20 %.
- Si el equipo prefiere el marco colombiano (FAO/Res. 3803), pedir a una persona que lea la tabla
  de adultos de la Res. 3803 y la guía metodológica de MinSalud en PDF antes de decidir.
