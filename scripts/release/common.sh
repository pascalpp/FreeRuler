#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELEASE_ENV_FILE="${RELEASE_ENV_FILE:-$ROOT_DIR/.env}"
PROJECT_PATH="$ROOT_DIR/Free Ruler.xcodeproj"
SCHEME_NAME="Free Ruler"
GITHUB_SCHEME_NAME="Free Ruler GitHub"
CONFIGURATION="Release"
APP_NAME="Free Ruler"
APP_BUNDLE_NAME="$APP_NAME.app"
RELEASE_DIR="$ROOT_DIR/build/release"
ARCHIVE_PATH="$RELEASE_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$RELEASE_DIR/export"
EXPORT_OPTIONS_PLIST="$ROOT_DIR/scripts/release/ExportOptions.github.plist"
APPCAST_PATH="$RELEASE_DIR/appcast.xml"
SPARKLE_FEED_URL="https://github.com/pascalpp/FreeRuler/releases/latest/download/appcast.xml"

load_release_env() {
  [[ -f "$RELEASE_ENV_FILE" ]] || return 0

  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    [[ -z "$line" || "${line:0:1}" == "#" ]] && continue

    if [[ "$line" == export[[:space:]]* ]]; then
      line="${line#export}"
      line="${line#"${line%%[![:space:]]*}"}"
    fi

    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    [[ -z "${!key+x}" ]] || continue

    if [[ "${#value}" -ge 2 ]]; then
      if [[ "${value:0:1}" == '"' && "${value: -1}" == '"' ]]; then
        value="${value:1:${#value}-2}"
      elif [[ "${value:0:1}" == "'" && "${value: -1}" == "'" ]]; then
        value="${value:1:${#value}-2}"
      fi
    fi

    export "$key=$value"
  done <"$RELEASE_ENV_FILE"
}

load_release_env

version() {
  node -p "require('./package.json').version"
}

release_tag() {
  if [[ -n "${RELEASE_TAG:-}" ]]; then
    printf "%s" "$RELEASE_TAG"
  else
    printf "v%s" "$(version)"
  fi
}

release_zip_path() {
  printf "%s/free-ruler-%s.zip" "$RELEASE_DIR" "$(version)"
}

release_zip_name() {
  printf "free-ruler-%s.zip" "$(version)"
}

release_zip_url() {
  printf "https://github.com/pascalpp/FreeRuler/releases/download/%s/%s" "$(release_tag)" "$(release_zip_name)"
}

exported_app_path() {
  printf "%s/%s" "$EXPORT_DIR" "$APP_BUNDLE_NAME"
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

run_from_root() {
  cd "$ROOT_DIR"
}

ensure_clean_worktree() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree has uncommitted changes. Commit or stash them before releasing." >&2
    exit 1
  fi
}

build_setting() {
  local setting="$1"
  xcodebuild -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -showBuildSettings 2>/dev/null \
    | awk -F ' = ' -v key="$setting" '$1 ~ key "$" { print $2; exit }'
}

ensure_version_matches_xcode() {
  local package_version
  local marketing_version
  package_version="$(version)"
  marketing_version="$(build_setting MARKETING_VERSION)"

  if [[ "$package_version" != "$marketing_version" ]]; then
    echo "package.json version ($package_version) does not match MARKETING_VERSION ($marketing_version)." >&2
    exit 1
  fi
}

xcodebuild_provisioning_flags() {
  if [[ "${ALLOW_PROVISIONING_UPDATES:-}" == "1" ]]; then
    printf "%s" "-allowProvisioningUpdates"
  fi
}

is_dry_run() {
  [[ "${RELEASE_DRY_RUN:-}" == "1" ]]
}
