# TCAC 2018 (ICBF) — licencia, atribución y formato

Pregunta: ¿La Tabla de Composición de Alimentos Colombianos (TCAC) 2018 del ICBF se puede
redistribuir en una app comercial? ¿Con qué atribución? ¿Existe en formato tabular (Excel/CSV)
o solo PDF?

Decisión que desbloquea: estrategia de origen de datos para el catálogo nutricional semilla
(~30 alimentos, SPEC-001) y el catálogo completo (T-004) — si se puede tomar la TCAC 2018 como
fuente con `source_id`/`source_ref` verificable y redistribuirla dentro de la app, o si se
necesita otra vía (transcripción manual fila a fila con cita, licencia especial, u otra fuente
como USDA FDC para lo no cubierto).

## CONFIRMADO

- La TCAC 2018 del ICBF es un documento de 773 alimentos (incluye alimentos nativos y
  preparaciones típicas colombianas, con ácidos grasos y aminoácidos) publicado por el ICBF.
  — https://www.icbf.gov.co/tabla-de-composicion-de-alimentos-colombianos-tcac-2018
  (consultado 2026-09-27)

- El único formato de descarga confirmado en el portal oficial del ICBF es **PDF**
  (`tcac_web.pdf`, sitio `icbf.gov.co/system/files/tcac_web.pdf`). Revisé tres páginas oficiales
  distintas del ICBF sobre la TCAC (la página TCAC 2018, la página general "Tabla de Composición
  de Alimentos Colombianos" y la página de "Herramientas... Resumen ejecutivo TCAC") y en
  ninguna se ofrece Excel, CSV ni API; solo PDFs (la tabla completa y un resumen ejecutivo en
  PDF separado).
  — https://www.icbf.gov.co/tabla-de-composicion-de-alimentos-colombianos-tcac-2018 (2026-09-27)
  — https://www.icbf.gov.co/nutricion/tabla-de-composicion-de-alimentos-colombianos (2026-09-27)
  — https://www.icbf.gov.co/herramientas-tabla-de-composicion-de-alimentos-colombianos-resumen-ejecutivo-tcac (2026-09-27)

- El PDF de la tabla completa (`tcac_web.pdf`) pesa más de 10 MB (mi herramienta de lectura lo
  rechazó por tamaño), consistente con un documento extenso de ~773 alimentos; no pude confirmar
  directamente si el texto es seleccionable/tabular o si son páginas escaneadas como imagen.
  — https://www.icbf.gov.co/system/files/tcac_web.pdf (intento de consulta 2026-09-27)

- **Las condiciones de uso del portal ICBF prohíben expresamente la reproducción y el uso
  comercial de los contenidos institucionales sin autorización previa y escrita.** Cita textual
  de la sección "Derechos de Propiedad Intelectual - Copyright" del portal:
  - "Este portal web, sus micrositios y su contenido son propiedad del Instituto Colombiano de
    Bienestar Familiar - ICBF."
  - "Está prohibida su reproducción total o parcial, su traducción, inclusión, transmisión,
    almacenamiento o manipulación sin autorización previa y escrita [del ICBF]."
  - "se prohíbe usar los contenidos institucionales con propósitos comerciales."
  - Uso permitido, explícitamente acotado: "es posible la descarga y cita de material (texto,
    video, audio) ... para uso personal o institucional de carácter informativo, educativo,
    noticioso y no comercial, siempre y cuando se haga expresa mención de la propiedad en
    cabeza del Instituto Colombiano de Bienestar Familiar - ICBF."
  — https://www.icbf.gov.co/el-instituto/politicas-del-portal-web (consultado 2026-09-27)

  Esta política no menciona la TCAC por nombre — es la política general del portal — pero la
  TCAC se distribuye desde ese mismo portal (`icbf.gov.co`) sin una licencia distinta publicada
  en sus páginas específicas, así que a falta de una licencia particular para el dato, aplica la
  política general del sitio.

## NO CONFIRMADO / CONTRADICTORIO

- No encontré una licencia específica para el dataset TCAC (p. ej. una licencia tipo Creative
  Commons o "licencia de datos abiertos" de Colombia) publicada junto a la tabla. No verifiqué
  con certeza si existe un dataset de la TCAC en el portal de datos abiertos del Estado
  colombiano (datos.gov.co): mi búsqueda en ese portal no devolvió resultados navegables sobre
  "composición de alimentos" con las herramientas de consulta disponibles, así que no puedo
  afirmar ni descartar que exista ahí con una licencia abierta distinta (p. ej. CC BY 4.0, que
  es la licencia por defecto de datos.gov.co para muchos datasets). Esto queda pendiente de
  verificar con una búsqueda manual directa en datos.gov.co o contactando al ICBF.
  — intento de consulta: https://www.datos.gov.co/browse (2026-09-27), sin resultado concluyente.

- Existe un sitio `capacitacion.icbf.gov.co/TCAC/` (subdominio del propio ICBF) que aparece
  como una herramienta interactiva de la TCAC. No pude renderizar su contenido (parece una
  aplicación web dinámica) por lo que no confirmé si permite exportar datos en un formato
  tabular (Excel/CSV) o solo consulta alimento por alimento en pantalla, ni si tiene términos de
  uso propios distintos a los del portal general.
  — https://capacitacion.icbf.gov.co/TCAC/ (intento de consulta 2026-09-27)

- No pude verificar directamente, leyendo el PDF completo, si el documento incluye una nota de
  copyright, ISBN o forma de cita sugerida dentro de sus primeras páginas (el archivo excede el
  límite de tamaño de mi herramienta de lectura). Es razonable asumir, por convención editorial
  del ICBF en otras publicaciones, que sí trae créditos institucionales, pero no lo confirmé
  con el texto del propio documento.

- Existen terceros comerciales (p. ej. "MenusPlus") que ofrecen la TCAC 2018 en su software y
  generan reportes en Excel a partir de ella. Esto es una fuente secundaria (no oficial): no
  indica que el ICBF autorice la redistribución comercial de los datos crudos, solo que un
  tercero construyó una herramienta que los usa (posiblemente bajo un convenio propio o bajo la
  interpretación de "uso no comercial" del portal, lo cual no puedo confirmar). No lo tomo como
  evidencia de que la redistribución esté permitida.
  — https://menusplus.net/ (mención secundaria, 2026-09-27)

## Implicaciones para el proyecto

- **Bloqueante confirmado, no descartado:** con la evidencia disponible, la TCAC 2018 tal como
  la publica el ICBF en su portal **no cumple** el invariante 8 del proyecto ("datos
  nutricionales solo desde fuentes... con `source_id` y `source_ref`") de forma segura para un
  producto comercial, porque las condiciones de uso del portal prohíben expresamente el uso
  comercial y la reproducción sin autorización previa y escrita. Calorías IA es una app
  comercial (aunque "sin cuentas" y con datos solo en el dispositivo, el producto en sí puede
  monetizarse), así que copiar/redistribuir los valores de la TCAC dentro del catálogo semilla
  o completo, sin permiso explícito del ICBF, es un riesgo legal, no solo una cuestión de estilo
  de cita.
- Esto afecta directamente a SPEC-001: aunque esa SPEC no usa "el catálogo completo" (T-004),
  sí necesita un catálogo semilla de ~30 alimentos con `source_id`/`source_ref` verificable por
  fila. Si esos ~30 alimentos se toman transcribiendo valores de la TCAC 2018, ese catálogo
  semilla hereda el mismo riesgo de licencia que el catálogo completo — el problema no es de
  escala (30 vs 773), es de origen del dato.
- No hay, hasta ahora, evidencia de una vía tabular oficial (Excel/CSV/API) para la TCAC 2018;
  solo PDF. Aunque el ICBF autorizara el uso, extraer ~30-773 filas de un PDF a mano/con
  herramientas introduce riesgo de error de transcripción, lo cual choca con el invariante 8
  ("nunca escribas valores nutricionales de memoria" — y por extensión, sin verificación rigurosa
  fila a fila contra el PDF fuente).
- Alternativas que no tienen esta restricción de licencia y sí tienen formato tabular oficial:
  **USDA FDC** (dominio público / CC0, con API y descargas CSV documentadas por USDA) ya está
  listado como fuente aceptable en el invariante 8. Para alimentos específicamente colombianos
  sin equivalente claro en USDA FDC, la vía más segura mientras no haya autorización del ICBF es
  usar la etiqueta nutricional confirmada por el usuario (invariante 2) como `source_ref` de esa
  fila, no la TCAC.

## Recomendación (no vinculante)

1. No incorporar valores de la TCAC 2018 al catálogo (ni semilla ni completo) hasta tener
   autorización escrita explícita del ICBF para uso comercial, o hasta confirmar que existe una
   versión con licencia abierta distinta en datos.gov.co (pendiente de verificar).
2. Enviar una solicitud formal al ICBF (canal de atención al ciudadano /
   PQRS en icbf.gov.co) pidiendo por escrito: (a) si permiten el uso de los valores de la TCAC
   2018 en una app comercial, (b) bajo qué atribución, y (c) si existe una versión tabular
   (Excel/CSV) distinta al PDF. Documentar la respuesta cuando llegue como nueva nota de
   investigación.
3. Mientras no haya respuesta, construir el catálogo semilla de SPEC-001 (~30 alimentos) usando
   USDA FDC (dominio público, con `source_id`/`source_ref` verificables) para los alimentos con
   equivalente razonable, y dejar explícitamente fuera del catálogo semilla los alimentos
   típicamente colombianos sin ese equivalente, hasta resolver la licencia de la TCAC — en vez de
   transcribir la TCAC "por ahora y ya se verá".
4. Verificar aparte (nuevo ítem PV, si el usuario lo aprueba) si datos.gov.co tiene un dataset
   de composición de alimentos con licencia abierta (CC BY u otra), ya que eso cambiaría esta
   recomendación.
