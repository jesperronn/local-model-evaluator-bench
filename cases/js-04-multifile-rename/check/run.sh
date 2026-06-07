#!/usr/bin/env bash
set -uo pipefail
cp "$CASE_DIR/check/rename.test.js" ./rename.test.js
exec bash "$REPO_ROOT/lib/node-test-score.sh" ./rename.test.js
