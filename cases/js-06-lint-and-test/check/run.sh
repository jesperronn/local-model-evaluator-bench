#!/usr/bin/env bash
# Grade = test pass-rate + a lint check (1 point). Uses PRISTINE test + linter
# so the agent can't game them. Prints: RESULT pass=N total=N + CHECK lines.
set -uo pipefail
source "$REPO_ROOT/lib/grader.sh"
cp "$CASE_DIR/check/total.test.js" ./total.test.js
cp "$CASE_DIR/check/lint.sh" ./lint.sh

out="$(node --test --test-reporter=tap ./total.test.js 2>&1)"; echo "$out" >&2
printf '%s\n' "$out" | tap_to_checks   # per-test diagnostic CHECK lines
tp="$(printf '%s\n' "$out" | sed -nE 's/^# pass ([0-9]+)/\1/p' | tail -1)"; tp=${tp:-0}
tt="$(printf '%s\n' "$out" | sed -nE 's/^# tests ([0-9]+)/\1/p' | tail -1)"; tt=${tt:-0}

if bash ./lint.sh >&2; then lp=1; echo "CHECK pass lint"; else lp=0; echo "CHECK fail lint"; fi
echo "  lint check: ${lp}/1" >&2

# Aggregate stays authoritative (TAP # counts + lint), independent of the
# diagnostic CHECK lines above.
echo "RESULT pass=$((tp + lp)) total=$((tt + 1))"
