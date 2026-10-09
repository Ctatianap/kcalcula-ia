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
| Productos personales (nombre y valores nutricionales confirmados desde una etiqueta —leída por la IA o escrita a mano, SPEC-004 y SPEC-033—, unidad de la porción en g o ml, nombres con que la persona los llama, SPEC-034, y marca opcional, SPEC-025) | `user.db` en el dispositivo (`personal_products`, `personal_product_aliases`) | No | — | Hasta que la persona lo borre en "Mis productos", use "Borrar todos mis datos" o desinstale. Se incluyen en "Exportar mis datos" (JSON, con unidad, nombres alternativos y marca) |
| Comidas favoritas: nombre que la persona les pone y sus alimentos con gramos (SPEC-022) | `user.db` en el dispositivo (`favorite_meals`, `favorite_meal_items`) | No | — | Hasta que la persona la quite, use "Borrar todos mis datos" o desinstale. Se incluyen en "Exportar mis datos" (JSON) |
| Meta diaria: objetivo, kcal y gramos de proteína, carbohidratos y grasa (SPEC-008) | `user.db` en el dispositivo | No | — | Hasta que la persona la cambie, borre todo o desinstale. Se incluye en la exportación |
| Perfil: sexo, fecha de nacimiento, estatura, peso, nivel de actividad y, si la persona lo escribe, su mantenimiento medido (SPEC-008; datos personales de salud). La app no lee Samsung Health ni otros servicios: el valor se escribe a mano | `user.db` en el dispositivo, solo si la persona completa "Mi perfil" | No: el metabolismo basal, el mantenimiento y la meta se calculan localmente (`nutrition_core`); no se envían a nuestro backend, a la IA, a Crashlytics ni a logs, y los fallos de escritura no se relanzan | — | Hasta que la persona los cambie, borre todo o desinstale. Se incluyen en la exportación |
| Historial de peso: fecha y kg, un registro por día (SPEC-015; dato personal de salud) | `user.db` (`weight_log`) en el dispositivo, solo si la persona anota su peso en Progreso o lo cambia en "Mi perfil" | No: la tendencia y el recálculo de la meta se hacen localmente (`nutrition_core`); no se envía a nuestro backend, a la IA, a Crashlytics ni a logs, y los fallos de escritura no se relanzan (SPEC-009) | — | Hasta que la persona borre el registro, borre todo o desinstale. Se incluye en la exportación. Política v4 |
| Texto de la comida (escrito o transcrito) | Memoria | Sí, en cada análisis | Cloud Function → Vertex AI (Google) | Backend: no se guarda ni se registra. Proveedor: Vertex AI no usa el contenido para entrenar sus modelos; el caché de datos es opcional y se puede desactivar a nivel de proyecto para retención cero; en `kcalcula-ia-dev` está desactivado desde 2026-10-07 (`disableCache: true`, SPEC-029). Google sí puede registrar prompts para monitoreo de abuso de su política de uso aceptable, como parte del servicio — esto ocurre del lado de Google, fuera del control de este backend, no es una contradicción de "backend sin estado" sino una dependencia de terceros a declarar. Ver `docs/research/2026-09-27-vertex-ai-functions.md` (PV-03); confirmar visualmente el texto oficial antes de citarlo en un aviso de consentimiento al usuario. |
| Corrección de una comida (SPEC-024): el texto de la corrección y, de cada ingrediente del borrador, lo que se dijo (`mention`), el alimento buscado y la cantidad, unidad y tamaño dichos. **Sin** valores nutricionales, gramos calculados ni confianza, y sin el texto original de la comida | Memoria | Sí, solo cuando la persona toca "Aplicar" | Cloud Function `correctMeal` → Vertex AI (Google, `us-east1`) | Igual que el texto de la comida: el backend no lo guarda ni lo registra (solo metadatos: latencia, tokens, número de operaciones, validez). La política v4 ya cubre "cuando escribes algo, ese texto se envía a Vertex AI": no cambia de versión |
| Audio de voz | Motor de voz del sistema operativo | **Android: sí**, hacia servidores de Google: medido en un motorola edge 50 pro (Android 16) — sin conexión no hay reconocimiento, y la app no pide reconocimiento en el dispositivo (`onDevice`). **iOS: POR VERIFICAR** (puede procesarse en servidores de Apple). En ningún caso hacia nuestro backend (SPEC-002) | SO (Google en Android; Apple en iOS) | Lo define Google/Apple, fuera del control de la app; POR VERIFICAR su política de retención de audio. Medición: `docs/research/2026-10-01-voz-es-co-dispositivos.md` |
| Foto de etiqueta | Memoria / galería del usuario | Sí, en cada lectura de etiqueta, igual que el texto: el backend desplegado de `kcalcula-ia-dev` usa Vertex AI desde 2026-10-07 (SPEC-029, `docs/decisions/ADR-002-ia-local-vs-vertex.md`). Solo con el emulador local y `AI_PROVIDER=ollama` la imagen se procesa en la máquina de desarrollo y no sale de ella | Cloud Function → Vertex AI (Google, `us-east1`) | Igual que el texto. La imagen se redimensiona/comprime en el dispositivo antes de enviarse (máx. ~1600 px, JPEG ~85 %); el backend nunca la guarda ni la registra (invariante 5), solo metadatos |
| Token de App Check | Dispositivo | Sí | Firebase | Gestionado por Google |
| Metadatos técnicos (latencia, tokens, códigos de error) | Cloud Logging | — | Google Cloud | Retención por defecto de Cloud Logging, POR VERIFICAR |
| Exportación de datos del usuario (SPEC-006, JSON con comidas, productos personales, perfil y meta —SPEC-008— , historial de peso —SPEC-015— y comidas favoritas —SPEC-022—; SPEC-016: también CSV —una fila por alimento, con `source_ref`— y PDF —meta, promedios, días en meta, peso del periodo y comidas por día; **sin** fecha de nacimiento, sexo, estatura ni mantenimiento medido—, filtrables por periodo) | Archivo temporal en el dispositivo (generado localmente; el PDF con la librería `pdf`, sin red) | Solo si el usuario decide compartirlo | El usuario elige el destino en el share sheet del sistema operativo — la app arma el archivo localmente y nunca lo transmite por su cuenta a ningún servidor propio ni de terceros | Archivo temporal; no es `user.db` ni un backup automático. Al empezar una exportación nueva se borran las anteriores que creó la app (T-022) |
| Reporte de fallos (SPEC-007, Firebase Crashlytics) | Memoria, solo cuando ocurre un error no controlado | Sí, si el usuario aceptó la versión vigente de la política | Firebase Crashlytics (Google), fuera de Colombia | Retención por defecto de Crashlytics, POR VERIFICAR. **Nunca** incluye texto de comidas, nombres de producto, fotos ni rutas de archivos exportados — solo stack trace, versión de la app y metadata técnica del dispositivo. La recolección arranca desactivada y solo se activa tras confirmar consentimiento vigente (`ConsentRecord.policyVersion` == versión actual); se desactiva de nuevo al revocar el consentimiento. Los errores de `user.db` se envían **saneados** (SPEC-009): solo el tipo de error y el código de SQLite, nunca el mensaje, que trae la sentencia y sus parámetros (alimentos, cantidades, perfil). |

## Controles
Implementados en SPEC-006 (T-007) y SPEC-007 (T-008) — antes solo estaban previstos aquí, ahora
existen en la app:
- Reporte de fallos (Crashlytics) gateado por consentimiento vigente: nunca empieza antes de que el
  usuario acepte la versión de la política que lo menciona explícitamente, y se apaga al revocar —
  ver fila nueva del inventario arriba. Un cambio de política (como este) hace que
  `_RootGate` vuelva a mostrar el onboarding a usuarios que ya habían aceptado una versión anterior,
  aunque no hayan revocado nada — no es un re-consentimiento silencioso.
- Consentimiento explícito e informado antes del primer uso, en un onboarding que bloquea el resto
  de la app hasta aceptar. El texto nombra explícitamente que es dato sensible de salud/nutrición,
  qué se envía, a quién (Vertex AI/Google, fuera de Colombia) y para qué — ver PV-07
  (`docs/research/2026-09-28-ley-1581-consentimiento.md`).
- Declaración de edad: casilla "confirmo que soy mayor de 18 años", sin verificar identidad
  (SUPUESTO, a validar legalmente — ver PV-07).
- "Borrar todos mis datos" en Ajustes (borra `meals`/`meal_items`/`personal_products`, el perfil, la
  meta, el historial de peso y las comidas favoritas de `user.db`).
- "Revocar consentimiento" en Ajustes, separado de borrar datos (Ley 1581 Art. 8) — re-bloquea la
  app hasta volver a aceptar, sin borrar los datos ya guardados.
- "Exportar mis datos" en Ajustes (pantalla propia desde SPEC-016): CSV, PDF o JSON local entregado
  al share sheet del sistema operativo — ver
  fila nueva del inventario arriba.
- Borrador de política de privacidad completo, en español, accesible desde el onboarding y desde
  Ajustes (`app/assets/legal/privacy_policy_draft_es.md`).
- Copias de seguridad del sistema operativo: permitidas, cifradas y controladas por el usuario; se
  informa en la política.
- Backend sin estado y sin logs de contenido (invariante 5 de `CLAUDE.md`).
- Pruebas manuales con IA real (SPEC-029): ningún agente maneja el selector de fotos sobre la galería
  personal de nadie; las pruebas de etiquetas usan imágenes dedicadas (`evals/datasets/`) o una foto
  que la persona elige ella misma. Motivo: el 2026-10-07 un toque automatizado envió por error una
  foto personal a Vertex AI.

## Marco normativo a revisar (POR VERIFICAR con abogado)
- Ley 1581 de 2012 (Colombia): datos de salud como datos sensibles, autorización explícita,
  transferencia internacional (el proveedor procesa fuera de Colombia) y derechos de habeas data —
  resuelto parcialmente en PV-07
  (`docs/research/2026-09-28-ley-1581-consentimiento.md`): el checkbox in-app y la autodeclaración
  de edad son formas técnicamente válidas, pero quedan sin confirmar (a) si Vertex AI cuenta como
  "encargado" (transmisión) o exige autorización expresa separada de transferencia internacional
  bajo el contrato real de Google, y (b) si el umbral de 100.000 UVT del Registro Nacional de Bases
  de Datos aplica a la estructura legal real del proyecto.
- Declaraciones de las tiendas: Google Play Data Safety y etiquetas de privacidad de App Store.
- Términos de uso de datos de Vertex AI (retención, entrenamiento, ubicación): resuelto parcialmente
  en PV-03 (ver tabla de arriba); falta confirmación visual humana del texto oficial de Google antes
  de usarlo en un aviso de consentimiento.

## Regla de cambios
Cualquier dato nuevo que salga del dispositivo, o un destino nuevo, requiere Strict Path y
actualizar esta tabla en el mismo cambio.
