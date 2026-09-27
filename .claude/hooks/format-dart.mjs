#!/usr/bin/env node
// PostToolUse (Edit|Write): formatea archivos .dart editados. Nunca bloquea.
import { readFileSync, existsSync } from "node:fs";
import { spawnSync } from "node:child_process";

try {
  const input = JSON.parse(readFileSync(0, "utf8") || "{}");
  const file = String(input?.tool_input?.file_path ?? "");
  if (file.endsWith(".dart") && existsSync(file)) {
    spawnSync("dart", ["format", file], {
      stdio: "ignore",
      timeout: 25000,
      shell: process.platform === "win32",
    });
  }
} catch {
  // formateo best-effort: nunca interrumpe el flujo
}
process.exit(0);
