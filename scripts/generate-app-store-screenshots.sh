#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

derived_data="$PWD/build/app-store-screenshots/DerivedData"
output_dir="${1:-$PWD/appstore/screenshots}"
app_executable="$derived_data/Build/Products/Debug/Free Ruler.app/Contents/MacOS/Free Ruler"

xcodebuild \
  -project "Free Ruler.xcodeproj" \
  -scheme "Free Ruler" \
  -configuration Debug \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  build

if [[ ! -x "$app_executable" ]]; then
  echo "Expected app executable not found: $app_executable" >&2
  exit 1
fi

"$app_executable" --generate-app-store-screenshots "$output_dir"
