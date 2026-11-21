#!/usr/bin/env bash
# Wraps the .app inside an .xcarchive in Payload/ and zips it as an unsigned .ipa.
# Usage: bash scripts/package-ipa.sh [archive-path] [output-ipa]
set -euo pipefail

ARCHIVE="${1:-build/WKWVTests.xcarchive}"
OUT="${2:-build/WKWVTests-unsigned.ipa}"

APP="$(find "$ARCHIVE/Products/Applications" -maxdepth 1 -name '*.app' -print -quit)"
if [[ -z "$APP" ]]; then
  echo "No .app found in $ARCHIVE/Products/Applications" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
OUT_ABS="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
rm -f "$OUT_ABS"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir "$STAGE/Payload"
cp -R "$APP" "$STAGE/Payload/"
(cd "$STAGE" && zip -qr "$OUT_ABS" Payload)

echo "Wrote $OUT_ABS"
