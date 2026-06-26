#!/usr/bin/env bash
# Smoke grader. Runs in the sandbox. Prints RESULT pass=N total=N + CHECK lines.
# Tests that the adapter can locate and edit an existing file — the minimal
# capability needed for any tool-calling adapter to be useful.
set -uo pipefail
source "$REPO_ROOT/lib/grader.sh"

src="src/transform.js"

if [ -f "$src" ]; then
  if grep -q 'toLowerCase' "$src"; then check_pass "toLowerCase present"
  else check_fail "toLowerCase present" "toLowerCase not found in $src"; fi

  if ! grep -q 'toUpperCase' "$src"; then check_pass "toUpperCase removed"
  else check_fail "toUpperCase removed" "toUpperCase still present in $src"; fi
else
  check_fail "toLowerCase present" "$src not found"
  check_fail "toUpperCase removed" "$src not found"
fi

emit_result
