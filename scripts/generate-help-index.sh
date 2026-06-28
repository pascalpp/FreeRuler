#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

help_resources_dir="$PWD/Free Ruler/FreeRuler.help/Contents/Resources"

for help_lproj_dir in "$help_resources_dir"/*.lproj; do
  language="$(basename "$help_lproj_dir" .lproj)"
  index_language="$language"

  if [[ "$language" == "English" ]]; then
    index_language="en"
  fi

  help_index="$help_lproj_dir/$language.lproj.helpindex"
  hiutil -I lsm -C -ag -s "$index_language" -f "$help_index" "$help_lproj_dir"
done
