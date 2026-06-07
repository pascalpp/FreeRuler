#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

run_from_root
require_tool node

sign_update_tool="${SPARKLE_SIGN_UPDATE:-sign_update}"
require_tool "$sign_update_tool"

zip_path="$(release_zip_path)"
zip_url="$(release_zip_url)"
version="$(version)"
tag="$(release_tag)"
release_notes_url="https://github.com/pascalpp/FreeRuler/releases/tag/$tag"

if [[ ! -f "$zip_path" ]]; then
  echo "Release zip not found: $zip_path" >&2
  echo "Run npm run release:github:zip first." >&2
  exit 1
fi

signature_output="$("$sign_update_tool" "$zip_path")"

if [[ "$signature_output" != sparkle:edSignature* ]]; then
  echo "Unexpected sign_update output:" >&2
  echo "$signature_output" >&2
  exit 1
fi

mkdir -p "$RELEASE_DIR"

node - "$APPCAST_PATH" "$version" "$tag" "$zip_url" "$release_notes_url" "$signature_output" <<'NODE'
const fs = require('fs');

const [
  appcastPath,
  version,
  tag,
  zipURL,
  releaseNotesURL,
  signatureAttributes,
] = process.argv.slice(2);

function escapeXML(value) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

const pubDate = new Date().toUTCString();
const appcast = `<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Free Ruler Updates</title>
    <link>https://github.com/pascalpp/FreeRuler/releases</link>
    <description>Free Ruler release updates</description>
    <item>
      <title>${escapeXML(tag)}</title>
      <sparkle:releaseNotesLink>${escapeXML(releaseNotesURL)}</sparkle:releaseNotesLink>
      <pubDate>${escapeXML(pubDate)}</pubDate>
      <enclosure
        url="${escapeXML(zipURL)}"
        sparkle:version="${escapeXML(version)}"
        sparkle:shortVersionString="${escapeXML(version)}"
        ${signatureAttributes}
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
`;

fs.writeFileSync(appcastPath, appcast);
NODE

echo "Created appcast: $APPCAST_PATH"
