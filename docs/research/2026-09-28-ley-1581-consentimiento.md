# Ley 1581 de 2012 aplicada a Calorías IA (PV-07)

Pregunta: ¿Qué exige la Ley 1581 de 2012 y su decreto reglamentario para consentimiento de datos
sensibles (salud), transferencia internacional (Vertex AI fuera de Colombia), Registro Nacional de
Bases de Datos (RNBD) y tratamiento de datos de menores, en una app sin cuentas que envía el texto/
foto de la comida a un backend sin estado que llama a Vertex AI?

Decisión que desbloquea: diseño técnico del consentimiento y borrador de política de privacidad de
SPEC-006 (T-007). **No sustituye revisión legal humana** — así lo dice ya `docs/privacy.md` y se
mantiene aquí.

Nota sobre vigencia: el Decreto 1377 de 2013 (reglamentario de la Ley 1581) fue compilado dentro del
Decreto Único Reglamentario 1074 de 2015 (Título 2, Capítulo 2, secciones 25 y 26 del sector Comercio,
Industria y Turismo). El contenido sustantivo citado abajo sigue vigente bajo esa nueva numeración;
no confirmé artículo por artículo la numeración exacta en el Decreto 1074/2015 (ver NO CONFIRMADO).

## CONFIRMADO

- **Datos sensibles — definición.** Art. 5, Ley 1581/2012: datos sensibles son los que afectan la
  intimidad del titular o cuyo uso indebido puede generar discriminación, incluyendo explícitamente
  los relacionados con la salud. — Ley 1581 de 2012, texto vía alcaldiabogota.gov.co/sisjur
  (https://www.alcaldiabogota.gov.co/sisjur/normas/Norma1.jsp?i=49981, consultado 2026-09-28).
- **Prohibición general y excepción por autorización explícita.** Art. 6, Ley 1581/2012: se prohíbe
  el tratamiento de datos sensibles, EXCEPTO cuando "el Titular haya dado su autorización explícita
  a dicho Tratamiento, salvo en los casos que por ley no sea requerido el otorgamiento de dicha
  autorización". — misma fuente, consultado 2026-09-28.
- **Deberes reforzados de información para datos sensibles.** El decreto reglamentario (art. 6,
  numeración original de Decreto 1377/2013) exige, además de lo anterior: informar explícita y
  previamente cuáles de los datos tratados son sensibles; informar al titular que NO está obligado a
  autorizar su tratamiento; y que "ninguna actividad podrá condicionarse a que el Titular suministre
  datos personales sensibles". — Decreto 1377 de 2013, texto vía alcaldiabogota.gov.co/sisjur
  (https://www.alcaldiabogota.gov.co/sisjur/normas/Norma1.jsp?i=53646, consultado 2026-09-28).
- **Forma de la autorización — no se exige firma ni papel.** Art. 9, Ley 1581/2012: se requiere
  "autorización previa e informada del Titular, la cual deberá ser obtenida por cualquier medio que
  pueda ser objeto de consulta posterior". El decreto (art. 7, numeración original) precisa que puede
  otorgarse "por escrito, de forma oral o mediante conductas inequívocas del titular" y que "en
  ningún caso el silencio podrá asimilarse a una conducta inequívoca". — mismas fuentes,
  consultado 2026-09-28.
- **Doctrina de la SIC sobre casillas de aceptación.** Un concepto/boletín jurídico de la SIC
  confirma que la autorización debe ser previa, expresa e informada, y puede constituirse por medios
  electrónicos (incluye casillas de verificación) siempre que quede en condiciones de poder
  consultarse después; no exige firma digital o física. — Superintendencia de Industria y Comercio,
  "La autorización para el Tratamiento de Datos Personales debe ser previa, expresa e informada"
  (https://www.sic.gov.co/boletin/juridico/habeas-data/la-autorizaci%C3%B3n-para-el-tratamiento-de-datos-personales-debe-ser-previa-expresa-e-informada-los-responsables-y-encargados-del-tratamiento-de-datos-personales,
  consultado 2026-09-28).
- **Transferencia internacional — regla general y excepciones.** Art. 26, Ley 1581/2012: se prohíbe
  transferir datos personales a países que no proporcionen niveles adecuados de protección de datos,
  EXCEPTO en varios casos, entre ellos: el titular ha otorgado su autorización expresa e inequívoca
  para la transferencia; intercambio de datos de carácter médico cuando así lo exija el tratamiento
  del titular por razones de salud o higiene pública; operaciones bancarias/bursátiles; tratados
  internacionales; y ejecución de un contrato entre el titular y el responsable, o entre el
  responsable y un tercero en interés del titular. — Ley 1581 de 2012, misma fuente,
  consultado 2026-09-28.
- **Transmisión (encargado) vs. transferencia (otro responsable).** El decreto distingue entre
  "transferencia internacional" (a otro responsable, sujeta al art. 26 citado arriba) y "transmisión"
  (a un encargado que trata datos por cuenta del responsable, p. ej. un proveedor de nube/IA bajo
  contrato). La transmisión a un encargado no exige por sí sola una autorización adicional del
  titular distinta de la autorización general del tratamiento, siempre que exista un documento
  contractual entre responsable y encargado (obligaciones de confidencialidad, uso solo para los
  fines encomendados, etc.). — Decreto 1377 de 2013 (arts. 24-25, numeración original), vía
  alcaldiabogota.gov.co/sisjur, consultado 2026-09-28.
- **Menores — regla general muy restrictiva.** Art. 7, Ley 1581/2012: "Queda proscrito el
  Tratamiento de datos personales de niños, niñas y adolescentes, salvo aquellos datos que sean de
  naturaleza pública." — misma fuente, consultado 2026-09-28.
- **Menores — mecanismo de excepción bajo el decreto.** El decreto reglamentario (art. 12,
  numeración original) permite tratamiento excepcional de datos de menores cuando responde al
  interés superior del niño/adolescente y respeta sus derechos fundamentales, y en ese caso "el
  representante legal del niño... otorgará la autorización previo ejercicio del menor de su derecho
  a ser escuchado", ponderando su opinión según madurez, autonomía y capacidad de entender el
  asunto. La SIC confirma en su FAQ que los datos de niños, niñas y adolescentes tienen protección
  especial reforzada. — Decreto 1377 de 2013 vía alcaldiabogota.gov.co/sisjur; SIC, "¿Los datos
  personales de los niños, niñas y adolescentes tienen alguna protección especial?"
  (https://www.sic.gov.co/content/%C2%BFlos-datos-personales-de-los-ni%C3%B1os-ni%C3%B1as-y-adolescentes-tienen-alguna-protecci%C3%B3n-especial),
  ambos consultados 2026-09-28.
- **RNBD — quién debe registrarse (nivel de corroboración: fuentes secundarias, no el texto
  reglamentario primario completo).** Múltiples fuentes secundarias (incluye referencias a Decreto
  90 de 2018, que modificó el Decreto 1074/2015) coinciden en que la obligación de inscribirse en el
  Registro Nacional de Bases de Datos aplica a sociedades y entidades sin ánimo de lucro con activos
  totales superiores a 100.000 UVT, y a entidades públicas; y que el Decreto 90 de 2018 eximió
  expresamente a las personas naturales de esta obligación. — SIC, página oficial "Registro Nacional
  de Bases de Datos" (https://www.sic.gov.co/registro-nacional-de-bases-de-datos) y "Preguntas
  frecuentes RNBD" (https://sic.gov.co/preguntas-frecuentes-rnbd), citadas vía resultados de
  búsqueda (no pude leer el cuerpo completo de estas páginas por error de certificado en la
  herramienta de fetch disponible); corroborado por múltiples blogs jurídicos especializados
  (Buk, Vigilantia, Nomikos) citando la misma cifra. Consultado 2026-09-28.
- **ARCO — derechos del titular.** Art. 8, Ley 1581/2012 (no leído literalmente en este ejercicio
  pero referenciado consistentemente en las fuentes anteriores y en el borrador previo de
  `docs/privacy.md`): el titular tiene derecho a conocer, actualizar y rectificar sus datos; a
  solicitar prueba de la autorización otorgada; a ser informado sobre el uso dado a sus datos; a
  presentar quejas ante la SIC; a revocar la autorización y/o solicitar la supresión del dato cuando
  no se respeten los principios, derechos y garantías constitucionales y legales; y a acceder
  gratuitamente a sus datos.

## NO CONFIRMADO / CONTRADICTORIO

- **Numeración exacta vigente en el Decreto 1074 de 2015.** Confirmé que el Decreto 1377/2013 fue
  compilado en el Decreto 1074/2015, pero no verifiqué artículo por artículo la numeración nueva
  (p. ej. si el "art. 12" sobre menores corresponde hoy a "2.2.2.25.12" o a otro número). El
  contenido sustantivo lo tomé del texto original de 2013 vía alcaldiabogota.gov.co, que en su
  encabezado indica ser la versión vigente, pero no cité el Decreto 1074/2015 directamente.
- **Cifra exacta de UVT del RNBD y su base legal primaria.** La cifra de 100.000 UVT y la exención de
  personas naturales la confirmé solo por fuentes secundarias (búsquedas) y no pude leer el texto
  oficial completo de la página de la SIC ni del Decreto 1074/2015 art. 2.2.2.26.1.2 (error de
  certificado SSL en la herramienta de fetch disponible en varios intentos con sic.gov.co,
  secretariasenado.gov.co y funcionpublica.gov.co). Recomiendo verificación humana directa en
  https://www.sic.gov.co/registro-nacional-de-bases-de-datos antes de decidir si aplica o no al
  proyecto.
- **Si el tratamiento vía Vertex AI califica como "transmisión" (encargado) o "transferencia"
  (responsable) bajo la ley colombiana.** Esto depende de los términos contractuales reales de
  Google Cloud/Vertex AI (si actúan como encargado bajo instrucciones del responsable, con un
  contrato de tratamiento de datos que cumpla el art. 25 del decreto) — no encontré ni evalué el
  contrato/DPA de Google Cloud en este ejercicio (queda parcialmente cubierto por PV-03, pero ese
  ítem tampoco cerró la lectura visual del texto oficial). Esta calificación cambia qué mecanismo de
  la Ley 1581 aplica (autorización general suficiente vs. autorización expresa e inequívoca
  específica para la transferencia) y es una determinación legal, no técnica.
- **Tensión entre "ninguna actividad podrá condicionarse a que el Titular suministre datos sensibles"
  y el hecho de que el propósito central de la app ES procesar datos de salud/nutrición.** No
  encontré doctrina de la SIC que resuelva directamente este caso (un servicio cuyo objeto mismo es
  tratar el dato sensible, a diferencia del ejemplo típico de "no puedes exigir religión para vender
  un plan de telefonía"). Queda como pregunta abierta para el abogado: ¿basta con que el aviso deje
  claro que el dato sensible es indispensable para el servicio solicitado, o se requiere alguna
  redacción específica adicional?
- **Si el "canal de atención" para ejercer derechos ARCO existe hoy en el diseño de SPEC-006.** No es
  una pregunta legal sino una brecha de diseño que detecté al comparar la ley con el plan: no vi
  mención de un correo/canal de contacto del responsable en el borrador de política de privacidad.

## Implicaciones para el proyecto

- El checkbox de consentimiento planeado en SPEC-006, si el texto es claro, específico (nombra que
  el dato es de salud/nutrición, qué se envía, a quién — Vertex AI/Google, fuera de Colombia — y para
  qué), y no viene premarcado, es coherente con lo que exige la ley para autorización de datos
  sensibles (Art. 6 Ley 1581 + Art. 6-7 del decreto) y no requiere firma ni papel (Art. 9 Ley 1581).
  Esto confirma que el enfoque planeado (checkbox in-app) es una forma válida, no que sea
  automáticamente suficiente en su redacción exacta — eso lo debe revisar el abogado.
- El mismo texto de consentimiento debería declarar explícitamente que el dato sale de Colombia hacia
  servidores de Google (Vertex AI) fuera del país. Esto cubre el escenario más conservador (que se
  trate como "transferencia" y no solo "transmisión") sin necesitar un segundo checkbox separado,
  igual que ya lo prevé el borrador de `docs/privacy.md`.
- El RNBD probablemente NO aplica a una app en etapa temprana operada por una persona natural o una
  empresa con activos muy por debajo de 100.000 UVT, pero esto depende de la estructura legal real
  del negocio (persona natural vs. sociedad) y debe reverificarse cuando haya estados financieros
  reales o al escalar — no es una decisión que se pueda cerrar solo con este documento.
- Declarar "confirmo ser mayor de 18 años" sin pedir fecha de nacimiento es coherente con el
  principio de minimización de datos del proyecto y evita activamente entrar en el régimen mucho más
  estricto y operacionalmente inviable para esta app (representante legal + derecho del menor a ser
  oído) que aplica si se llegara a tratar datos de un menor. No encontré un requisito legal
  colombiano que exija verificación de identidad/edad más fuerte que la autodeclaración para este
  tipo de app; la autodeclaración es una medida técnica razonable, no una garantía legal absoluta —
  el abogado debe confirmar si el equipo quiere/necesita alguna medida adicional (p. ej. bloquear el
  uso si el usuario marca que es menor).
- "Borrar todos mis datos" + "exportar mis datos" cubren gran parte del espíritu de ARCO porque no
  hay copia remota de los datos personales que rectificar/eliminar (todo vive en el dispositivo). Sin
  embargo, la política de privacidad debería incluir de todas formas un canal de contacto (correo)
  del responsable del tratamiento para consultas, quejas o el ejercicio de derechos relacionados con
  cualquier dato que sí procese un tercero (p. ej. metadatos de Cloud Logging, o preguntas generales)
  — esto parece faltar en el borrador actual y es fácil de agregar sin implicar nuevos datos que
  salgan del dispositivo.

## Recomendación (no vinculante)

- Mantener el diseño de checkbox único, no premarcado, con texto explícito que mencione: naturaleza
  de dato de salud, qué se envía, a quién (Vertex AI/Google, fuera de Colombia) y con qué fin (nunca
  para calcular, solo estructurar). Confirmar la redacción final con el abogado antes de publicar.
- Añadir un correo/canal de contacto visible en la política de privacidad para ejercer derechos ARCO,
  aunque no haya cuenta ni backend con estado.
- Antes de fusionar SPEC-006: pedir al abogado que confirme específicamente (a) si el contrato de
  Google Cloud/Vertex AI aplicable califica como "encargado" bajo el Decreto 1074/2015 o si se
  requiere tratar el envío como transferencia con autorización expresa separada, y (b) si el umbral
  de 100.000 UVT del RNBD aplica o no a la estructura legal real del proyecto.
- No añadir verificación de identidad/edad más allá de la autodeclaración por ahora; documentar la
  decisión en la SPEC como una limitación conocida y aceptada.
