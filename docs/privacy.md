# Privacidad — Calorías IA

Estado: borrador técnico. **Requiere revisión legal antes de publicar** (no es asesoría legal).

## Principios
- Minimización: solo sale del dispositivo lo imprescindible para interpretar la entrada.
- Sin cuentas: no hay identificadores de usuario en el backend.
- El registro alimentario se trata como dato sensible relacionado con la salud (criterio conservador).
- Los datos del usuario no se usan para entrenar modelos.

## Inventario de datos
| Dato | Dónde vive | ¿Sale del dispositivo? | Destino | Retención |
|---|---|---|---|---|
| Registro de comidas, cantidades, totales | `user.db` en el dispositivo | No | — | Hasta que el usuario lo borre o desinstale |
| Productos personales (nombre y valores nutricionales confirmados desde una etiqueta, SPEC-004) | `user.db` en el dispositivo | No | — | Hasta que el usuario lo borre o desinstale |
| Texto de la comida (escrito o transcrito) | Memoria | Sí, en cada análisis | Cloud Function → Vertex AI (Google) | Backend: no se guarda ni se registra. Proveedor: Vertex AI no usa el contenido para entrenar sus modelos; el caché de datos es opcional y se puede desactivar a nivel de proyecto para retención cero. Google sí puede registrar prompts para monitoreo de abuso de su política de uso aceptable, como parte del servicio — esto ocurre del lado de Google, fuera del control de este backend, no es una contradicción de "backend sin estado" sino una dependencia de terceros a declarar. Ver `docs/research/2026-09-27-vertex-ai-functions.md` (PV-03); confirmar visualmente el texto oficial antes de citarlo en un aviso de consentimiento al usuario. |
| Audio de voz | Motor de voz del sistema operativo | Depende del dispositivo (puede procesarse en servidores de Apple o Google), nunca hacia nuestro backend (SPEC-002) | SO | POR VERIFICAR — se completa con la medición real en dispositivo de PV-05 / AC8 de SPEC-002 |
| Foto de etiqueta | Memoria / galería del usuario | Depende del proveedor de IA configurado (SPEC-004): con `AI_PROVIDER=ollama` (desarrollo, ver `docs/decisions/ADR-002-ia-local-vs-vertex.md`) la imagen se procesa en la máquina local y **no sale del dispositivo de desarrollo**; con `AI_PROVIDER=vertex` (producción) sí sale, igual que el texto | Cloud Function → proveedor de IA configurado (Vertex AI en producción) | Igual que el texto. La imagen se redimensiona/comprime en el dispositivo antes de enviarse (máx. ~1600 px, JPEG ~85 %); el backend nunca la guarda ni la registra (invariante 5), solo metadatos |
| Token de App Check | Dispositivo | Sí | Firebase | Gestionado por Google |
| Metadatos técnicos (latencia, tokens, códigos de error) | Cloud Logging | — | Google Cloud | Retención por defecto de Cloud Logging, POR VERIFICAR |

## Controles
- Consentimiento explícito e informado antes del primer análisis con IA, explicando qué se envía y a quién.
- Declaración de edad: uso solo para mayores de 18 años (SUPUESTO, a validar legalmente).
- "Borrar todos mis datos" en la app (borra `user.db`).
- Exportar mis datos (formato por definir en una SPEC).
- Copias de seguridad del sistema operativo: permitidas, cifradas y controladas por el usuario; se informa en la política.
- Backend sin estado y sin logs de contenido (invariante 5 de `CLAUDE.md`).

## Marco normativo a revisar (POR VERIFICAR con abogado)
- Ley 1581 de 2012 (Colombia): datos de salud como datos sensibles, autorización explícita,
  transferencia internacional (el proveedor procesa fuera de Colombia) y derechos de habeas data.
- Declaraciones de las tiendas: Google Play Data Safety y etiquetas de privacidad de App Store.
- Términos de uso de datos de Vertex AI (retención, entrenamiento, ubicación): resuelto parcialmente
  en PV-03 (ver tabla de arriba); falta confirmación visual humana del texto oficial de Google antes
  de usarlo en un aviso de consentimiento.

## Regla de cambios
Cualquier dato nuevo que salga del dispositivo, o un destino nuevo, requiere Strict Path y
actualizar esta tabla en el mismo cambio.
