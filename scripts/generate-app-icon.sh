#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

output_dir="$PWD/Free Ruler/Images.xcassets/AppIcon.appiconset"
help_resource_dir="$PWD/Free Ruler/FreeRuler.help/Contents/Resources"
help_shared_dir="$help_resource_dir/shrd"
help_html="$help_resource_dir/English.lproj/FreeRuler.html"
help_css="$help_shared_dir/styles.css"
binary="${TMPDIR:-/tmp}/freeruler-generate-app-icon"
module_cache="${TMPDIR:-/tmp}/freeruler-generate-app-icon-module-cache"

xcrun swiftc \
  -D APP_ICON_GENERATOR_CLI \
  -module-cache-path "$module_cache" \
  -framework AppKit \
  "Free Ruler/AppIconRenderer.swift" \
  "Free Ruler/AppIconGenerator.swift" \
  -o "$binary"

"$binary" "$output_dir"

icon_hash="$(shasum -a 256 "$output_dir/icon_512x512.png" | awk '{ print substr($1, 1, 12) }')"
generated_at="$(date -u +%Y%m%d%H%M%S)"
help_cache_token="${generated_at}-${icon_hash}"
help_icon_name="freeruler-help-icon-${help_cache_token}.png"
help_icon="$help_shared_dir/$help_icon_name"

cp "$output_dir/icon_512x512.png" "$help_icon"
rm -f "$help_shared_dir/freeruler.png"

for stale_icon in "$help_shared_dir"/freeruler-help-icon-*.png; do
  if [[ -e "$stale_icon" && "$stale_icon" != "$help_icon" ]]; then
    rm "$stale_icon"
  fi
done

HELP_ICON_NAME="$help_icon_name" perl -0pi -e \
  's#background-image: url\(\./(?:freeruler\.png|freeruler-help-icon-[^)]+)\);#background-image: url(./$ENV{HELP_ICON_NAME});#' \
  "$help_css"

HELP_CACHE_TOKEN="$help_cache_token" perl -0pi -e \
  's#href="\.\./shrd/styles\.css(?:\?[^"]*)?"#href="../shrd/styles.css?icon=$ENV{HELP_CACHE_TOKEN}"#' \
  "$help_html"
