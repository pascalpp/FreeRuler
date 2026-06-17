#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/FreeRulerTests/__Snapshots__/RulerSnapshotTests"
TMP_ROOT="${TMPDIR:-/tmp}"
GENERATOR="$TMP_ROOT/free-ruler-snapshot-generator"
MODULE_CACHE="$TMP_ROOT/free-ruler-snapshot-module-cache"

swiftc \
  -D SNAPSHOT_GENERATOR \
  -module-cache-path "$MODULE_CACHE" \
  -Xcc -fmodules-cache-path="$MODULE_CACHE/clang" \
  "$ROOT_DIR/Free Ruler/Prefs.swift" \
  "$ROOT_DIR/Free Ruler/Ruler.swift" \
  "$ROOT_DIR/Free Ruler/RulerTickLayout.swift" \
  "$ROOT_DIR/Free Ruler/UnitLabelView.swift" \
  "$ROOT_DIR/Free Ruler/ResizeHandleView.swift" \
  "$ROOT_DIR/Free Ruler/RuleView.swift" \
  "$ROOT_DIR/Free Ruler/HorizontalRule.swift" \
  "$ROOT_DIR/Free Ruler/VerticalRule.swift" \
  "$ROOT_DIR/Free Ruler/GroupedRulerWindow.swift" \
  "$ROOT_DIR/FreeRulerTests/RulerSnapshotTests.swift" \
  -o "$GENERATOR"

"$GENERATOR" "$OUTPUT_DIR"
