# Cuotas de Play Integrity y App Attest; TTL de token recomendado (PV-08)

Pregunta: ¿Qué cuotas tienen Play Integrity API y App Attest para verificación de tokens en el
nivel gratuito? ¿Cuál es el TTL recomendado de los tokens de Firebase App Check? ¿Qué requisitos
previos ineludibles existen para cada proveedor? ¿Qué riesgo documenta Firebase sobre dejar el
debug provider activo en una build de release?

Decisión que desbloquea: diseño de SPEC-007 (T-008, "Endurecimiento para beta") — activación de
Firebase App Check real (Play Integrity en Android, App Attest en iOS) contra `kcalcula-ia-dev`
para proteger `parseMeal` y `extractLabel`, y configuración del TTL de token.

## CONFIRMADO

- El TTL (time-to-live) de los tokens de sesión de App Check es configurable entre **30 minutos y
  7 días**, con **1 hora como valor por defecto**, y la librería cliente refresca el token
  aproximadamente a la mitad del TTL (con 1h por defecto, refresco ~cada 30 min). Firebase describe
  el default de 1h como "razonable para la mayoría de apps": TTL más corto = más seguridad pero más
  latencia y consumo de cuota más rápido; TTL más largo = menos llamadas de verificación pero mayor
  ventana de abuso si se filtra un token.
  — [Firebase App Check · Play Integrity provider](https://firebase.google.com/docs/app-check/android/play-integrity-provider) (consultado 2026-09-29)
  — [Firebase App Check · App Attest provider](https://firebase.google.com/docs/app-check/ios/app-attest-provider) (consultado 2026-09-29)
  — [Firebase App Check · Enable enforcement](https://firebase.google.com/docs/app-check/enable-enforcement) (consultado 2026-09-29)

- **Play Integrity API**: cuota gratuita por defecto de **10.000 solicitudes totales por día**,
  compartida entre "Standard requests" y "Classic requests", sumando todas las instalaciones de la
  app. Se puede pedir aumento de cuota desde Play Console/Play SDK Console, pero **para ser
  elegible al aumento la app debe estar publicada en Google Play** (además de cualquier otro canal
  de distribución) y se debe confirmar implementación correcta de la lógica de reintentos. La cuota
  incluye también 10.000 desencriptaciones de token en servidores de Google.
  — [Android Developers · Play Integrity overview](https://developer.android.com/google/play/integrity/overview) (consultado 2026-09-29)
  — [Play Console Help · Use Play Integrity API](https://support.google.com/googleplay/android-developer/answer/11395166) (consultado 2026-09-29)

- **Requisito previo ineludible — Play Integrity**: la app necesita (1) un proyecto de Google Cloud
  con la Play Integrity API habilitada, y (2) ese proyecto de Cloud **vinculado** desde Play Console
  (App integrity → "Link Cloud project"). Para vincular, la cuenta debe ser **Owner** directo del
  proyecto de Firebase/GCP (ser miembro de un grupo con rol Owner no es suficiente, según la
  documentación de Firebase). La app puede existir en **pista interna de pruebas** de Play Console
  para vincular y probar sin estar publicada — el requisito de publicación en Play solo aplica si
  se pide **aumento de cuota**, no para operar dentro del límite gratuito de 10.000/día.
  — [Firebase App Check · Play Integrity provider](https://firebase.google.com/docs/app-check/android/play-integrity-provider) (consultado 2026-09-29)
  — [Android Developers · Play Integrity setup](https://developer.android.com/google/play/integrity/setup) (consultado 2026-09-29)

- **App Attest**: Apple no publica un número exacto de cuota ni SLA. La documentación/foros de
  Apple Developer indican que Apple limita la cantidad de dispositivos únicos llamando a App Attest
  en un momento dado, sin cifra pública, y **no hay mecanismo para pedir aumento** porque no hay SLA
  disponible. Como guía práctica (no cifra de cuota formal), Apple recomienda mantener las llamadas
  a `attestKey()` de una app en un solo dígito/decenas por segundo a escala normal, y que a escala de
  ~10 millones de usuarios/día se mantenga bajo ~100 llamadas de attestation por segundo — muy por
  encima de lo que generaría una beta cerrada de cientos de usuarios. Además, `attestKey()` está
  pensado para llamarse **una sola vez por instalación** (generación de la key de dispositivo), no
  por sesión ni por request, lo que reduce aún más el volumen relevante.
  — [Apple Developer Forums · App Attest & DeviceCheck rate limiting/quotas](https://developer.apple.com/forums/thread/818214) (consultado 2026-09-29)
  — [Apple Developer Forums · App Attest Service Quota Limits](https://developer.apple.com/forums/thread/778937) (consultado 2026-09-29)

- **App Attest no funciona en el Simulador de iOS**: Firebase documenta explícitamente que "App
  Check actualmente no acepta tokens generados en el entorno sandbox de App Attest" (que es lo que
  usa el Simulador); se requiere dispositivo real o el debug provider para desarrollo/CI.
  — [Firebase App Check · App Attest provider](https://firebase.google.com/docs/app-check/ios/app-attest-provider) (consultado 2026-09-29)

- **Riesgo documentado de dejar el debug provider activo**: la documentación oficial de Firebase
  advierte explícitamente: *"Keep your debug token and debug build private. A valid debug token and
  the debug provider in your debug build allow access to your backend services from unverified
  devices."* Instrucciones oficiales: no subir el debug token a repositorios públicos, no incluirlo
  en builds de producción/release, guardarlo como secreto cifrado en el CI (no en texto plano), y si
  se filtra o se sospecha comprometido, **borrarlo de inmediato en la consola de Firebase** para
  revocar acceso. Si el token se pierde, basta desinstalar/reinstalar la app para generar uno nuevo.
  No hay una página que describa un escenario específico "qué pasa si queda activo en release" más
  allá de esta advertencia general — pero la implicación directa es que cualquier build de release
  que use el debug provider (o cuyo binario incluya un debug token filtrado) permitiría a **cualquier
  cliente** con ese token pasar la verificación de App Check, anulando la protección de
  `enforceAppCheck: true` en `parseMeal`/`extractLabel`.
  — [Firebase App Check · Debug provider (iOS)](https://firebase.google.com/docs/app-check/ios/debug-provider) (consultado 2026-09-29)

## NO CONFIRMADO / CONTRADICTORIO

- **¿App Attest exige una cuenta de Apple Developer Program de pago (US$99/año)?** No se encontró
  una afirmación directa y explícita en la documentación oficial de Apple sobre App Attest que
  confirme esto para el entitlement específico de App Attest. Lo que sí es un hecho independiente y
  bien establecido (no específico de App Attest) es que **distribuir la app en TestFlight/App Store
  para una beta cerrada de iOS ya requiere membresía de pago del Apple Developer Program**
  ($99 USD/año) — así que en la práctica el proyecto necesitará esa membresía de todas formas para
  poder hacer la beta, independientemente de si App Attest en sí la exige o no. No se debe tratar
  como confirmado que "App Attest específicamente" tenga ese requisito; se recomienda verificarlo al
  configurar el capability en Xcode con la cuenta real del proyecto.
- No se encontró una página oficial única que compare explícitamente "qué pasa en runtime si un
  build de release intenta usar el debug provider" (p. ej. si Firebase lo rechaza en servidor o si
  simplemente funciona igual que en debug, exponiendo el token). La advertencia oficial es sobre el
  riesgo de exposición del token, no sobre un comportamiento de rechazo automático en servidor.

## Implicaciones para el proyecto

- El límite de 10.000 solicitudes/día de Play Integrity es más que suficiente para una beta cerrada
  de cientos de usuarios, incluso sin optimizar TTL: con TTL por defecto de 1h (refresco ~cada 30
  min) y cientos de usuarios activos, el volumen de attestations reales quedaría muy por debajo del
  límite gratuito. No se ve necesidad de pedir aumento de cuota para T-008/SPEC-007.
- App Attest no tiene una cifra de cuota conocida, pero al ser `attestKey()` una operación de una
  sola vez por instalación (no por sesión), el volumen para una beta de cientos de usuarios es
  trivial frente a las guías informales de Apple.
- El TTL por defecto de 1 hora es razonable para SPEC-007; no hay indicio de que haga falta acortarlo
  ni alargarlo para esta escala. Se puede documentar como decisión "usar default (1h), revisar si
  cambia el perfil de uso en producción".
- Vinculación con Play Console es obligatoria antes de que Play Integrity funcione, y quien lo haga
  debe ser Owner directo del proyecto de Firebase/GCP (verificar quién tiene ese rol antes de
  ejecutar el paso). La app puede quedarse en pista interna de Play Console para esto — no hace
  falta publicarla, salvo que en el futuro se necesite aumentar la cuota de 10.000/día.
- Para iOS, verificar temprano si la cuenta de Apple Developer Program de pago ya existe para el
  proyecto — la va a necesitar de todos modos para distribuir la beta por TestFlight, así que
  conviene resolver esa gestión (fuera del alcance de este investigador; requiere acción humana en
  la cuenta de Apple Developer) antes de que SPEC-007 llegue a implementación en iOS.
- El manejo del debug token debe tratarse como secreto: no committearlo, guardarlo en el almacén de
  secretos del CI, y asegurarse de que la configuración de build de release (Flutter `--release` /
  Xcode Release scheme / variante `release` de Android) nunca registre el provider de depuración —
  esto debería quedar como criterio de aceptación explícito en SPEC-007 (p. ej. un test o check de
  build que falle si el debug provider queda referenciado en la configuración de release).

## Recomendación (no vinculante)

- Usar el TTL por defecto de App Check (1 hora) en SPEC-007 en vez de personalizarlo; no hay
  evidencia de que la escala de la beta lo justifique.
- No solicitar aumento de cuota de Play Integrity para esta beta; solo evaluarlo si en producción
  real se supera de forma sostenida el 10.000/día (poco probable a la escala descrita).
- Incluir en SPEC-007 un criterio de aceptación explícito que verifique (por configuración de build,
  no solo por convención) que el debug provider de App Check no puede quedar activo en una build de
  release de Android/iOS.
- Antes de implementar la parte de iOS de SPEC-007, confirmar con el usuario si ya existe una cuenta
  de pago de Apple Developer Program vinculada al proyecto (paso que solo el usuario puede hacer en
  la consola de Apple).
