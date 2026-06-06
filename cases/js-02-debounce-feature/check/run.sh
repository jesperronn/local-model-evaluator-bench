#!/usr/bin/env bash
set -uo pipefail
cp "$CASE_DIR/check/debounce.test.js" ./debounce.test.js
exec bash "$REPO_ROOT/lib/node-test-score.sh" ./debounce.test.js
