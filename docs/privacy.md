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
| Texto de la comida (escrito o transcrito) | Memoria | Sí, en cada análisis | Cloud Function → Vertex AI (Google) | Backend: no se guarda ni se registra. Proveedor: POR VERIFICAR |
| Audio de voz | Motor de voz del sistema operativo | Depende del dispositivo (puede procesarse en servidores de Apple o Google) | SO | POR VERIFICAR |
| Foto de etiqueta | Memoria / galería del usuario | Sí, al analizarla | Cloud Function → Vertex AI | Igual que el texto |
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
- Términos de uso de datos de Vertex AI (retención, entrenamiento, ubicación).

## Regla de cambios
Cualquier dato nuevo que salga del dispositivo, o un destino nuevo, requiere Strict Path y
actualizar esta tabla en el mismo cambio.
