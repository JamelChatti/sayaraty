#!/bin/bash
# Configure la signature release et genere le .aab signe pour Google Play
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
ANDROID_DIR="$ROOT/android"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
KEY_PROPS="$ANDROID_DIR/key.properties"

if [ ! -f "$KEYSTORE" ]; then
  echo "Keystore introuvable. Creez-le d'abord avec :"
  echo '  "/c/Users/Home/.jdks/corretto-17.0.13/bin/keytool" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload'
  exit 1
fi

if [ ! -f "$KEY_PROPS" ]; then
  echo "=== Configuration de key.properties ==="
  echo -n "Mot de passe du keystore (celui choisi avec keytool) : "
  read -s STORE_PASS
  echo
  echo -n "Confirmez le mot de passe : "
  read -s STORE_PASS2
  echo
  if [ "$STORE_PASS" != "$STORE_PASS2" ]; then
    echo "Erreur : les mots de passe ne correspondent pas."
    exit 1
  fi
  cat > "$KEY_PROPS" << EOF
storePassword=$STORE_PASS
keyPassword=$STORE_PASS
keyAlias=upload
storeFile=../upload-keystore.jks
EOF
  echo "key.properties cree."
else
  echo "key.properties existe deja."
fi

echo ""
echo "=== Generation du bundle signe ==="
cd "$ROOT"
export GRADLE_USER_HOME="$ROOT/.gradle-home"
fvm flutter build appbundle --release

echo ""
echo "=== Verification de la signature ==="
JARSIGNER="/c/Users/Home/.jdks/corretto-17.0.13/bin/jarsigner"
AAB="$ROOT/build/app/outputs/bundle/release/app-release.aab"
if "$JARSIGNER" -verify "$AAB" 2>&1 | grep -q "jar verified"; then
  echo "OK : app-release.aab est SIGNE"
  echo "Fichier a uploader : $AAB"
else
  echo "ERREUR : le bundle n'est toujours pas signe."
  exit 1
fi
