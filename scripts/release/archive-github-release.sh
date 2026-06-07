#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

run_from_root
require_tool xcodebuild

if [[ -z "${SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
  echo "SPARKLE_PUBLIC_ED_KEY is required for GitHub release archives." >&2
  echo "Create one with Sparkle's generate_keys tool, then export the public key before releasing." >&2
  exit 1
fi

mkdir -p "$RELEASE_DIR"
rm -rf "$ARCHIVE_PATH"

xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$GITHUB_SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  SPARKLE_FEED_URL="$SPARKLE_FEED_URL" \
  SPARKLE_PUBLIC_ED_KEY="$SPARKLE_PUBLIC_ED_KEY" \
  $(xcodebuild_provisioning_flags)

echo "Created archive: $ARCHIVE_PATH"
