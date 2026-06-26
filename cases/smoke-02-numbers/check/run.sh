#!/usr/bin/env bash
# Smoke grader. Runs in the sandbox. Prints RESULT pass=N total=N + CHECK lines.
# Tests that the adapter can read a file, recognise a pattern, and edit in place.
set -uo pipefail
source "$REPO_ROOT/lib/grader.sh"

file="numbers.txt"

if [ ! -f "$file" ]; then
  check_fail "_ replaced" "$file not found"
  check_fail "sequence correct" "$file not found"
  emit_result
  exit 0
fi

content=$(tr -s ' ' < "$file" | sed 's/^ //;s/ $//' | tr -d '\n')

# 1. Placeholder removed
if ! grep -q '_' "$file"; then check_pass "_ replaced"
else check_fail "_ replaced" "_ still present in file"; fi

# 2. Correct sequence
expected="1 1 2 3 5 8 13 21"
check_eq "sequence correct" "$expected" "$content"

emit_result
