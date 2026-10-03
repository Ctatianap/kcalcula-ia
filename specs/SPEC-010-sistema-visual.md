# SPEC-010: Sistema visual y navegación

## Status
Review
Path: Standard (solo presentación: no toca `nutrition_core`, la IA, el catálogo ni lo que sale del
dispositivo. La fuente se embebe para no descargarla de internet; ver Security & Privacy).

## Objective
Darle a la app la identidad del diseño "kcalcula ia UI" (paleta, tipografía Outfit, tarjetas,
botones y anillos de progreso) y una navegación inferior Hoy / Historial / Progreso con un botón +
para registrar. Es la base de T-012 a T-020.

## Context
Backlog T-011. Diseño revisado el 2026-10-03:
https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD. Decisiones de la usuaria registradas en
`docs/backlog.md` (encabezado del rediseño). Hoy la app usa
`ColorScheme.fromSeed(Colors.deepPurple)` y no tiene navegación inferior: el diario es la raíz y
Ajustes se abre desde un icono.

Valores tomados del diseño (archivos `project/*.dc.html` del lienzo):
- Tipografía: Outfit, pesos 200–500. Títulos grandes en 300; texto en 300–400; énfasis en 500.
- Texto principal `#1B2430`; texto secundario `#5F6B7A`; acento `#3F6483` (títulos de pantalla,
  botón primario, botón +, anillo de kcal); fondo `#FFFFFF`; superficies suaves `#EEF3FA` y
  `#F3F7FC`; selección de la navegación `#E4EDF7`; bordes y pistas de los anillos `#E3E9F1` y
  `#E8EDF4`.
- Macros: proteína `#C2776B`, carbohidratos `#C9A15A`, grasa `#5FA8A0`. Son la identidad de cada
  macro, no señales de alarma.
- Confirmación: fondo `#E8F3EC`, texto `#2F6B4A` (por ejemplo, el sello "Base verificada").
- Tarjetas: radio 22–28 px, sombra suave
  (`0 0 0 1px rgba(30,60,110,.06), 0 1px 3px rgba(20,40,80,.05), 0 4px 16px rgba(20,40,80,.05)`).
- Botones: 56 px de alto, radio 28 px; primario relleno con el acento; secundario blanco con borde
  `#E3E9F1`.
- Navegación: píldora blanca abajo a la izquierda con Hoy (con texto), Historial y Progreso (solo
  icono), y botón + circular de 60 px con el acento, abajo a la derecha.

## User Story
Como persona que usa la app, quiero una interfaz clara y consistente, con acceso directo a Hoy,
Historial y Progreso y un botón para registrar, para usarla a diario sin esfuerzo.

## Requirements
- R1. **Tema global** (`app/lib/ui/` o `app/lib/infra/theme/`): un `ThemeData` con la paleta, la
  tipografía, los radios y los estilos de botones, tarjetas, campos de texto y diálogos del
  Context. Todas las pantallas existentes lo heredan sin cambiar su contenido ni su comportamiento.
- R2. **Tipografía Outfit embebida** como asset de la app (pesos 200, 300, 400 y 500). **No se
  descarga en tiempo de ejecución**: nada de `google_fonts` ni peticiones a Google Fonts. La
  licencia (se espera SIL Open Font License) y la fuente de los archivos se verifican al
  implementar y se citan en `app/assets/fonts/OFL.txt` y en la SPEC.
- R3. **Componentes reutilizables**, sin lógica de negocio: tarjeta, botón primario, botón
  secundario, anillo de progreso (valor de 0 a 1, grosor, color, contenido al centro) y encabezado
  de pantalla (título en el acento, con botón Volver opcional). Los anillos reciben la fracción ya
  calculada (`GoalProgress.fraction` de `nutrition_core`); no calculan nada.
- R4. **Navegación inferior** en las tres pantallas principales: Hoy (activa, con texto), Historial
  y Progreso (iconos con `aria`/`Semantics` en español), más el botón + que abre "¿Qué comiste?"
  (la captura actual). Ajustes se sigue abriendo desde el icono de engranaje de Hoy.
- R5. **Historial y Progreso, provisionales:** hasta T-014 y T-015, cada pestaña muestra un estado
  vacío neutro: "Aquí verás tu historial día por día." y "Aquí verás tus promedios y tu
  progreso.", con una ilustración simple. No se muestra ningún dato inventado.
- R6. **Estados del día sin alarma** (decisión 3 del rediseño): se definen tokens de estado para
  T-012 y T-014 sin rojo ni verde de alarma. "En la meta" = acento; "por debajo" = acento claro;
  "por encima" = acento oscuro `#1B2430`. El significado nunca depende solo del color: lleva texto
  o icono.
- R7. **Accesibilidad:** texto con contraste ≥ 4,5:1 (≥ 3:1 desde 24 px), áreas táctiles ≥ 44 px y
  etiquetas semánticas en los botones que solo tienen icono. La app respeta el tamaño de letra del
  sistema.

## Acceptance Criteria
- AC1. `MaterialApp` usa el tema nuevo: el color primario es `#3F6483`, la fuente por defecto es
  Outfit y el fondo es blanco `[widget]`.
- AC2. `pubspec.yaml` declara Outfit con sus 4 pesos como assets; no hay dependencia de
  `google_fonts` y la app no hace peticiones a `fonts.googleapis.com` ni `fonts.gstatic.com`
  `[revisión de código + grep]`.
- AC3. Navegación: al abrir la app con consentimiento vigente se ve Hoy con la barra inferior;
  tocar Historial o Progreso muestra su estado vacío (R5) y la barra marca la pestaña activa; tocar
  + abre "¿Qué comiste?"; al volver de registrar se ve Hoy actualizado `[widget + integration]`.
- AC4. El anillo de progreso dibuja la fracción que recibe (0, 0,5, 1) y la limita entre 0 y 1;
  muestra el contenido central `[widget]`.
- AC5. Contraste: el texto principal, el secundario y el texto blanco sobre el acento cumplen
  ≥ 4,5:1, calculado en un test con la fórmula de WCAG 2.x sobre los tokens `[unit]`.
- AC6. Los botones de la barra y el botón + miden ≥ 44 px y tienen etiqueta semántica en español
  `[widget]`.
- AC7. Las suites existentes siguen verdes: el contenido y el comportamiento de las pantallas no
  cambian, solo su aspecto `[unit + widget + integration]`.
- AC8. Recorrido manual en el teléfono: las pantallas actuales se ven con el tema nuevo, la barra
  funciona y no hay textos cortados con el tamaño de letra por defecto y con uno grande `[manual]`.

## Technical Constraints
- Invariante 9: la fuente y su licencia se verifican, no se suponen.
- Riverpod; las features no se importan entre sí. La navegación inferior vive en la raíz de
  composición (`app.dart`) o en un `shell` fuera de `features/`, y conecta las pestañas por ruta.
- Los tokens de color y los estilos se definen una sola vez; ninguna pantalla repite valores
  hexadecimales.

## Components / Files Affected
- `app/lib/ui/theme.dart` (tokens y `ThemeData`), `app/lib/ui/components/` (tarjeta, botones,
  anillo, encabezado).
- `app/lib/app.dart`: tema y shell de navegación.
- `app/lib/features/history/` y `app/lib/features/progress/` (provisionales, R5).
- `app/assets/fonts/` (Outfit + `OFL.txt`), `app/pubspec.yaml`.
- `docs/architecture.md`: sección de UI (tema, componentes, navegación).

## Dependencies
- Ninguna técnica. T-012 a T-020 dependen de esta SPEC.

## Edge Cases
- Tamaño de letra del sistema grande: los textos crecen sin cortarse; la barra inferior no tapa
  contenido (el contenido deja margen inferior).
- Pantallas que se abren desde Hoy (captura, revisión, Ajustes, perfil, objetivo) no muestran la
  barra inferior: es solo de las tres pantallas principales.
- Botón atrás de Android en Historial o Progreso: vuelve a Hoy, no cierra la app.
- Modo oscuro del sistema: fuera de alcance; la app se ve en claro.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? **No.** Embeber la fuente evita la petición a Google Fonts
  que haría `google_fonts` al abrir la app.

## Tests Required
- Unit: AC5.
- Widget: AC1, AC3, AC4, AC6.
- Revisión y grep: AC2.
- Suites completas: AC7.
- Manual: AC8.

## Out of Scope
- El rediseño de cada pantalla (T-012, T-013), el Historial real (T-014) y el Progreso real
  (T-015).
- Modo oscuro, animaciones y transiciones personalizadas.
- Ícono de la app y pantalla de arranque.

## Open Questions
- Ninguna. El modo oscuro queda fuera del MVP.

## Evidencia de Acceptance Criteria
| AC | Estado | Evidencia |
|----|--------|-----------|
| AC1 | ✅ | `app/test/ui/theme_test.dart` ("AC1…") |
| AC2 | ✅ | `app/pubspec.yaml` declara Outfit (200/300/400/500) desde `assets/fonts/`; grep (2026-10-03) sin `google_fonts`, `fonts.googleapis` ni `fonts.gstatic` en `lib/`, `pubspec.yaml` ni `pubspec.lock`. Licencia: SIL OFL 1.1, archivos de https://github.com/Outfitio/Outfit-Fonts en el commit `902773808eb372f70fb34e8946dd1ffe604efc79`, `app/assets/fonts/OFL.txt` |
| AC3 | ✅ | `app/test/ui/main_nav_test.dart` (pestañas, estados vacíos, + desde Hoy y Progreso, Atrás en Historial vuelve a Hoy) + suites de integración que registran desde Hoy y vuelven al diario |
| AC4 | ✅ | `app/test/ui/progress_ring_test.dart` |
| AC5 | ✅ | `app/test/ui/theme_test.dart`, grupo "AC5" (7 pares, todos ≥ 4,5:1; el menor, 4,87) |
| AC6 | ✅ | `main_nav_test.dart` ("AC6…") |
| AC7 | ✅ | `flutter analyze` sin issues; `flutter test` 169/169 (2026-10-03, tres corridas) |
| AC8 | ⏳ | Recorrido manual en el teléfono: se hace al final del lote (decisión de la usuaria) |

Decisión de implementación: los botones primario y secundario de R3 son `FilledButton` y
`OutlinedButton` con el estilo del tema (56 px, radio 28), no widgets nuevos; el encabezado usa el
`AppBarTheme` (título en el acento, 26 px, peso 300). Los dos tests de integración que buscaban el
texto "Hoy" ahora buscan el título de la pantalla, porque "Hoy" también está en la barra.

## Definition of Done
- AC1–AC8 con evidencia enlazada en esta SPEC.
- `flutter analyze` sin issues y `flutter test` verde.
- Reviewer: PASS enlazado.
- Licencia de Outfit verificada y citada.
- `docs/architecture.md` actualizado.

## Change Log
- 2026-10-03: creación a partir de T-011 de `docs/backlog.md` y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobado"). Status → Implementing.

- 2026-10-03: implementada (AC1–AC7); AC8 al final del lote. Status → Review.

## Review
Informe del reviewer: pendiente.
