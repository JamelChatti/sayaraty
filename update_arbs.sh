#!/bin/bash

SOURCE="translations.json"

# Vérifier que jq est installé
if ! command -v jq &> /dev/null; then
  echo "❌ Erreur : jq n'est pas installé"
  echo "👉 Installe-le avec :"
  echo "   pacman -S jq   (MSYS / Git Bash)"
  echo "   ou"
  echo "   sudo apt install jq (Linux)"
  exit 1
fi

update_arb_file() {
  local lang=$1
  local file="assets/l10n/app_${lang}.arb"

  # Créer le fichier s'il n'existe pas
  if [ ! -f "$file" ]; then
    echo "{}" > "$file"
  fi

  keys=$(jq -r 'keys[]' "$SOURCE")

  for key in $keys; do
    value=$(jq -r --arg key "$key" --arg lang "$lang" '.[$key][$lang]' "$SOURCE")
    tmp=$(mktemp)
    jq --arg key "$key" --arg val "$value" '. + {($key): $val}' "$file" > "$tmp" && mv "$tmp" "$file"
  done

  echo "✅ $file mis à jour"
}

update_arb_file fr
update_arb_file en
update_arb_file ar
