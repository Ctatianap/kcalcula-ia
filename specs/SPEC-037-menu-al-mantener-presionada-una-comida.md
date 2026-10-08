# SPEC-037: Menú al mantener presionada una comida

## Status
Draft
Path: Standard (gesto nuevo en Hoy e Historial; reutiliza borrar y editar de SPEC-026; no sale ningún
dato)

## Objective
Que dejar presionada la tarjeta de una comida en Hoy o en Historial abra un menú con "Eliminar
comida", sin entrar a editarla.

## Context
Pedido de la usuaria (2026-10-08) al probar SPEC-026: "al dejar presionada la card salga un menú
parecido al de los 3 puntos […] que sea eliminar comida, siento que ese debería ser el gesto para
eliminar una comida, igual dejar la opción como está en el editar comida".

Hoy (SPEC-026): tocar la tarjeta abre "Editar comida", que tiene "Borrar comida" con confirmación
("¿Borrar el almuerzo de las 13:00?"). El menú ⋮ de los ingredientes (SPEC-033) es un menú emergente
con ícono y texto.

## User Story
Como persona que registró una comida por error, quiero dejarla presionada y eliminarla, sin abrirla.

## Requirements
- R1. **Gesto:** mantener presionada una tarjeta de comida en **Hoy** o en el día elegido del
  **Historial** abre un menú emergente junto a la tarjeta, con el mismo estilo del menú ⋮ de los
  ingredientes:
  - **"Editar comida"**: abre "Editar comida" (igual que tocarla);
  - **"Repetir hoy"**: solo en comidas de otros días (SPEC-026 R4);
  - **"Eliminar comida"**: en color de error, al final.
- R2. **Eliminar:** pide la misma confirmación de SPEC-026 R3 ("¿Borrar el almuerzo de las 13:00?" /
  "¿Borrar la cena…?"). Al confirmar borra la comida y sus ítems, **se queda en la misma pantalla**, la
  lista y los totales se actualizan, y aparece el aviso "Comida eliminada.". Cancelar no cambia nada.
- R3. **Error:** si borrar falla, aviso "No pude borrar la comida. Intenta de nuevo." y la comida sigue
  ahí (SPEC-009).
- R4. **Accesibilidad:** el lector de pantalla anuncia la tarjeta con "Toca para editar. Mantén
  presionado para más opciones" y ofrece la acción "Más opciones".
- R5. Tocar la tarjeta sigue abriendo "Editar comida", y "Borrar comida" sigue dentro de "Editar
  comida" (SPEC-026).
- R6. La confirmación y el texto con artículo ("el almuerzo", "la cena") se comparten entre "Editar
  comida", Hoy e Historial desde `app/lib/ui/`, porque las features no se importan entre sí.

## Acceptance Criteria
- AC1. En Hoy, mantener presionada la tarjeta del desayuno → menú con "Editar comida" y "Eliminar
  comida" (sin "Repetir hoy") `[widget]`.
- AC2. "Eliminar comida" → "¿Borrar el desayuno de las 8:30?" → "Borrar" → la tarjeta desaparece, las
  kcal del día bajan, aparece "Comida eliminada." y la pantalla sigue siendo Hoy `[widget +
  integration]`.
- AC3. "Cancelar" en la confirmación → la comida sigue `[widget]`.
- AC4. En Historial (día anterior), mantener presionada → menú con "Editar comida", "Repetir hoy" y
  "Eliminar comida"; eliminar actualiza ese día `[widget]`.
- AC5. Si borrar falla → el aviso de R3 y la comida sigue `[widget]`.
- AC6. "Editar comida" desde el menú abre "Editar comida" con esa comida `[widget]`.
- AC7. Los tests existentes de Hoy, Historial y SPEC-026 siguen verdes; los que cambien por mover la
  confirmación a `ui/` se listan en la Verificación `[widget + integration]`.

## Technical Constraints
- La UI pasa por `infra/storage` (`deleteMeal`). Errores como SPEC-009.
- Sin imports entre features (R6).

## Components / Files Affected
- `app/lib/ui/components/meal_card.dart` (`onLongPress` y semántica).
- `app/lib/ui/` (menú de la comida y confirmación compartida).
- `app/lib/features/diary/diary_screen.dart`, `app/lib/features/history/history_screen.dart`.
- `app/lib/features/review/meal_detail_view.dart` (usa la confirmación compartida).
- Tests de esas carpetas.

## Dependencies
- SPEC-026, SPEC-033 (estilo del menú), SPEC-009.

## Edge Cases
- Eliminar la única comida del día: Hoy vuelve al estado vacío ("Todavía no registras nada hoy").
- Eliminar baja la racha si era la única comida de ese día.
- Un toque largo en una zona sin tarjeta no hace nada.

## Security & Privacy
- ¿Sale algún dato nuevo del dispositivo? No.

## Tests Required
- Widget: AC1, AC3–AC6. Integration: AC2, AC7.
- Manual: mantener presionada una comida en el teléfono y eliminarla.

## Out of Scope
- Deshacer el borrado.
- Deslizar para borrar.
- Borrar varias comidas a la vez.

## Open Questions
- Ninguna. Decisión tomada: el menú incluye también "Editar comida" (y "Repetir hoy" en días
  anteriores) para que el gesto sirva para más que borrar.

## Definition of Done
- AC1–AC7 con evidencia · analyze y tests verdes en `app` · prueba manual · reviewer PASS enlazado.

## Change Log
- 2026-10-08: creación a pedido de la usuaria (gesto para eliminar una comida).

## Review
Informe del reviewer:
