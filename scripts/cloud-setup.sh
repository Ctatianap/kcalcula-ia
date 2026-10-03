#!/bin/bash
# Script de configuración del entorno de Claude Code en la nube (claude.ai/code).
# NO se ejecuta desde el repo: copia este archivo completo en el campo "Setup script"
# del entorno (selector de entornos en claude.ai/code). Corre como root en Ubuntu 24.04,
# antes de clonar el repo, y su resultado queda en caché (~7 días) si termina en < 5 min.
# Instala solo la cadena de herramientas; las dependencias del proyecto las instala
# scripts/cloud-session-start.sh (hook SessionStart en .claude/settings.json).
# Sin secretos: no usa credenciales de Firebase ni de Google Cloud.
set -euo pipefail

FLUTTER_VERSION=3.47.5
# SHA-256 publicado en releases_linux.json de Flutter para esta versión.
FLUTTER_SHA256=2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

if [ ! -x /opt/flutter/bin/flutter ]; then
  apt-get update -qq && apt-get install -y -qq xz-utils unzip libglu1-mesa >/dev/null || true
  curl -fsSL -o /tmp/flutter.tar.xz "$FLUTTER_URL"
  echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c -
  tar -xJf /tmp/flutter.tar.xz -C /opt
  rm /tmp/flutter.tar.xz
fi

# Flutter se ejecuta como root en la VM; git exige marcar el SDK como seguro.
git config --global --add safe.directory /opt/flutter
ln -sf /opt/flutter/bin/flutter /usr/local/bin/flutter
ln -sf /opt/flutter/bin/dart /usr/local/bin/dart

flutter config --no-analytics >/dev/null
dart --disable-analytics >/dev/null || true
# Descarga el SDK de Dart y los artefactos de prueba (sin Android/iOS: no hay emulador).
flutter precache --no-ios --no-web --no-linux --no-macos --no-windows --no-fuchsia
flutter --version
