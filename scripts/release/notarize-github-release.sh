#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

run_from_root
require_tool ditto
require_tool xcrun

app_path="$(exported_app_path)"
notary_zip="$RELEASE_DIR/notary-upload.zip"

if [[ ! -d "$app_path" ]]; then
  echo "Exported app not found: $app_path" >&2
  echo "Run npm run release:github:export first." >&2
  exit 1
fi

rm -f "$notary_zip"
ditto -c -k --keepParent "$app_path" "$notary_zip"

notary_args=(submit "$notary_zip" --wait)

if [[ -n "${NOTARYTOOL_PROFILE:-}" ]]; then
  notary_args+=(--keychain-profile "$NOTARYTOOL_PROFILE")
elif [[ -n "${NOTARYTOOL_APPLE_ID:-}" && -n "${NOTARYTOOL_PASSWORD:-}" && -n "${NOTARYTOOL_TEAM_ID:-}" ]]; then
  notary_args+=(--apple-id "$NOTARYTOOL_APPLE_ID" --password "$NOTARYTOOL_PASSWORD" --team-id "$NOTARYTOOL_TEAM_ID")
else
  echo "Missing notarization credentials." >&2
  echo "Set NOTARYTOOL_PROFILE, or set NOTARYTOOL_APPLE_ID, NOTARYTOOL_PASSWORD, and NOTARYTOOL_TEAM_ID." >&2
  echo "You can create a profile with: xcrun notarytool store-credentials" >&2
  exit 1
fi

xcrun notarytool "${notary_args[@]}"
xcrun stapler staple "$app_path"

echo "Notarized and stapled: $app_path"
