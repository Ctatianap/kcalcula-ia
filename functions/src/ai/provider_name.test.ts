import { test } from "node:test";
import assert from "node:assert/strict";
import { resolveProviderName } from "./provider_name.js";

test("SPEC-029: sin configuración → fake", () => {
  assert.equal(resolveProviderName({}), "fake");
  assert.equal(resolveProviderName({ FUNCTIONS_EMULATOR: "true" }), "fake");
});

test("SPEC-029 R2: desplegado con DEPLOYED_AI_PROVIDER=vertex → vertex", () => {
  assert.equal(resolveProviderName({ DEPLOYED_AI_PROVIDER: "vertex" }), "vertex");
});

test("SPEC-029 R4/AC5: el emulador ignora DEPLOYED_AI_PROVIDER", () => {
  assert.equal(
    resolveProviderName({ FUNCTIONS_EMULATOR: "true", DEPLOYED_AI_PROVIDER: "vertex" }),
    "fake",
  );
});

test("SPEC-029 R4: en el emulador AI_PROVIDER sigue eligiendo el proveedor", () => {
  const deployed = { FUNCTIONS_EMULATOR: "true", DEPLOYED_AI_PROVIDER: "vertex" };
  assert.equal(resolveProviderName({ ...deployed, AI_PROVIDER: "ollama" }), "ollama");
  assert.equal(resolveProviderName({ ...deployed, AI_PROVIDER: "vertex" }), "vertex");
});

test("SPEC-029: desplegado sin DEPLOYED_AI_PROVIDER respeta AI_PROVIDER", () => {
  assert.equal(resolveProviderName({ AI_PROVIDER: "vertex" }), "vertex");
  assert.equal(
    resolveProviderName({ AI_PROVIDER: "vertex", DEPLOYED_AI_PROVIDER: "fake" }),
    "fake",
  );
});

test("SPEC-029: un valor desconocido → fake", () => {
  assert.equal(resolveProviderName({ DEPLOYED_AI_PROVIDER: "gemini" }), "fake");
});
