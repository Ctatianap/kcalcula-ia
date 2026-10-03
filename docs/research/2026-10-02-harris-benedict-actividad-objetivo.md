# Harris-Benedict, factores de actividad, ajuste por objetivo y macros por g/kg (PV-14)

Pregunta: ¿Qué fuente citable respalda una sugerencia de kcal "estilo fitgeneration" (Harris-Benedict ×
factor de actividad con 5 niveles por días de ejercicio a la semana + ajuste por objetivo: bajar grasa /
mantener / ganar masa muscular), con coeficientes, factores y porcentajes exactos y casos de referencia
calculados por la fuente? Ampliación (pedida por el coordinador): ¿qué fuentes de nutrición deportiva
respaldan repartir macros en g/kg (proteína 1,5–2,0 g/kg, grasa 0,7 g/kg, carbohidratos 2–3 g/kg)?

Decisión que desbloquea: cambio de SPEC-008 (sugerencia de kcal y de macros) — elegir ecuación,
niveles de actividad, ajuste por objetivo y reparto de macros; definir casos de referencia para tests
de `nutrition_core`. Antecedente: [PV-13](2026-10-02-formula-gasto-energetico.md).

Fecha de consulta de todas las fuentes: 2026-10-02.

Nota de método: la herramienta de lectura web resume con un modelo pequeño. Para Harris y Benedict
se leyeron **las imágenes escaneadas de las páginas originales** (PNAS en PMC; monografía de 1919 en
Internet Archive) y se transcribieron directamente. Los PDF de NHLBI, Dietitians of Canada y EFSA se
leyeron completos. El resto viene de resúmenes de la herramienta; se marca cuando aplica.

---

## CONFIRMADO

### 1. Harris-Benedict: coeficientes exactos

**(a) Original — Harris JA, Benedict FG, PNAS 1918;4(12):370-373 (fuente primaria, página 373 escaneada)**

Texto literal:
> "The closest prediction of the daily heat production of a subject can be made by the use of the
> multiple regression equations,
> For men, h = 66.4730 + 13.7516 w + 5.0033 s − 6.7550 a
> For women, h = 655.0955 + 9.5634 w + 1.8496 s − 4.6756 a
> where h = total heat production per 24 hours, w = weight in kilograms, s = stature in centimeters,
> and a = age in years. These equations have been tabulated for values of weight from 25.0 to 124.9
> kgm., for stature from 151 to 200 cm., and for age from 21 to 70 years [...]"

- Población (p. 371): "Measurements on 136 men, 103 women and 94 new-born infants".
- Remite a la monografía: "Publication No. 279 of the Carnegie Institution of Washington".
— [PMC1091498, p. 373 (imagen)](https://cdn.ncbi.nlm.nih.gov/pmc/blobs/6e3d/1091498/204ffb0bd743/pnas01945-0021.png);
[p. 371](https://cdn.ncbi.nlm.nih.gov/pmc/blobs/6e3d/1091498/7449a464316c/pnas01945-0019.png);
[ficha PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC1091498/) (consultado 2026-10-02)

- Unidades: h en "calories per 24 hours" (kcal/día), peso en kg, estatura en cm, edad en años.
- Rango de validez tabulado por los autores: peso 25,0–124,9 kg, estatura 151–200 cm, edad 21–70 años.

**(b) Revisada — Roza AM, Shizgal HM, Am J Clin Nutr 1984;40(1):168-182, DOI 10.1093/ajcn/40.1.168**

- El artículo primario **no se pudo leer** (AJCN devolvió 403; OUP 404). Solo el resumen: las
  ecuaciones originales, evaluadas con datos de 98 sujetos adicionales, estiman el gasto en reposo con
  "precision of 14%"; predicen bien en personas bien nutridas pero "underestimated the measured value"
  en desnutridos y son "unreliable in the malnourished patient".
  — [Europe PMC, PMID 6741850](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=Roza%20Shizgal%20Harris%20Benedict%20reevaluated&resultType=core&format=json) (consultado 2026-10-02)
- Coeficientes reproducidos por una **fuente institucional** (Maastricht UMC+, departamento de
  Dietética, *Nutritional Assessment*), que cita a Roza y Shizgal 1984:
  - Hombres: 88.362 + (13.397 × W) + (4.799 × H) − (5.677 × A)
  - Mujeres: 447.593 + (9.247 × W) + (3.098 × H) − (4.33 × A)
  - La página dice: "This revised formule is currently used by dieticians of the Maastricht UMC+."
  — [Maastricht UMC+, Calculating energy expenditure](https://nutritionalassessment.mumc.nl/en/calculating-energy-expenditure) (consultado 2026-10-02)
  - Ojo (error de la página): define "Height (H) in meter", pero con estos coeficientes la estatura
    tiene que ir en cm (con metros el término de estatura quedaría en ~5–8 kcal). Ver NO CONFIRMADO.
- La misma página reproduce la original con los mismos coeficientes que el PNAS (66.4730 / 13.7516 /
  5.0033 / 6.7550; 655.0955 / 9.5634 / 1.8496 / 4.6756), lo que corrobora la transcripción.

**¿Qué institución recomienda Harris-Benedict hoy?**

- **Dietitians of Canada, Academy of Nutrition and Dietetics y ACSM (posición conjunta 2016,
  *Nutrition and Athletic Performance*)**: "Although population-specific regression equations are
  encouraged, a reasonable estimate of BMR can be obtained using either the Cunningham or the
  Harris-Benedict equations, with an appropriate activity factor being applied to estimate TEE." La
  referencia que citan para Harris-Benedict es **Roza y Shizgal 1984** (la revisada). **No dan valores
  de factor de actividad.** El documento dice estar vigente "until December 31, 2019".
  — [Dietitians of Canada, PDF de la posición, p. 7 y ref. 5](https://www.dietitians.ca/DietitiansOfCanada/media/Documents/Resources/noap-position-paper.pdf?ext=.pdf) (consultado 2026-10-02)
- **Maastricht UMC+** usa la revisada de Roza-Shizgal en su práctica clínica y advierte que
  "the (updated) Harris and Benedict formula is known to overestimate the resting energy metabolism".
  — [Maastricht UMC+](https://nutritionalassessment.mumc.nl/en/calculating-energy-expenditure) (consultado 2026-10-02)
- **Academy of Nutrition and Dietetics (EAL, manejo de peso en adultos)** recomienda Mifflin-St Jeor,
  no Harris-Benedict, para personas con sobrepeso u obesidad (ver PV-13).
  — [andeal.org](https://www.andeal.org/template.cfm?template=guide_summary&key=621) (consultado 2026-10-02)
- **ESPEN (Bendavid et al., Clin Nutr 2021;40:690-701, "The centenary of the Harris-Benedict
  equations")**: en la mayoría de los entornos clínicos las ecuaciones tienen rendimiento bajo a
  moderado, "with the best generally reaching an accuracy of no more than 70%"; recomiendan calorimetría
  indirecta cuando esté disponible. (Solo resumen; texto completo con 403.)
  — [Europe PMC, PMID 33279311](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=centenary%20Harris-Benedict%20equations%20ESPEN%20expert%20group&resultType=core&format=json) (consultado 2026-10-02)

**Precisión frente a Mifflin-St Jeor y DRI 2023**

- Mifflin et al. 1990 (resumen): "The Harris-Benedict Equations derived in 1919 overestimated measured
  REE by 5%". — [Europe PMC, PMID 2305711](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:2305711&resultType=core&format=json) (consultado 2026-10-02)
- Academy EAL: en personas con obesidad, Mifflin-St Jeor predijo dentro de ±10 % en el 70 % de los
  casos; Harris-Benedict, en el 39–64 %. — [andeal.org](https://www.andeal.org/template.cfm?template=guide_summary&key=621) (consultado 2026-10-02)
- Frankenfield, Roth-Yousey, Compher, *J Am Diet Assoc* 2005;105:775-789: de Harris-Benedict, Mifflin-St
  Jeor, Owen y OMS/FAO/UNU, "the Mifflin-St Jeor equation was the most reliable". El resumen no da
  cifras propias para Harris-Benedict. — [Europe PMC, PMID 15883556](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:15883556&resultType=core&format=json) (consultado 2026-10-02)
- DRI 2023 (NASEM): predice **gasto total** (no basal), MAPE 8,7 % (mujeres) y 9,4 % (hombres)
  (ver PV-13). No es comparable directamente con las cifras de REE de arriba; no se encontró una
  comparación directa Harris-Benedict vs DRI 2023.

### 2. Factores de actividad

- **No se encontró ninguna fuente primaria, institucional ni académica que publique la escala
  1,2 / 1,375 / 1,55 / 1,725 / 1,9 con descripciones por días de ejercicio.** Aparece solo en
  calculadoras comerciales, blogs y patentes. Los resúmenes del buscador atribuyen su origen a fuentes
  distintas y contradictorias (Mifflin 1990; FAO/OMS/UNU 1985), y ambas atribuciones se contradicen
  con las propias fuentes:
  - El resumen de Mifflin 1990 solo da REE, sin factores (PV-13).
  - FAO/OMS/UNU 1985 usó PAL de **1,55 / 1,78 / 2,10** (hombres, actividad ligera/moderada/intensa) y
    **1,56 / 1,64 / 1,82** (mujeres), según la guía EU Menu de EFSA.
    — [EFSA, EU Menu Guidance, Appendix 8.2.1, p. 4](https://www.efsa.europa.eu/sites/default/files/efsa_rep/blobserver_assets/3944A-8-2-1.pdf) (consultado 2026-10-02)
- Conjuntos de PAL institucionales que sí existen (ninguno coincide con 1,2–1,9), según el mismo
  documento de EFSA (pp. 4-5):
  - FAO/OMS/UNU 2004, adultos: ligera 1,40–1,69; moderada 1,70–1,99; vigorosa 2,00–2,40.
  - IOM 2005: sedentario 1,0–1,39; poco activo 1,4–1,59; activo 1,6–1,89; muy activo 1,9–2,49.
  - SACN (Reino Unido) 2011: 1,49 / 1,63 / 1,78.
  - EFSA 2013 (adultos): 1,4 / 1,6 / 1,8 / 2,0 / >2,0.
  — [EFSA, EU Menu Guidance, Appendix 8.2.1](https://www.efsa.europa.eu/sites/default/files/efsa_rep/blobserver_assets/3944A-8-2-1.pdf) (consultado 2026-10-02)
- Maastricht UMC+ (uso clínico con Harris-Benedict) suma porcentajes, no multiplica por la escala
  1,2–1,9: "Bedridden + 10% / Ambulant + 20% / Small amount of activity + 30% / Mediate activity + 40%"
  y "Weight gain desired + 30%" (población hospitalaria).
  — [Maastricht UMC+, PDF Additions](https://nutritionalassessment.mumc.nl/sites/nutritionalassessment/files/energy_expenditure_measurement_additions.pdf) (consultado 2026-10-02)
- DC/AND/ACSM 2016 menciona "an appropriate activity factor" pero sin valores (ver §1).

### 3. Ajuste por objetivo

**Bajar grasa — déficit en kcal fijas (institucional)**

- NHLBI/NAASO, *The Practical Guide* (NIH Pub. 00-4084, octubre 2000): "Caloric intake should be
  reduced by 500 to 1,000 calories per day (kcal/day) from the current level." "Reductions of 500 to
  1,000 kcal/day will produce a recommended weight loss of 1 to 2 pounds per week." "For individuals
  who are overweight, a deficit of 300 to 500 kcal/day may be more appropriate, providing a weight loss
  of about 0.5 pounds per week." También: la dieta "should not be too low (less than 800 kcal/day)".
  Población: adultos con sobrepeso/obesidad.
  — [NHLBI, Practical Guide (PDF), pp. 2, 3, 19, 23](https://www.nhlbi.nih.gov/files/docs/guidelines/prctgd_c.pdf) (consultado 2026-10-02)
- AHA/ACC/TOS 2013 (Jensen et al., Circulation 2014;129:S102-38), recomendación de grado A:
  "Prescribe a 500-kcal/d or 750-kcal/d energy deficit"; la declaración de evidencia ES1 menciona
  "prescription of an energy deficit of 500 kcal/d or 750 kcal/d or 30% energy deficit".
  — [PMC5819889](https://pmc.ncbi.nlm.nih.gov/articles/PMC5819889/) (consultado 2026-10-02, vía resumen de la herramienta)
- **Contexto deportivo** — DC/AND/ACSM 2016: "for most athletes, the practical approach of decreasing
  energy intake by ~250 to 500 kcal/d from their periodized energy needs [...] can achieve progress
  towards short-term body composition goals over approximately 3 to 6 weeks"; "FFM and performance may
  be better preserved in athletes who minimize weekly weight loss to < 1% per week".
  — [Dietitians of Canada, PDF, p. 11](https://www.dietitians.ca/DietitiansOfCanada/media/Documents/Resources/noap-position-paper.pdf?ext=.pdf) (consultado 2026-10-02)
- Helms, Aragon, Fitschen, *J Int Soc Sports Nutr* 2014;11:20 (preparación de culturismo natural):
  pérdidas de peso de "approximately 0.5 to 1%/wk".
  — [PMC4033492](https://pmc.ncbi.nlm.nih.gov/articles/PMC4033492/) (consultado 2026-10-02)

**Bajar grasa — déficit en %**

- El único % institucional encontrado es el **30 %** de AHA/ACC/TOS 2013 (en la declaración de
  evidencia, no en el texto de la recomendación). **El rango 10–25 % que muestra fitgeneration no tiene
  cita en la propia página** (la frase no lleva número de referencia) y no se encontró en ninguna fuente
  institucional o académica.

**Ganar masa muscular — superávit**

- Iraki, Fitschen, Espinar, Helms, *Sports* (Basel) 2019;7(7):154, DOI 10.3390/sports7070154 (revisión
  narrativa sobre culturistas en "off-season"): "A hyper-energetic diet (~10–20%)" sobre mantenimiento;
  para avanzados "+5–10% above maintenance"; ganancia objetivo "~0.25–0.5% of bodyweight/week for
  novice/intermediate".
  — [PMC6680710](https://pmc.ncbi.nlm.nih.gov/articles/PMC6680710/) (consultado 2026-10-02)
- Maastricht UMC+ (clínico, no deportivo): "Weight gain desired + 30%" sobre el gasto.
  — [Maastricht UMC+, PDF Additions](https://nutritionalassessment.mumc.nl/sites/nutritionalassessment/files/energy_expenditure_measurement_additions.pdf) (consultado 2026-10-02)
- No se encontró un superávit recomendado por un organismo de salud pública para ganar músculo.

### 4. Casos de referencia calculados por la fuente

**Harris y Benedict 1919 sí trae ejemplos resueltos** (monografía Carnegie Publ. 279, p. 230, leída de
la imagen escaneada):

> "In constructing these tables the constant term of the equation and the corrective term for
> body-weight are combined in table I for men and table III for women. The corrective term for stature
> and age is given in table II for men and table IV for women. These tables must be used in conjunction
> only. [...] Three examples follow:"

| Caso | Sexo | Edad | Estatura (cm) | Peso (kg) | Tabla I/III | Tabla II/IV | "Predicted calories" |
|---|---|---|---|---|---|---|---|
| 1 | Hombre | 27 | 172 | 77,2 | 1128 | 678 | **1806** |
| 2 | Mujer | 22 | 166 | 77,2 | 1393 | 204 | **1597** |
| 3 | Mujer | 66 | 162 | 62,3 | 1251 | −9 | **1242** |

— [Internet Archive, *A biometric study of basal metabolism in man*, p. 230 (imagen n239)](https://archive.org/details/biometricstudyof00harruoft) (consultado 2026-10-02)

Además, las tablas del apéndice (pp. 253 en adelante) son, en sí mismas, cientos de valores calculados
por la fuente. Ejemplos leídos: Tabla I (hombres, factor por peso), 70,0 kg → 1029; Tabla II (hombres,
factor por estatura y edad), 170 cm y 35 años → 614.
— [Internet Archive, p. 253 (imagen n262) y p. 256 (imagen n265)](https://archive.org/details/biometricstudyof00harruoft) (consultado 2026-10-02)

**Comprobación de consistencia** (no es dato nuevo; verifica la transcripción): con las ecuaciones del
PNAS, Tabla I = 66,4730 + 13,7516·w y Tabla II = 5,0033·s − 6,7550·a, redondeadas por separado:
- Caso 1: 1128,10 + 678,18 → 1128 + 678 = 1806. Ecuación sin redondear: **1806,28**.
- Caso 2: 1393,39 + 204,17 → 1393 + 204 = 1597. Ecuación sin redondear: **1597,56** (redondeada
  directamente daría **1598**: la fuente suma partes ya redondeadas).
- Caso 3: 1250,90 + (−8,95) → 1251 + (−9) = 1242. Ecuación sin redondear: **1241,94**.
- Tabla I 70,0 kg: 1029,09 → 1029 ✓. Tabla II 170 cm/35 a: 614,14 → 614 ✓.
Conclusión: en tests, tolerancia de **±1 kcal** frente a "Predicted calories".

**Roza y Shizgal 1984:** no se pudo leer el artículo; **no hay casos resueltos confirmados**.
**Escala 1,2–1,9 y ajustes por objetivo:** no hay fuente con ejemplos resueltos (no hay fuente).

### 5. fitgeneration.es (dato, no fuente)

- La página muestra como "Original 1918": hombres "RMB = 66 + (13.75 x peso en kg) + (5 x altura en cm)
  – (6.75 x edad en años)"; mujeres "RMB = 655 + (9.56 x peso en kg) + (1.85 x altura en cm) - (4.68 x
  edad en años)". También muestra Mifflin-St Jeor y dice que "la variante más utilizada en la actualidad
  es la propuesta por Mifflin y St. Jeor en 1990" (y que Mifflin "revisaron la fórmula original", lo cual
  no es exacto: la revisión de Harris-Benedict es la de Roza-Shizgal; Mifflin es otra ecuación).
- **No dice qué ecuación calcula su calculadora** y **no muestra los factores numéricos** de actividad.
  Opciones del formulario: "Sedentario: poco o nada de ejercicio al día"; "Actividad ligera: ejercicio
  ligero o deporte 1-3 días a la semana"; "Actividad moderada: ejercicio moderado o deporte 3-5 días a
  la semana"; "Actividad intensa: ejercicio intenso o deporte 6-7 días a la semana"; "Actividad muy
  intensa: ejercicio muy intenso o trabajo físico y ejercicio diario".
- Déficit: "Los rangos se sitúan entre el 10% y el 25% de déficit respecto al Gasto Energético Diario",
  sin número de referencia. El superávit y los macros están en una "Tabla 1" en imagen (no legible).
- Referencias listadas: Harris y Benedict 1918 (PNAS), Mifflin 1990, Cunningham 1991, De Lorenzo 1999,
  Jagim 2019, Tinsley 2019, Strock 2020, Fields 2022, Sordi 2022, Siedler 2023, Katch y McArdle 1975.
  Ninguna corresponde a la escala de factores ni al 10–25 %.
  — [fitgeneration.es, calculadora Harris-Benedict](https://fitgeneration.es/calculadora/harris-benedict/) (consultado 2026-10-02)
- **Coincidencia con la original:** sus coeficientes son los del PNAS 1918 **redondeados** (66,4730→66;
  13,7516→13,75; 5,0033→5; 6,7550→6,75; 655,0955→655; 9,5634→9,56; 1,8496→1,85; 4,6756→4,68). Con los
  tres casos de la fuente dan 1805,25 / 1597,17 / 1241,41 (cálculo propio), es decir, hasta ~1 kcal de
  diferencia frente a la ecuación exacta.

---

## Macronutrientes por g/kg para adultos que entrenan (ampliación)

### 6. Proteína

- **ISSN, Jäger et al. 2017**, *J Int Soc Sports Nutr* 14:20, DOI 10.1186/s12970-017-0177-8:
  punto 2, "an overall daily protein intake in the range of 1.4–2.0 g protein/kg body weight/day (g/kg/d)
  is sufficient for most exercising individuals"; punto 3, "Higher protein intakes (2.3–3.1 g/kg/d) may
  be needed to maximize the retention of lean body mass in resistance-trained subjects during hypocaloric
  periods"; punto 5, "0.25 g of a high-quality protein per kg of body weight, or an absolute dose of
  20–40 g" por comida.
  — [PMC5477153](https://pmc.ncbi.nlm.nih.gov/articles/PMC5477153/) (consultado 2026-10-02)
- **DC/AND/ACSM 2016** (Thomas, Erdman, Burke): "dietary protein intake necessary to support metabolic
  adaptation, repair, remodeling, and for protein turnover generally ranges from 1.2 to 2.0 g/kg/d.
  Higher intakes may be indicated for short periods during intensified training or when reducing energy
  intake." Y: "In cases of energy restriction or sudden inactivity [...] elevated protein intakes as high
  as 2.0 g/kg/day or higher when spread over the day may be advantageous in preventing FFM loss."
  Por comida: "0.3 g/kg BW after key exercise sessions and every 3 to 5 hours over multiple meals".
  — [Dietitians of Canada, PDF, p. 17 y resumen p. 36](https://www.dietitians.ca/DietitiansOfCanada/media/Documents/Resources/noap-position-paper.pdf?ext=.pdf) (consultado 2026-10-02)
- **Morton et al., *Br J Sports Med* 2018;52(6):376-384** (publicado en línea 2017), DOI
  10.1136/bjsports-2017-097608, metaanálisis: "Protein supplementation beyond total protein intakes of
  1.62 g/kg/day resulted in no further RET-induced gains in FFM"; IC 95 % del punto de corte
  1,03–2,20 g/kg/día; sugieren "~2.2 g protein/kg/d for those seeking to maximise resistance
  training-induced gains in FFM".
  — [PMC5867436](https://pmc.ncbi.nlm.nih.gov/articles/PMC5867436/) (consultado 2026-10-02)
- **Helms et al. 2014** (déficit, preparación de competencia): "2.3-3.1 g/kg of lean body mass per day
  of protein" (ojo: por kg de **masa magra**, no de peso total).
  — [PMC4033492](https://pmc.ncbi.nlm.nih.gov/articles/PMC4033492/) (consultado 2026-10-02)
- **Iraki et al. 2019** (superávit): "Sufficient protein (1.6–2.2 g/kg/day)".
  — [PMC6680710](https://pmc.ncbi.nlm.nih.gov/articles/PMC6680710/) (consultado 2026-10-02)
- **ISSN, Kerksick et al. 2018**, *J Int Soc Sports Nutr* 15:38: "1.2–2.0 g/kg/day" (entrenamiento
  moderado), "1.4–1.8 g/kg/d" (entrenamiento intenso), "1.7–2.2 g/kg/day" (alto volumen), según el
  resumen de la herramienta.
  — [PMC6090881](https://pmc.ncbi.nlm.nih.gov/articles/PMC6090881/) (consultado 2026-10-02)
- **Conclusión:** el rango de la usuaria, **1,5–2,0 g/kg**, cae dentro de ISSN 2017 (1,4–2,0) y
  DC/AND/ACSM 2016 (1,2–2,0). En déficit, las fuentes suben el techo (ISSN: 2,3–3,1 g/kg; Helms: 2,3–3,1
  g/kg de masa magra; DC/AND/ACSM: "2.0 g/kg/day or higher").

### 7. Grasa

- **En % de energía:** DC/AND/ACSM 2016: "For most athletes, fat intakes [...] typically range from 20%
  to 35% of total energy intake. Consuming ≤20% of energy intake from fat does not benefit performance";
  "Athletes should be discouraged from chronic implementation of fat intakes below 20% of energy intake
  since the reduction in dietary variety often associated with such restrictions is likely to reduce the
  intake of a variety of nutrients such as fat-soluble vitamins and essential fatty acids".
  — [Dietitians of Canada, PDF, pp. 18-19 y 36](https://www.dietitians.ca/DietitiansOfCanada/media/Documents/Resources/noap-position-paper.pdf?ext=.pdf) (consultado 2026-10-02)
  Helms 2014: "15-30% of calories from fat" (sin g/kg). Kerksick 2018: "Generally, it is recommended
  that athletes consume a moderate amount of fat (approximately 30% of their daily caloric intake)."
- **En g/kg:**
  - Iraki 2019 (superávit): "Fat should be consumed in moderate amounts (0.5–1.5 g/kg/day)".
    — [PMC6680710](https://pmc.ncbi.nlm.nih.gov/articles/PMC6680710/) (consultado 2026-10-02)
  - Kerksick 2018 (para reducir grasa corporal): "dietary fat intakes ranging from 0.5 to 1 g/kg/day
    have been recommended results in situations where daily fat intake might comprise as little as 20%
    of total calories in the diet."
    — [PMC6090881](https://pmc.ncbi.nlm.nih.gov/articles/PMC6090881/) (consultado 2026-10-02)
- **Salud hormonal:** Whittaker y Wu, *J Steroid Biochem Mol Biol* 2021;210:105878 (metaanálisis, 6
  estudios, 206 participantes): "low-fat diets appear to decrease testosterone levels in men"; piden más
  ECA. No fija un mínimo en g/kg.
  — [Europe PMC, PMID 33741447](https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=%22Low-fat%20diets%20and%20testosterone%20in%20men%22&resultType=core&format=json) (consultado 2026-10-02)
  El único mínimo con respaldo institucional es el **20 % de la energía** de DC/AND/ACSM, justificado
  por vitaminas liposolubles y ácidos grasos esenciales, no por hormonas.
- **0,7 g/kg** no aparece como valor puntual en ninguna fuente; está **dentro** de 0,5–1,0 (Kerksick,
  pérdida de grasa) y 0,5–1,5 (Iraki, superávit).

### 8. Carbohidratos según volumen de entrenamiento

- **DC/AND/ACSM 2016, Tabla 1, "Daily needs for fuel and recovery"** (transcripción del PDF):

  | Nivel | Situación | Objetivo |
  |---|---|---|
  | Light | "Low intensity or skill-based activities" | "3-5 g/kg of athlete's BW/d" |
  | Moderate | "Moderate exercise program (e.g., ~1 h/d)" | "5-7 g/kg/d" |
  | High | "Endurance program (e.g., 1-3 h/d mod-high-intensity exercise)" | "6-10 g/kg/d" |
  | Very High | "Extreme commitment (e.g., > 4-5 h/d mod-high intensity exercise" | "8-12 g/kg/d" |

  Notas de la misma tabla: los objetivos buscan "high carbohydrate availability" para sesiones de alta
  calidad o intensidad; "when exercise quality or intensity is less important, it may be less important
  to achieve these carbohydrate targets [...] carbohydrate intake may be chosen to suit energy goals,
  food preferences, or food availability".
  — [Dietitians of Canada, PDF, p. 15](https://www.dietitians.ca/DietitiansOfCanada/media/Documents/Resources/noap-position-paper.pdf?ext=.pdf) (consultado 2026-10-02)
- Kerksick 2018: "45–55% CHO [3–5 g/kg/day]" para forma física general; "5–8 g/kg/day" moderado;
  "8–10 g/day of carbohydrate (i.e., 400–1500 g/day for 50–150 kg athletes)" en alto volumen (así está
  escrito, sin "/kg"; por el ejemplo entre paréntesis parece referirse a g/kg).
  — [PMC6090881](https://pmc.ncbi.nlm.nih.gov/articles/PMC6090881/) (consultado 2026-10-02)
- Iraki 2019 (superávit): "Remaining calories should come from carbohydrates with focus on consuming
  sufficient amounts (≥3–5 g/kg/day)".
- **2–3 g/kg no aparece en ninguna fuente leída**; queda **por debajo** del mínimo de todas
  (3 g/kg). La única puerta que abren DC/AND/ACSM es elegir los carbohidratos según "energy goals"
  cuando la calidad de la sesión importa menos, sin dar un número.

### 9. Coherencia: ¿proteína y grasa en g/kg y carbohidratos "del resto"?

- **Sí está descrito así en fuentes académicas de culturismo**:
  - Iraki 2019: proteína 1,6–2,2 g/kg, grasa 0,5–1,5 g/kg y "Remaining calories should come from
    carbohydrates". — [PMC6680710](https://pmc.ncbi.nlm.nih.gov/articles/PMC6680710/) (consultado 2026-10-02)
  - Helms 2014: primero las kcal; luego proteína 2,3–3,1 g/kg de masa magra, grasa 15–30 % de las kcal
    y "the reminder [sic] of calories from carbohydrate".
    — [PMC4033492](https://pmc.ncbi.nlm.nih.gov/articles/PMC4033492/) (consultado 2026-10-02)
- **DC/AND/ACSM 2016 no lo describe como "resto"**: fija carbohidratos y proteína en g/kg según la carga
  de entrenamiento y la grasa en % (20–35 %), e individualiza según la energía total. No se encontró
  ninguna fuente que fije los **tres** macros en g/kg y derive las kcal de su suma.

---

## NO CONFIRMADO / CONTRADICTORIO

- **Texto primario de Roza y Shizgal 1984**: no leído (403/404). Los coeficientes vienen de Maastricht
  UMC+, que además tiene un error de unidades ("Height in meter"). Los valores 88.362 / 13.397 / 4.799 /
  5.677 y 447.593 / 9.247 / 3.098 / 4.330 coinciden con numerosas fuentes secundarias (calculadoras), lo
  que no es confirmación primaria. Requiere que una persona lea el PDF de AJCN (posible acceso
  institucional) antes de codificarlos.
- **Origen de la escala 1,2 / 1,375 / 1,55 / 1,725 / 1,9**: sin fuente. Las atribuciones a McArdle,
  Katch y Katch, a Mifflin 1990 o a FAO/OMS/UNU 1985 no se pudieron verificar y las dos últimas se
  contradicen con lo que dicen esas fuentes. No se consultó el libro *Exercise Physiology* (no hay copia
  accesible).
- **Déficit 10–25 %** (fitgeneration): sin fuente. **Superávit en la "Tabla 1" de fitgeneration**:
  ilegible (imagen).
- **Fórmula que calcula realmente fitgeneration**: la página no lo dice.
- **AHA/ACC/TOS 2013**: el "30% energy deficit" se leyó vía resumen de la herramienta sobre PMC, no
  transcrito de la imagen/PDF.
- **Kerksick 2018**: valores de proteína y carbohidratos obtenidos por resumen de la herramienta; las
  frases de grasa y de "8–10 g/day" sí se pidieron literales.
- **Vigencia de DC/AND/ACSM 2016**: el documento dice "in effect until December 31, 2019". No se
  verificó si fue reafirmado o reemplazado.
- **Whittaker y Wu 2021**: cifras de efecto (p. ej., −10–15 % de testosterona al pasar de 40 % a 20 % de
  grasa) solo en fuentes secundarias; el resumen de Europe PMC no las trae.
- **Morton 2018**: año de volumen 2018 (52:376-384); la herramienta reportó 2017 (publicación en línea).

## Implicaciones para el proyecto

- **Harris-Benedict es citable** en su forma original (PNAS 1918, transcrita de la imagen primaria) y
  tiene **3 casos resueltos por la propia fuente** + tablas, aptos para tests con ±1 kcal. La revisada
  (Roza-Shizgal) tiene respaldo institucional de uso (DC/AND/ACSM la citan; Maastricht la usa), pero sus
  coeficientes no están verificados en la fuente primaria y no tiene casos resueltos.
- La población de la original es de 1918 (136 hombres, 103 mujeres; 21–70 años; 25–125 kg;
  151–200 cm). Fuera de ese rango, la fuente no da valores tabulados.
- Las fuentes de precisión (Mifflin 1990, Academy EAL, ESPEN 2021) indican que Harris-Benedict **tiende a
  sobrestimar** y es menos precisa que Mifflin-St Jeor. Cambiar de DRI 2023 (PV-13) a Harris-Benedict
  sería una decisión de producto, no de exactitud.
- **La escala 1,2–1,9 no cumple el invariante 8/9** (sin fuente). Si se quieren 5 niveles por días de
  ejercicio, no hay fuente que dé esos números con esas descripciones. Las alternativas con fuente son
  los PAL institucionales (FAO 2004, IOM 2005, EFSA 2013), cuyas descripciones no son por "días a la
  semana", o seguir con las 4 ecuaciones de la DRI 2023.
- **Ajuste por objetivo con fuente:** déficit en kcal fijas (NHLBI 500–1.000; AHA 500/750; deportivo
  DC/AND/ACSM 250–500) o 30 % (AHA, población con obesidad). Superávit: solo Iraki 2019 (10–20 %; 5–10 %
  avanzados), revisión narrativa en culturistas, no guía institucional.
- **Macros por g/kg:** proteína 1,5–2,0 y grasa 0,7 g/kg caben dentro de rangos publicados. Carbohidratos
  2–3 g/kg **no tienen respaldo**. El esquema "proteína y grasa en g/kg, carbohidratos del resto" está
  descrito por Iraki 2019 (y Helms 2014 con grasa en %).
- **Choque de restricciones:** grasa fija en g/kg puede quedar por debajo del 20 % de energía que
  DC/AND/ACSM desaconseja de forma crónica (cálculo propio con 9 kcal/g de FAO: 70 kg × 0,7 g/kg = 49 g
  = 441 kcal, que es 14,7 % de 3.000 kcal). Hay que decidir qué prima.
- Esto cambia la población objetivo de SPEC-008 (fitness frente a población general) y las fuentes
  colombianas (Res. 3803/2016) dejarían de ser la base de los macros: decisión explícita del equipo.

## Recomendación (no vinculante)

- Si se adopta Harris-Benedict, usar la **original de 1918** (fuente primaria leída) y como tests los
  **3 ejemplos de la p. 230** de la monografía de 1919 (tolerancia ±1 kcal), o filas de las Tablas I–IV.
  No usar la revisada de Roza-Shizgal hasta que una persona lea el artículo de AJCN.
- No codificar la escala 1,2–1,9 ni el 10–25 %: no tienen fuente. Opciones citables: (a) mantener DRI
  2023 con 4 niveles (PV-13), o (b) Harris-Benedict × PAL de un organismo (p. ej., EFSA 2013:
  1,4 / 1,6 / 1,8 / 2,0), dejando explícito que la traducción a "días de ejercicio por semana" sería
  decisión de producto.
- Objetivo "bajar grasa": un déficit en kcal fijas con fuente (p. ej., 250–500 kcal/d de DC/AND/ACSM
  para personas que entrenan, o 500 kcal/d de NHLBI/AHA). "Ganar masa": si se usa 10–20 %, citar Iraki
  2019 y decir que es una revisión en culturistas.
- Macros: proteína 1,4–2,0 g/kg (ISSN 2017) y grasa con piso del 20 % de la energía (DC/AND/ACSM) además
  del g/kg; carbohidratos del resto (Iraki 2019), con aviso si bajan de 3 g/kg (mínimo de DC/AND/ACSM y
  Kerksick). Documentar en la SPEC qué regla gana cuando chocan.
- Pedir a una persona: leer Roza y Shizgal 1984 (AJCN), confirmar la "Tabla 1" de fitgeneration y
  verificar si la posición DC/AND/ACSM fue reafirmada después de 2019.
