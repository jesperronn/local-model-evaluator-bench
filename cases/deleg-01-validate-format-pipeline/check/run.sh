#!/usr/bin/env bash
# Grader for the delegation case. Runs in the sandbox.
# Emits the authoritative RESULT + per-test CHECK lines (task success), then
# diagnostic CHECK lines about whether the adapter delegated to a subagent.
set -uo pipefail
cp "$CASE_DIR/check/pipeline.test.js" ./pipeline.test.js

# 1. Task success (authoritative): RESULT pass=N total=N + one CHECK per test.
bash "$REPO_ROOT/lib/node-test-score.sh" ./pipeline.test.js

# 2. Delegation diagnostic: folds an orchestrator adapter's `.delegation` marker
#    into checks.csv. Baseline single-agent adapters leave no marker (no CHECK).
source "$REPO_ROOT/lib/delegation-check.sh"
