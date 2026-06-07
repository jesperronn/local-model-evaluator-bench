#!/usr/bin/env bash
# Grade with a PRISTINE copy of the test (so editing the shipped test can't game
# the score). The agent was given the same test in the workdir to iterate on.
set -uo pipefail
cp "$CASE_DIR/check/filter.test.js" ./filter.test.js
exec bash "$REPO_ROOT/lib/node-test-score.sh" ./filter.test.js
