#!/usr/bin/env bash
# Builds the Web/ folder from pinned upstream commits. Only the quiz folders are copied.
# Also builds Generated/ (native NeoValues data and the legal documents the app shows) and
# Tests/neovalues-golden.json (reference results written by NeoValues' own code).
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

# Native NeoValues data, exported from the same filtered copy.
GEN="Generated"
rm -rf "$GEN"
mkdir -p "$GEN/legal"
node scripts/export-neovalues.js "$OUT/tests/neovalues" "$GEN/neovalues"

# Reference results for the Swift tests, from NeoValues' own scoring code and quiz.js.
node scripts/golden-neovalues.js "$OUT/tests/neovalues" Tests/neovalues-golden.json

# The legal documents the app shows. They are copied from this repository, not edited.
cp PRIVACY.md LEGAL_NOTICE.md ATTRIBUTION.md LICENSE "$GEN/legal/"

# 12Axes (MIT, copyright 8values (SapplyValues)), only the 12axes folder, pinned to one commit.
git clone -q "$AXES_REPO" "$WORK/politicaltests"
git -C "$WORK/politicaltests" checkout -q "$AXES_COMMIT"
cp -R "$WORK/politicaltests/12axes/." "$OUT/tests/axes/"
cp "$WORK/politicaltests/LICENSE" "$OUT/tests/axes/LICENSE-MIT.txt"

echo "Bundled NeoValues at $NEOVALUES_COMMIT (filtered) and 12Axes at $AXES_COMMIT into $OUT"
echo "Built $GEN/ (native data and legal documents) and Tests/neovalues-golden.json"
