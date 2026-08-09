#!/bin/bash
# Lance l'app (cache Gradle local + nettoyage avant build)
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
export GRADLE_USER_HOME="$ROOT/.gradle-home"
mkdir -p "$GRADLE_USER_HOME"

echo "Arret Gradle + nettoyage..."
cd "$ROOT/android"
./gradlew.bat --stop 2>/dev/null || true
cd "$ROOT"
rm -rf build
fvm flutter clean
fvm flutter pub get

echo "Lancement sur le telephone..."
fvm flutter run "$@"
