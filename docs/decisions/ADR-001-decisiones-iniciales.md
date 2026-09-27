# ADR-001 — Decisiones iniciales de arquitectura

Estado: Aceptado · Fecha: 2026-09-27

## D1 — Backend proxy sin estado (Cloud Functions for Firebase, callable, TypeScript)
**Necesidad:** no exponer credenciales de IA en la app y limitar el uso del endpoint sin cuentas de usuario.
**Por qué:** App Check protege funciones callable con atestación del dispositivo (Play Integrity en Android,
DeviceCheck/App Attest en iOS). Los prompts versionados y la validación de esquema quedan en el servidor,
y el proveedor se puede cambiar sin publicar una versión nueva de la app.
**Alternativas:** Firebase AI Logic (llamadas desde la app, sin función propia): un componente menos, pero
los prompts quedan en el cliente, ata el proyecto a Gemini y limita la validación al cliente.
**Trade-off:** un segundo lenguaje (TypeScript) en una superficie pequeña.

## D2 — Catálogo nutricional empaquetado en la app
**Necesidad:** valores nutricionales trazables para alimentos colombianos y generales.
**Por qué:** TCAC 2018 (ICBF, alimentos colombianos, por 100 g de porción comestible) + USDA FoodData
Central (CC0, incluye pesos de porciones y platos compuestos), procesados en build a `catalog.db`.
Funciona offline, es determinista, no expone claves y no envía consultas a terceros.
**Alternativas:** API de FDC en tiempo real (requiere clave, latencia, depende de red); Open Food Facts
(orientado a productos empacados; se evalúa en la fase de marcas).
**Trade-off:** ampliar el catálogo requiere una nueva versión de la app. Licencia de la TCAC POR VERIFICAR.

## D3 — Reconocimiento de voz del sistema operativo
**Necesidad:** convertir voz en texto con bajo coste y latencia.
**Por qué:** coste cero, y el audio no pasa por nuestro backend.
**Alternativa:** STT en la nube (más consistente entre dispositivos Android, con coste y audio saliendo del dispositivo).
**Trade-off:** calidad variable según el dispositivo. Se mide en es-CO; si no alcanza, se cambia detrás de la misma interfaz.

## D4 — Etiquetas con LLM multimodal + validación determinista + confirmación del usuario
**Necesidad:** extraer tablas nutricionales conservando la estructura porción ↔ valor.
**Por qué:** el OCR local pierde la estructura de tabla; el LLM de visión la conserva. La foto de una etiqueta no contiene datos personales.
**Alternativa:** OCR en el dispositivo (ML Kit) + parser propio: gratis y privado, pero frágil con tablas.
**Trade-off:** coste por imagen y dependencia del proveedor.

## D5 — Drift (SQLite) para las bases locales
**Por qué:** madura, relacional y tipada; FTS5 para buscar alimentos; migraciones explícitas.
**Alternativas:** Isar o Hive (menos adecuadas para consultas relacionales).
**Trade-off:** más código de esquema. Cifrado: el del sistema operativo; SQLCipher POR VERIFICAR como mejora.

## D6 — Confianza calculada por reglas
**Por qué:** la autoevaluación de un LLM no es reproducible. Las reglas por `quantity_basis` sí lo son y se pueden testear.
**Trade-off:** menos matices; las reglas se ajustan vía Strict Path.

## D7 — Proveedor de IA detrás de un adaptador; Gemini vía Vertex AI como proveedor inicial
**Por qué:** mismo proyecto y facturación de Google Cloud que Firebase, sin API key adicional (credenciales
por defecto de la cuenta de servicio) y un proveedor menos. Confirmado por el usuario el 2026-09-27.
**Alternativas:** Anthropic u OpenAI detrás del mismo adaptador.
**Trade-off:** la elección se valida con evals antes de la beta. Modelo, región, precios y política de
retención de datos: POR VERIFICAR.
