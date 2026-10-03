# SPEC-016: Exportar en CSV y PDF

## Status
Approved
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

## Change Log
- 2026-10-03: creación a partir de T-017 y del diseño "kcalcula ia UI".
- 2026-10-03: **Approved por la usuaria** ("aprobadas", junto con SPEC-011 a SPEC-019). Los recorridos manuales en el teléfono se agrupan al final del lote.

## Review
Informe del reviewer: pendiente.
