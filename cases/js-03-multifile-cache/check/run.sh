#!/usr/bin/env bash
set -uo pipefail
cp "$CASE_DIR/check/cache.test.js" ./cache.test.js
exec bash "$REPO_ROOT/lib/node-test-score.sh" ./cache.test.js
