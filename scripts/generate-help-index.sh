#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

help_lproj_dir="$PWD/Free Ruler/FreeRuler.help/Contents/Resources/English.lproj"
help_index="$help_lproj_dir/English.lproj.helpindex"

hiutil -I lsm -C -ag -s en -f "$help_index" "$help_lproj_dir"
