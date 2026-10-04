# SPEC-027: Datos de salud conectados (Health Connect y Apple Salud)

## Status
Draft
Path: Strict (entran datos de salud de otras apps; puede cambiar el mantenimiento que usa
`nutrition_core`; quizá se escriben datos fuera de la app)

## Objective
Que la app pueda tomar el peso (y, si se decide, el gasto calórico) de Health Connect en Android o de
Apple Salud en iPhone, y opcionalmente escribir allí las comidas confirmadas, sin que nada salga del
dispositivo hacia nuestros servidores.

## Context
Fase F4 de `docs/backlog.md`. **La usuaria la pospuso el 2026-10-03** (sin integraciones en el MVP; el
mantenimiento medido sigue siendo manual, SPEC-008 R4). Esta SPEC deja el plan listo para cuando se
retome. Investigación: `docs/research/2026-10-03-samsung-health-health-connect.md` (PV-12). Hechos
clave de esa nota:
- El "Total de calorías quemadas" diario de Samsung Health **no** se sincroniza con Health Connect
  (solo las calorías de ejercicio, `TotalCaloriesBurnedRecord`); sí llegan peso, pasos, metabolismo
  basal y nutrición.
- El Samsung Health Data SDK sí expone `ActivitySummaryType.TOTAL_CALORIES_BURNED`, pero publicar exige
  aprobación de Samsung como partner y código nativo.
- El paquete Flutter `health` (13.3.2, carp.dk) cubre Health Connect y HealthKit y escribe comidas; su
  mantenimiento es contradictorio según las fuentes.
- Play exige Data safety, el Health apps declaration form y política de privacidad; App Store 5.1.3
  prohíbe escribir datos inexactos en HealthKit.
- Los relojes no bajan del 20 % de error en gasto energético (Shcherbina 2017).

## User Story
Como persona que se pesa con una báscula conectada, quiero que mi peso llegue solo a la app, para no
anotarlo dos veces.

## Requirements
- R1. **Activación opcional** en Ajustes ("Conectar con Health Connect" / "Conectar con Salud"), con una
  pantalla que explica qué datos se leen o escriben y para qué; nada se lee antes de que la persona lo
  active y conceda el permiso del sistema.
- R2. **Leer peso:** los registros de peso del sistema entran a `weight_log` (SPEC-015) con su fecha
  local, marcados como importados; uno por día (gana el más reciente); el perfil y la meta se
  actualizan como en SPEC-015 R3.
- R3. **Gasto calórico (opcional, decisión pendiente):** si se decide leerlo, se muestra como dato
  informativo con el aviso "Estimación del reloj; puede variar más de un 20 %" y **no** reemplaza el
  mantenimiento medido sin confirmación explícita de la persona.
- R4. **Escribir comidas (opcional, decisión pendiente):** solo comidas guardadas, con kcal y macros de
  `nutrition_core`; las de "Estimación" se excluyen o se marcan según la decisión del equipo (App Store
  5.1.3(ii)).
- R5. **Desconectar** deja de leer y escribir; los datos ya importados se quedan salvo que la persona
  los borre. "Borrar todos mis datos" borra lo importado; no borra datos de las otras apps.
- R6. **Privacidad:** nada de esto sale hacia nuestro backend ni a la IA. Se actualizan
  `docs/privacy.md`, la política (nueva versión) y las declaraciones de las tiendas.

## Acceptance Criteria
- AC1. Con un proveedor de salud falso que devuelve pesos de 62,4 (26 sep) y 62,0 (3 oct), al
  sincronizar quedan 2 registros en `weight_log` marcados como importados y el perfil en 62,0
  `[integration]`.
- AC2. Sin activar la conexión o con el permiso denegado no se llama al proveedor y se muestra un
  mensaje en español `[widget]`.
- AC3. Desconectar detiene las lecturas; los registros importados siguen hasta que la persona los
  borra `[integration]`.
- AC4. Si se implementa R3: el gasto leído nunca cambia la meta sin confirmación `[widget]`.
- AC5. Si se implementa R4: solo se escriben comidas guardadas con valores de `nutrition_core`
  `[unit]`.
- AC6. Política nueva con la sección de datos conectados; re-consentimiento `[widget + integration]`.
- AC7. Recorrido manual en un Android con Health Connect y en un iPhone con Salud `[manual]`.

## Technical Constraints
- Invariantes 3, 5, 6, 7 y 9 (no suponer capacidades del paquete; verificar la versión al añadirlo).
- La integración vive detrás de una interfaz en `app/lib/infra/health/` para poder probarla con un
  falso (como `SharingService`).

## Components / Files Affected
- `app/lib/infra/health/` (nuevo), `app/lib/infra/storage/` (origen del registro de peso),
  `app/lib/features/settings/`, `app/lib/features/progress/`, `android/` (permisos y actividad de
  justificación), `ios/` (capacidad HealthKit y textos de uso), `docs/privacy.md`, política.

## Dependencies
- SPEC-008, SPEC-015. Decisión de la usuaria de retomar F4.

## Edge Cases
- Health Connect no instalado o no disponible (Android 13 o menos) → se ofrece instalarlo.
- Datos de más de 30 días antes del permiso no se leen sin el permiso de historial.
- Peso duplicado el mismo día desde la app y desde el sistema → gana el más reciente.
- Unidades en libras → conversión a kg.

## Security & Privacy
- **Entran datos de salud nuevos** de otras apps (peso; quizá gasto calórico) y quizá **salen** comidas
  hacia Health Connect/Salud (en el mismo dispositivo). Nada sale hacia nuestros servidores. Strict +
  `docs/privacy.md` + política + Data safety + Health apps declaration form + texto de App Store.

## Tests Required
- Unit: AC5, conversión de unidades. Widget: AC2, AC4, AC6. Integration: AC1, AC3, AC6. Manual: AC7.

## Out of Scope
- Samsung Health Data SDK (exige partnership; ver Open Questions), pasos, sueño, frecuencia cardiaca,
  sincronización en segundo plano.

## Open Questions
- ¿Se retoma F4? (Hoy está pospuesta por decisión de la usuaria.)
- ¿Qué se lee: solo peso, o también gasto calórico de ejercicio (`TotalCaloriesBurnedRecord`), sabiendo
  que no es el total diario de Samsung Health?
- ¿Se escriben comidas? ¿Las de "Estimación" se excluyen o se marcan?
- ¿Se pide partnership a Samsung para el total diario? Criterios y si aceptan solicitudes: NO
  CONFIRMADO en PV-12.
- Paquete Flutter: `health` 13.3.2 (mantenimiento contradictorio) u otra opción: POR VERIFICAR con el
  subagente `researcher` al retomar.

## Definition of Done
- AC1–AC7 con evidencia · analyze y tests verdes · reviewer PASS enlazado · `docs/privacy.md`, política
  y declaraciones de tienda actualizadas · aprobación de la usuaria antes de fusionar (Strict).

## Change Log
- 2026-10-04: creación a partir de F4 (fase pospuesta; Draft para cuando se retome).

## Review
Informe del reviewer: pendiente.
