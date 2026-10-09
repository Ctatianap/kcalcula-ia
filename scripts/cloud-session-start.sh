#!/bin/bash
# Hook SessionStart (.claude/settings.json): prepara el proyecto en las sesiones en la nube.
# En local sale sin hacer nada. Requiere que el entorno haya corrido scripts/cloud-setup.sh.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/..}" || exit 0

if ! command -v flutter >/dev/null; then
  echo "cloud-session-start: falta Flutter; configura el entorno con scripts/cloud-setup.sh" >&2
  exit 0
fi

(cd packages/nutrition_core && dart pub get) &
(cd data/build_catalog && dart pub get) &
(cd app && flutter pub get) &
(npm --prefix functions ci --no-audit --no-fund) &
wait

# catalog.db no se versiona: se regenera desde los CSV curados de data/ (sin red).
if [ ! -f app/assets/catalog/catalog.db ]; then
  (cd data/build_catalog && dart run) || echo "cloud-session-start: no se pudo generar catalog.db" >&2
fi
exit 0
