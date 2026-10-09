<!-- Versión: v4 — SPEC-015 (antes v3, SPEC-008; v2, SPEC-007). BORRADOR: pendiente de revisión legal humana antes de publicar. -->

# Política de privacidad (borrador)

**Este es un borrador técnico, no un documento legal terminado.** Está pendiente de revisión por un
abogado antes de publicarse como política definitiva. Lo compartimos así, de forma transparente,
para que sepas exactamente qué hace la app hoy.

## Qué hace esta app con tus datos

KCalcula IA no tiene cuentas de usuario. No hay nombre, correo ni identificador que te conecte con
un servidor. Todo lo que registras (comidas, cantidades, calorías) vive únicamente en tu teléfono,
en una base de datos local que nadie más puede leer salvo que tú compartas el archivo.

Tratamos tu registro de alimentación como un **dato sensible de salud**, por un criterio
conservador — aunque sea solo lo que comiste, no lo que te pasa médicamente.

## Qué sale de tu teléfono, y a quién

Cuando escribes o fotografías algo (por ejemplo, "150 g de pollo" o la tabla nutricional de un
producto), ese texto o esa foto se envía a **Vertex AI, un servicio de Google que procesa fuera de
Colombia**, únicamente para convertirlo en datos estructurados (qué alimento, qué cantidad, qué
unidad, o los números impresos en una etiqueta). **La inteligencia artificial nunca calcula
calorías ni decide valores nutricionales** — solo interpreta lo que dijiste o lo que está impreso;
el cálculo lo hace el propio teléfono, con una base de datos nutricional verificada.

Nuestro servidor (una función en la nube) no guarda ni registra ese texto o esa foto en ningún
momento — solo pasa por él, de ida y de vuelta, sin quedarse con una copia. Lo único que puede
quedar registrado, para poder detectar fallas técnicas, son datos como cuánto tardó la respuesta o
si hubo un error — nunca el contenido de lo que enviaste.

Tu voz nunca pasa por nuestro servidor: la convierte en texto el reconocimiento de voz del propio
sistema operativo de tu teléfono. En Android ese servicio puede procesar el audio en servidores de
Google (sin conexión a internet no funciona); en iPhone puede procesarse en servidores de Apple.
Eso depende del sistema operativo, no de esta app, y la app no guarda el audio.

Tus datos ya registrados (comidas, productos guardados, tu perfil, tu historial de peso y tu meta
diaria) nunca salen de tu dispositivo por decisión de la app.

## Tu perfil y tu meta diaria (opcional)

Si usas "Mi perfil", la app guarda en tu teléfono tu sexo, fecha de nacimiento, estatura, peso,
nivel de actividad física y, si lo escribes, tu mantenimiento medido (por ejemplo, el promedio de
tu reloj), para calcular ahí mismo tu metabolismo basal, tu mantenimiento y la meta
del objetivo que elijas (con sus calorías, proteína, carbohidratos y grasa). **Estos datos nunca
salen de tu dispositivo**: ni a nuestro servidor, ni a la inteligencia artificial, ni en los
reportes de fallos.

Puedes cambiarlos cuando quieras desde "Mi perfil", y "Borrar todos mis datos" los elimina junto con
tu meta. Los cálculos son estimaciones generales, no una recomendación médica.

## Tu historial de peso (opcional)

Si anotas tu peso en "Progreso" (o lo cambias en "Mi perfil"), la app guarda en tu teléfono un
registro por día con la fecha y los kilos, para mostrarte cómo cambia y para que tu perfil use
siempre el último peso. **Este historial nunca sale de tu dispositivo**: ni a nuestro servidor, ni a
la inteligencia artificial, ni en los reportes de fallos. Puedes borrar cualquier registro desde
"Progreso"; "Borrar todos mis datos" lo elimina completo y "Exportar mis datos" lo incluye.

## Si la app falla

Si la app se cierra sola o encuentra un error, enviamos un reporte técnico a Firebase Crashlytics
(Google) para poder corregirlo: en qué parte del código pasó, la versión de la app, y datos técnicos
del dispositivo (modelo, sistema operativo). **Nunca incluye el texto de lo que escribiste, fotos, ni
nada de tu diario de comidas.** Este envío solo empieza después de que aceptes esta política — si
revocas tu consentimiento (ver Ajustes), se detiene de inmediato.

## Tus derechos

- **Ver y editar** todo lo que la app calculó antes de guardarlo — nada se guarda sin que lo
  confirmes.
- **Borrar todos tus datos** cuando quieras, desde Ajustes. Es inmediato y no se puede deshacer.
- **Exportar tus datos** en un archivo que tú decides dónde guardar o a quién enviar — nosotros no
  elegimos el destino ni lo mandamos por nuestra cuenta. Puede ser una hoja de cálculo (CSV), un
  resumen para imprimir (PDF, sin tu fecha de nacimiento ni tu sexo) o la copia completa (JSON).
- **Revocar tu consentimiento** en cualquier momento, desde Ajustes, sin que eso borre tus datos ya
  guardados — simplemente dejarás de poder usar la app (incluido el análisis con IA y el reporte de
  fallos) hasta que vuelvas a aceptar.

## Menores de edad

Esta app es para mayores de 18 años. Te pedimos que lo confirmes antes de usarla, pero no
verificamos tu identidad ni tu edad con ningún documento — es una declaración tuya.

## Preguntas o quejas

Si tienes preguntas sobre este borrador o quieres ejercer algún derecho sobre tus datos, escríbenos
a **privacidad@kcalcula.app** (dirección de contacto pendiente de activar formalmente antes de
publicar la app).

## Copias de seguridad

Si tu teléfono hace copias de seguridad automáticas (de Apple o Google), tus datos de la app pueden
quedar incluidos ahí, cifrados y bajo tu control, igual que el resto de tus aplicaciones.

---

*Última actualización de este borrador: 2026-09-30. Versión: v2.*
