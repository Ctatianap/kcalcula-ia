#!/usr/bin/env node
// PreToolUse (Bash): bloquea comandos destructivos y lectura de secretos;
// pide confirmación humana para despliegues, push y gcloud.
// Exit 2 + stderr = bloquear (el mensaje llega a Claude).
// JSON con permissionDecision "ask" = pedir confirmación al usuario.
// Es una defensa adicional, no la única: complementa las reglas deny de settings.json.
import { readFileSync } from "node:fs";

let command = "";
try {
  const input = JSON.parse(readFileSync(0, "utf8") || "{}");
  command = String(input?.tool_input?.command ?? "");
} catch {
  process.exit(0); // entrada ilegible: decide el sistema de permisos
}

const DENY = [
  [/\brm\s+(-\w*r\w*|--recursive)\b/i, "Borrado recursivo bloqueado. Borra archivos concretos."],
  [/\bgit\s+push\b.*(--force|--force-with-lease|\s-f\b)/i, "git push forzado bloqueado."],
  [/\bgit\s+reset\s+--hard\b/i, "git reset --hard bloqueado. Usa git stash o una rama."],
  [/\bgit\s+clean\s+-\w*f/i, "git clean -f bloqueado."],
  [/\bfirebase\s+\w+:delete\b/i, "Borrado de recursos de Firebase bloqueado."],
  [/\bgcloud\b.*\bdelete\b/i, "Borrado de recursos de Google Cloud bloqueado."],
  [/(^|[\s/'"=])\.env(\.(?!example\b)[\w-]+)?($|[\s'";|&)])/, "Acceso a archivos .env bloqueado (invariante 7)."],
  [/(service-account|credentials)[\w.-]*\.json/i, "Acceso a credenciales bloqueado (invariante 7)."],
  [/\bprintenv\b|^\s*env\s*$/i, "Volcado de variables de entorno bloqueado."],
];

const ASK = [
  [/\bfirebase\s+deploy\b/i, "Despliegue a Firebase: requiere confirmación humana."],
  [/\bgit\s+push\b/i, "git push: requiere confirmación humana."],
  [/\bgcloud\b/i, "Comando gcloud: requiere confirmación humana."],
];

for (const [re, reason] of DENY) {
  if (re.test(command)) {
    process.stderr.write(`BLOQUEADO por hook del proyecto: ${reason}\n`);
    process.exit(2);
  }
}

// Sesiones en la nube (claude.ai/code): git push sin forzar a ramas distintas de main
// pasa sin pedir confirmación, para que la sesión trabaje sola. main sigue protegida.
const cloud = process.env.CLAUDE_CODE_REMOTE === "true";
const cloudPush = cloud && /\bgit\s+push\b/i.test(command) && !/\bmain\b/.test(command);

for (const [re, reason] of ASK) {
  if (re.test(command) && !(cloudPush && /git/.test(re.source))) {
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: reason,
      },
    }));
    process.exit(0);
  }
}

process.exit(0);
