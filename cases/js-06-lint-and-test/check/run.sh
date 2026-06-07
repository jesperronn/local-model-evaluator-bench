#!/usr/bin/env bash
# Grade = test pass-rate + a lint check (1 point). Uses PRISTINE test + linter
# so the agent can't game them. Prints: RESULT pass=N total=N
set -uo pipefail
cp "$CASE_DIR/check/total.test.js" ./total.test.js
cp "$CASE_DIR/check/lint.sh" ./lint.sh

out="$(node --test --test-reporter=tap ./total.test.js 2>&1)"; echo "$out" >&2
tp="$(printf '%s\n' "$out" | sed -nE 's/^# pass ([0-9]+)/\1/p' | tail -1)"; tp=${tp:-0}
tt="$(printf '%s\n' "$out" | sed -nE 's/^# tests ([0-9]+)/\1/p' | tail -1)"; tt=${tt:-0}

if bash ./lint.sh >&2; then lp=1; else lp=0; fi
echo "  lint check: ${lp}/1" >&2

echo "RESULT pass=$((tp + lp)) total=$((tt + 1))"
