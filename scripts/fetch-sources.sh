#!/usr/bin/env bash
# Builds the Web/ folder from pinned upstream commits. Only the quiz folders are copied.
# Usage: bash scripts/fetch-sources.sh [output-dir]
set -euo pipefail

NEOVALUES_REPO="https://github.com/zore0010/neovalues"
NEOVALUES_COMMIT="b8dce4ef53d507763baddd7bcb634bcccd31eb88"

AXES_REPO="https://github.com/politicaltests/politicaltests.github.io"
AXES_COMMIT="5a508de557cc88eb7e9a44d89f45501dbe912d61"

OUT="${1:-Web}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

rm -rf "$OUT"
mkdir -p "$OUT/tests/neovalues" "$OUT/tests/axes"

# NeoValues (CC BY-NC-SA 4.0), from the fork, pinned to one commit.
git clone -q "$NEOVALUES_REPO" "$WORK/neovalues"
git -C "$WORK/neovalues" checkout -q "$NEOVALUES_COMMIT"
cp -R "$WORK/neovalues/." "$OUT/tests/neovalues/"
rm -rf "$OUT/tests/neovalues/.git"

# Remove the ideologies and answers excluded for distribution, and any file that names them.
node scripts/filter-neovalues.js "$OUT/tests/neovalues" scripts/neovalues-exclusions.json

# 12Axes (MIT, copyright 8values (SapplyValues)), only the 12axes folder, pinned to one commit.
git clone -q "$AXES_REPO" "$WORK/politicaltests"
git -C "$WORK/politicaltests" checkout -q "$AXES_COMMIT"
cp -R "$WORK/politicaltests/12axes/." "$OUT/tests/axes/"
cp "$WORK/politicaltests/LICENSE" "$OUT/tests/axes/LICENSE-MIT.txt"

echo "Bundled NeoValues at $NEOVALUES_COMMIT (filtered) and 12Axes at $AXES_COMMIT into $OUT"
