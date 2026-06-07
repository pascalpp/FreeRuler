#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

run_from_root
require_tool codesign
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

app_path="$(exported_app_path)"
developer_id_identity="${DEVELOPER_ID_APPLICATION_IDENTITY:-Developer ID Application}"

codesign \
  --force \
  --deep \
  --options runtime \
  --preserve-metadata=identifier,entitlements,requirements \
  --sign "$developer_id_identity" \
  "$app_path"
codesign --verify --deep --strict --verbose=4 "$app_path"

echo "Exported and signed app: $app_path"
