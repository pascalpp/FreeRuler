#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

"$script_dir/check-github-release.sh"
"$script_dir/archive-github-release.sh"
"$script_dir/export-github-release.sh"

if [[ "${RELEASE_SKIP_NOTARIZE:-}" == "1" ]]; then
  echo "Skipping notarization because RELEASE_SKIP_NOTARIZE=1."
else
  "$script_dir/notarize-github-release.sh"
fi

"$script_dir/zip-github-release.sh"
"$script_dir/publish-github-release.sh"
