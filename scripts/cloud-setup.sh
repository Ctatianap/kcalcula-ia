#!/bin/bash
# Script de configuración del entorno de Claude Code en la nube (claude.ai/code).
# NO se ejecuta desde el repo: copia este archivo completo en el campo "Script de configuración"
# del entorno (selector de entornos en claude.ai/code). Corre como root en Ubuntu 24.04 y su
# resultado queda en caché (~7 días) si termina en < 5 min.
# Instala solo Flutter; las dependencias del proyecto las instala scripts/cloud-session-start.sh
# (hook SessionStart en .claude/settings.json). Sin secretos.
# Nunca falla: si un paso falla, la sesión arranca igual y el detalle queda en
# /tmp/cloud-setup.log para que Claude lo lea y lo resuelva dentro de la sesión.
LOG=/tmp/cloud-setup.log
exec > >(tee -a "$LOG") 2>&1
echo "== cloud-setup $(date -u +%FT%TZ)"

FLUTTER_VERSION=3.47.5
# SHA-256 publicado en releases_linux.json de Flutter para esta versión.
FLUTTER_SHA256=2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

step() { echo "-- $*"; "$@" || echo "!! falló: $*"; }

if [ ! -x /opt/flutter/bin/flutter ]; then
  step apt-get update -qq
  step apt-get install -y -qq xz-utils unzip
  if step curl -fsSL --retry 3 -o /tmp/flutter.tar.xz "$FLUTTER_URL" &&
     echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c -; then
    step tar -xJf /tmp/flutter.tar.xz -C /opt
  else
    # Alternativa: clonar la etiqueta oficial desde GitHub.
    step git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git /opt/flutter
  fi
  rm -f /tmp/flutter.tar.xz
fi

if [ -x /opt/flutter/bin/flutter ]; then
  # Flutter corre como root en la VM; git exige marcar el SDK como seguro.
  git config --global --add safe.directory /opt/flutter
  ln -sf /opt/flutter/bin/flutter /usr/local/bin/flutter
  ln -sf /opt/flutter/bin/dart /usr/local/bin/dart
  step flutter config --no-analytics
  step flutter --version
else
  echo "!! Flutter no quedó instalado"
fi
echo "== fin cloud-setup"
exit 0
