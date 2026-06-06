#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

run_from_root
require_tool xcodebuild

mkdir -p "$RELEASE_DIR"
rm -rf "$ARCHIVE_PATH"

xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  $(xcodebuild_provisioning_flags)

echo "Created archive: $ARCHIVE_PATH"
