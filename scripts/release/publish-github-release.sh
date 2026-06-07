#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

run_from_root
require_tool git
require_tool node

tag="$(release_tag)"
zip_path="$(release_zip_path)"
appcast_path="$APPCAST_PATH"

if [[ ! -f "$zip_path" ]]; then
  echo "Release zip not found: $zip_path" >&2
  echo "Run npm run release:github:zip first." >&2
  exit 1
fi

if [[ ! -f "$appcast_path" ]]; then
  echo "Appcast not found: $appcast_path" >&2
  echo "Run npm run release:github:appcast first." >&2
  exit 1
fi

if is_dry_run; then
  echo "Dry run: would create or update draft GitHub release $tag with $zip_path and $appcast_path."
  exit 0
fi

require_tool gh
gh auth status >/dev/null

if ! git rev-parse "$tag" >/dev/null 2>&1; then
  git tag -a "$tag" -m "$tag"
fi

git push origin "$tag"

if gh release view "$tag" >/dev/null 2>&1; then
  gh release upload "$tag" "$zip_path" "$appcast_path" --clobber
else
  gh release create "$tag" "$zip_path" "$appcast_path" --title "$tag" --notes "$tag" --draft
fi

echo "Created or updated draft GitHub release: $tag"
