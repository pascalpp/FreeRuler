#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

run_from_root

require_tool git
require_tool gh
require_tool node
require_tool npm
require_tool xcodebuild
require_tool xcrun
require_tool ditto

if ! is_dry_run; then
  gh auth status >/dev/null
fi

if ! is_dry_run; then
  ensure_clean_worktree
else
  echo "Dry run: skipping clean worktree check."
fi
ensure_version_matches_xcode

tag="$(release_tag)"
zip_path="$(release_zip_path)"

if ! is_dry_run && git rev-parse "$tag" >/dev/null 2>&1; then
  echo "Release tag already exists locally: $tag" >&2
  exit 1
fi

if ! is_dry_run && git ls-remote --tags origin "refs/tags/$tag" | grep -q "$tag"; then
  echo "Release tag already exists on origin: $tag" >&2
  exit 1
fi

if [[ -e "$zip_path" && "${RELEASE_OVERWRITE:-}" != "1" ]]; then
  echo "Release zip already exists: $zip_path" >&2
  echo "Set RELEASE_OVERWRITE=1 to replace it." >&2
  exit 1
fi

if is_dry_run; then
  echo "Dry run: existing release tags are allowed and no GitHub release will be published."
fi

echo "GitHub release preflight passed for $tag."
