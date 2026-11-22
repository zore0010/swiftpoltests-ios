#!/usr/bin/env bash
# Builds the Web/ folder from pinned upstream commits. Only the quiz folders are copied.
# Also builds Generated/ (native NeoValues data and the legal documents the app shows) and
# Tests/neovalues-golden.json (reference results written by NeoValues' own code).
# Usage: bash scripts/fetch-sources.sh [output-dir]
set -euo pipefail

OUT="${1:-Web}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# clone <repo> <commit> <name>: a clean checkout at a pinned commit, in $WORK/<name>.
clone() {
  git clone -q "$1" "$WORK/$3"
  git -C "$WORK/$3" checkout -q "$2"
  rm -rf "$WORK/$3/.git"
}

# copy_root <name> <test-id>: a repository's files become one test folder.
copy_root() {
  mkdir -p "$OUT/tests/$2"
  cp -R "$WORK/$1/." "$OUT/tests/$2/"
}

NEOVALUES_COMMIT="b8dce4ef53d507763baddd7bcb634bcccd31eb88"
AXES_COMMIT="5a508de557cc88eb7e9a44d89f45501dbe912d61"

rm -rf "$OUT"
mkdir -p "$OUT/tests/neovalues"

# NeoValues (CC BY-NC-SA 4.0), from the fork, pinned to one commit.
clone https://github.com/zore0010/neovalues "$NEOVALUES_COMMIT" neovalues
cp -R "$WORK/neovalues/." "$OUT/tests/neovalues/"

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

# politicaltests (MIT, copyright 2020 8values (SapplyValues)): 12 Axes, AuthValues and InfValues.
clone https://github.com/politicaltests/politicaltests.github.io "$AXES_COMMIT" politicaltests
mkdir -p "$OUT/tests/axes" "$OUT/tests/auth" "$OUT/tests/inf"
cp -R "$WORK/politicaltests/12axes/." "$OUT/tests/axes/"
cp -R "$WORK/politicaltests/auth/." "$OUT/tests/auth/"
cp -R "$WORK/politicaltests/inf/." "$OUT/tests/inf/"
for t in axes auth inf; do cp "$WORK/politicaltests/LICENSE" "$OUT/tests/$t/LICENSE-MIT.txt"; done
# The shared icons folder of the repository: the quizzes refer to it as ../icons/.
for t in axes auth inf; do cp -R "$WORK/politicaltests/icons" "$OUT/tests/$t/icons"; done

# RightValues (MIT).
clone https://github.com/rightvaluestest/rightvaluestest.github.io e655d615423757c9d207c4542274e35603b28873 rightvalues
copy_root rightvalues rightvalues
cp "$WORK/rightvalues/LICENSE" "$OUT/tests/rightvalues/LICENSE.txt"

# 10Groups (MIT, copyright 8values).
clone https://github.com/10Groups/10groups.github.io f984ba4b9240daceaf1b335bb9b69ab8afa81c10 10groups
copy_root 10groups 10groups
cp "$WORK/10groups/LICENSE.txt" "$OUT/tests/10groups/LICENSE.txt"

# 8Dreams (MIT, copyright 2017 8values). The repository has no LICENSE file; its license page holds the text.
clone https://github.com/8Dreams/8dreams.github.io 80ca1ca25482e215e5b2e42c4734200ff2a9d873 8dreams
copy_root 8dreams 8dreams
python3 - "$WORK/8dreams/license.html" "$OUT/tests/8dreams/LICENSE.txt" <<'PY'
import re, sys
html = open(sys.argv[1], encoding="utf-8").read()
html = re.sub(r"<script[\s\S]*?</script>", "", html)
text = re.sub(r"<[^>]+>", "", html).strip()
text = re.sub(r"\n\s*\n+", "\n\n", text)
open(sys.argv[2], "w", encoding="utf-8").write(text + "\n")
PY

# NeoValues-family quizzes by neomediavalist (CC BY-NC-SA 4.0).
clone https://github.com/neomediavalist/theovalues bae011807dd280c538d2a4cf2ef9688660a0cf45 theovalues
copy_root theovalues theovalues
cp "$WORK/theovalues/LICENSE" "$OUT/tests/theovalues/LICENSE.txt"

clone https://github.com/neomediavalist/ReligioQuest 46b945cd122cb6e6e41647cb4b67047b5634b1a6 religioquest
copy_root religioquest religioquest
cp "$WORK/religioquest/LICENSE" "$OUT/tests/religioquest/LICENSE.txt"

clone https://github.com/neomediavalist/mytests 8be6c831495aed1fc52f5fc1343d4cac3fd8a045 mytests
copy_root mytests mytests
cp "$WORK/mytests/LICENSE" "$OUT/tests/mytests/LICENSE.txt"

# Remove analytics and ads, bundle every script, stylesheet and font, remove the fascist ideologies,
# fix the paths, and fail if anything external or missing is left.
node scripts/import-tests.js "$OUT"

echo "Bundled NeoValues at $NEOVALUES_COMMIT (filtered), the politicaltests quizzes at $AXES_COMMIT, and the other imported quizzes into $OUT"
echo "Built $GEN/ (native data and legal documents) and Tests/neovalues-golden.json"
