#!/usr/bin/env bash
# Grader. Runs from the sandbox root (CWD). $CASE_DIR = original case dir,
# $REPO_ROOT = repo root. Must print: RESULT pass=N total=N
set -uo pipefail
cp "$CASE_DIR/check/slugify.test.js" ./slugify.test.js
exec bash "$REPO_ROOT/lib/node-test-score.sh" ./slugify.test.js
