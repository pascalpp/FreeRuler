#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

run_from_root
require_tool xcodebuild

if [[ ! -d "$ARCHIVE_PATH" ]]; then
  echo "Archive not found: $ARCHIVE_PATH" >&2
  echo "Run npm run release:github:archive first." >&2
  exit 1
fi

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  $(xcodebuild_provisioning_flags)

echo "Exported app: $(exported_app_path)"
