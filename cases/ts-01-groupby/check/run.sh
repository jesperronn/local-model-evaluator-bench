#!/usr/bin/env bash
set -uo pipefail
cp "$CASE_DIR/check/groupBy.test.ts" ./groupBy.test.ts
exec bash "$REPO_ROOT/lib/node-test-score.sh" ./groupBy.test.ts
