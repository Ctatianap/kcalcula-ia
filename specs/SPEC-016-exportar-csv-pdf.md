# SPEC-016: Exportar en CSV y PDF

## Status
Done
Path: Strict (crea archivos con datos de salud que la persona puede compartir fuera del dispositivo)

## Objective
Que "Exportar mis datos" ofrezca, además del JSON actual, una hoja de cálculo (CSV) y un resumen en
PDF para la nutricionista, con filtro por periodo.

## Context
Backlog T-017. Diseño: artboard "Exportar datos" del lienzo
https://claude.ai/artifact/7SVwbLxMs9qjmGydrydhbD. Hoy existe "Exportar mis datos" en JSON con el
share sheet del sistema (SPEC-006 R7): el archivo se crea en el teléfono y la persona elige el
destino; la app no lo envía a ningún servidor.

## User Story
Como persona que lleva su registro, quiero exportar mis datos en un formato útil para mí o para mi
nutricionista.

## Requirements
- R1. **Pantalla "Exportar mis datos"** (abre desde Ajustes): resumen de lo que hay ("128 comidas · 45
  días · Perfil, objetivo y diario completo"), periodo ("Todo", "Últimos 30 días", "Elegir fechas") y
  formato:
  - **Hoja de cálculo (CSV):** "Ábrelo en Excel o Google Sheets".
  - **Resumen para imprimir (PDF):** "Ideal para tu nutricionista".
  - **Copia completa (JSON):** "Para guardar o mover tus datos" (el actual; siempre exporta todo,
    sin filtro).

  Nota fija: "El archivo se crea en tu teléfono y tú eliges dónde guardarlo." y botón "Exportar".
- R2. **CSV** (UTF-8 con BOM, separador `;`, decimales con coma, para Excel en es-CO): una fila por
  ítem de comida con fecha, hora, tipo de comida, alimento, gramos, kcal, proteína, carbohidratos,
  grasa, confianza y `source_ref`. Valores sin redondear a más de 1 decimal en macros y enteros en
  kcal (reglas de presentación de `docs/architecture.md`).
- R3. **PDF** (A4): título, periodo, meta vigente (kcal y macros), promedio diario y días en meta
  (SPEC-014), tabla de totales por día y lista de comidas por día. Pie: "Estimaciones calculadas por
  KCalcula IA; no reemplazan una valoración profesional.". **No incluye** fecha de nacimiento, sexo
  ni mantenimiento medido (minimización); sí el peso del periodo si hay registros (SPEC-015).
- R4. El periodo filtra CSV y PDF por fecha local de la comida.
- R5. Los archivos se crean en el directorio temporal y se entregan al share sheet, igual que el
  JSON; la app no los envía a ningún lado.
- R6. **Librería de PDF:** se elige y se verifica (versión estable actual, licencia, mantenimiento)
  al implementar; queda citada en la SPEC. El CSV no necesita librería.

## Acceptance Criteria
- AC1. CSV de 2 comidas (3 ítems) → encabezado + 3 filas con los campos de R2; acentos correctos al
  abrir en Excel (BOM) y decimales con coma `[unit]`.
- AC2. Periodo "Últimos 30 días" excluye una comida de hace 40 días en CSV y PDF `[unit]`.
- AC3. El PDF generado contiene el periodo, la meta, el promedio y la tabla por día, y **no** contiene
  la fecha de nacimiento ni el sexo `[unit, inspección del texto del PDF]`.
- AC4. "Exportar" con cada formato entrega un archivo con la extensión correcta al share sheet (fake)
  `[widget]`.
- AC5. El resumen superior cuenta comidas y días con registros `[widget]`.
- AC6. Sin comidas en el periodo → "No hay comidas en este periodo." y no se crea archivo `[widget]`.

## Technical Constraints
- Invariantes 3 (promedios de `nutrition_core`), 5 y 6. Errores como en SPEC-009.
- Dependencia nueva solo para PDF, con versión verificada (CLAUDE.md, Convenciones).

## Components / Files Affected
- `app/lib/features/settings/` (pantalla de exportar), `app/lib/infra/export/` (CSV y PDF),
  `app/pubspec.yaml`, `docs/privacy.md`.

## Dependencies
- SPEC-010; SPEC-014 para promedios y días en meta; SPEC-015 para el peso (si no está, el PDF va sin
  peso).

## Edge Cases
- Nombres de alimentos con `;` o comillas: se escapan según RFC 4180.
- Periodo con 90+ días: el PDF pagina.
- Fallo al escribir el archivo: mensaje y sin relanzar.

## Security & Privacy
- El archivo sale del dispositivo solo si la persona lo comparte. El PDF excluye datos del perfil
  que no hacen falta (R3). Se actualiza `docs/privacy.md` (fila de exportación).

## Tests Required
- Unit: AC1–AC3. Widget: AC4–AC6. Manual: abrir el CSV en una hoja de cálculo y el PDF en el
  teléfono.

## Out of Scope
- Enviar por correo desde la app, importar datos, exportación automática o programada.

## Open Questions
- Ninguna. La librería de PDF se verifica al implementar (R6).

## Definition of Done
- AC1–AC6 con evidencia; analyze y tests verdes; reviewer PASS; librería verificada y citada;
  `docs/privacy.md` actualizado; aprobación de la usuaria antes de fusionar (Strict).

## Librería de PDF (R6)
`pdf` 3.13.1 (https://pub.dev/packages/pdf, repositorio DavBfr/dart_pdf), verificada en la API de
pub.dev el 2026-10-03: versión estable más reciente, publicada el 2026-09-19, licencia Apache-2.0,
160 puntos de pub, SDK `>=3.12.0 <4.0.0`. Dart puro (sin código nativo ni red). Se declara en
`app/pubspec.yaml` con esa nota. El texto del PDF usa Outfit (OFL 1.1, ya embebida en la app).

## Evidencia
| AC | Evidencia |
|----|-----------|
| AC1 | `app/test/infra/export/meals_csv_test.dart` › "AC1: 2 comidas (3 ítems) → BOM, encabezado y 3 filas con ; y coma decimal" (y "edge case: nombres con ; o comillas se escapan (RFC 4180)") |
| AC2 | mismo archivo › "AC2: \"Últimos 30 días\" excluye una comida de hace 40 días en CSV y PDF" (CSV) y `summary_report_test.dart` › "AC2: el PDF de los últimos 30 días no incluye la comida de hace 40 días" |
| AC3 | `app/test/infra/export/summary_report_test.dart` › "AC3: periodo, meta, promedio, días en meta y tabla por día" y "AC3/R3: el PDF no contiene fecha de nacimiento, sexo ni mantenimiento medido" (inspección de todo el texto que dibuja el PDF; ver Change Log), "el PDF se genera (A4) y pagina con 100 días" |
| AC4 | `app/test/features/settings/export_screen_test.dart` › "AC4: \"Exportar\" con csv/pdf/json entrega un archivo .csv/.pdf/.json al share sheet"; `summary_report_test.dart` › "AC4: el servicio entrega .pdf al share sheet" |
| AC5 | `export_screen_test.dart` › "AC5: el resumen cuenta comidas y días con registros del periodo" |
| AC6 | `export_screen_test.dart` › "AC6: sin comidas en el periodo → mensaje y no se crea archivo" |

Además: el JSON ignora el periodo, "Elegir fechas" abre el selector (en español en la app), texto ×2
en 360 px, fallo del share sheet con mensaje (`settings_screen_test.dart`). Manual: abrir el CSV en
una hoja de cálculo y el PDF en el teléfono (usuaria).

## Change Log
- 2026-10-03: creación a partir de T-017 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.
- 2026-10-03: implementada (autorización única de la usuaria para el lote, incluidas las Strict).
  Detalles menores:
  - Librería `pdf` 3.13.1 (ver "Librería de PDF"). El PDF usa la fuente Outfit embebida: con las
    fuentes estándar de PDF no hay soporte Unicode completo.
  - AC3 "inspección del texto del PDF": el PDF solo dibuja las cadenas de `SummaryReport`, y el test
    inspecciona todas (`allText`); con una fuente TrueType embebida el texto dentro del archivo va
    codificado por glifos y no se puede buscar en los bytes. Además se comprueba que el archivo es un
    PDF y que pagina.
  - El resumen superior cuenta las comidas y los días del periodo elegido (el JSON, de todo); sin
    comidas en el periodo, el resumen dice "No hay comidas en este periodo." y "Exportar" queda
    deshabilitado (no se crea archivo).
  - Fecha en CSV "dd/mm/aaaa" y hora "hh:mm"; gramos con 1 decimal; tipo de comida y confianza en
    español; fin de línea CRLF.
  - "Últimos 30 días" = hoy y los 29 anteriores (como "Mes" en Progreso). "Elegir fechas" usa el
    selector de rango de Material; para que salga en español la app declara `es-CO` con
    `flutter_localizations` (paquete del SDK).
  - El PDF **no** incluye estatura, fecha de nacimiento, sexo ni mantenimiento medido; sí la meta vigente, el promedio y los días en meta (`nutrition_core`) y
    los registros de peso del periodo.
  - "Exportar mis datos" en Ajustes abre la pantalla nueva; la lógica del JSON pasó de
    `SettingsController` a `infra/export/export_service.dart` (mismo contenido y nombre de archivo).
  - La política solo se aclara (formatos de exportación) sin subir de versión: no sale ningún dato
    nuevo del teléfono por decisión de la app.
  Status → Review.
- 2026-10-03: reviewer **PASS** (commit 1a91efa; app 266/266), sin BLOCKER ni MAJOR. MINOR atendidos
  antes de fusionar:
  - "Cambiar fechas" junto al rango elegido (el segmento ya seleccionado no responde a otro toque);
  - error de lectura del resumen con "Reintentar" (SPEC-009 R4), con test;
  - el indicador de "Exportar" tiene etiqueta semántica ("Exportando…");
  - CSV: un texto que empieza por `=`, `+`, `-` o `@` lleva un apóstrofo delante para que la hoja
    de cálculo no lo tome como fórmula (OWASP), con test;
  - `date_format_es.dart` pasó de `ui/` a `format/` (módulo neutral): `infra/export` ya no depende de
    `ui/`;
  - el test del selector de fechas monta Material en es-CO y comprueba textos en español.
  - Al backlog (Fast Path): T-022 borrar exportaciones temporales anteriores y T-023 idioma
    declarado en iOS (`CFBundleLocalizations`).
  Fusionada en `develop` por la autorización única de la usuaria (incluidas las Strict). Sigue en
  Review hasta los pasos manuales en el teléfono.
- 2026-10-07: recorrido manual en el teléfono (Motorola edge 50 pro, Android 16, build debug de
  `develop` en `dc92f55`). La usuaria lo dio por bueno ("si ya creo que el resto esta bien").
  Status Review → Done.

## Review
Informe del reviewer (2026-10-03, commit 1a91efa): **PASS**. AC1–AC6 con evidencia; AC3 con
evidencia sustituta aceptada (la garantía es estructural: el PDF no recibe el perfil y solo dibuja
`SummaryReport`); `pdf` 3.13.1 verificada en `pubspec.lock`; sin red ni logs en la exportación;
locale es-CO sin efectos colaterales. MINOR atendidos o llevados al backlog (ver Change Log).
