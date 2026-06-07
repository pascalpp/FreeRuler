#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

output_dir="$PWD/Free Ruler/Images.xcassets/AppIcon.appiconset"
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
