<!-- Versión: v1 — SPEC-006. BORRADOR: pendiente de revisión legal humana antes de publicar. -->

# Política de privacidad (borrador)

**Este es un borrador técnico, no un documento legal terminado.** Está pendiente de revisión por un
abogado antes de publicarse como política definitiva. Lo compartimos así, de forma transparente,
para que sepas exactamente qué hace la app hoy.

## Qué hace esta app con tus datos

Calorías IA no tiene cuentas de usuario. No hay nombre, correo ni identificador que te conecte con
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

Ni tu voz (se transcribe en tu propio teléfono, sin pasar por nuestro servidor) ni tus datos ya
registrados (comidas, productos guardados) salen jamás de tu dispositivo por decisión de la app.

## Tus derechos

- **Ver y editar** todo lo que la app calculó antes de guardarlo — nada se guarda sin que lo
  confirmes.
- **Borrar todos tus datos** cuando quieras, desde Ajustes. Es inmediato y no se puede deshacer.
- **Exportar tus datos** en un archivo que tú decides dónde guardar o a quién enviar — nosotros no
  elegimos el destino ni lo mandamos por nuestra cuenta.
- **Revocar tu consentimiento** en cualquier momento, desde Ajustes, sin que eso borre tus datos ya
  guardados — simplemente dejarás de poder usar el análisis con IA hasta que vuelvas a aceptar.

## Menores de edad

Esta app es para mayores de 18 años. Te pedimos que lo confirmes antes de usarla, pero no
verificamos tu identidad ni tu edad con ningún documento — es una declaración tuya.

## Preguntas o quejas

Si tienes preguntas sobre este borrador o quieres ejercer algún derecho sobre tus datos, escríbenos
a **privacidad@caloriasia.app** (dirección de contacto pendiente de activar formalmente antes de
publicar la app).

## Copias de seguridad

Si tu teléfono hace copias de seguridad automáticas (de Apple o Google), tus datos de la app pueden
quedar incluidos ahí, cifrados y bajo tu control, igual que el resto de tus aplicaciones.

---

*Última actualización de este borrador: 2026-09-29. Versión: v1.*
