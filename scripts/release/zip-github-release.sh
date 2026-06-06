#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

run_from_root
require_tool ditto

app_path="$(exported_app_path)"
zip_path="$(release_zip_path)"

if [[ ! -d "$app_path" ]]; then
  echo "Exported app not found: $app_path" >&2
  echo "Run npm run release:github:export first." >&2
  exit 1
fi

mkdir -p "$RELEASE_DIR"

if [[ -e "$zip_path" ]]; then
  if [[ "${RELEASE_OVERWRITE:-}" == "1" ]]; then
    rm -f "$zip_path"
  else
    echo "Release zip already exists: $zip_path" >&2
    echo "Set RELEASE_OVERWRITE=1 to replace it." >&2
    exit 1
  fi
fi

ditto -c -k --keepParent "$app_path" "$zip_path"

echo "Created zip: $zip_path"
