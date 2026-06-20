#!/usr/bin/env bash
# Smoke grader. Runs in the sandbox. Prints RESULT pass=N total=N.
# Tests that the adapter can read a file, recognise a pattern, and edit in place.
set -uo pipefail
pass=0; total=2

file="numbers.txt"

if [ ! -f "$file" ]; then
  echo "  MISS: $file not found" >&2
  echo "RESULT pass=0 total=${total}"
  exit 0
fi

content=$(tr -s ' ' < "$file" | sed 's/^ //;s/ $//' | tr -d '\n')

# 1. Placeholder removed
if ! grep -q '_' "$file"; then
  pass=$((pass+1)); echo "  ok: _ replaced" >&2
else
  echo "  MISS: _ still present in file" >&2
fi

# 2. Correct sequence
expected="1 1 2 3 5 8 13 21"
if [ "$content" = "$expected" ]; then
  pass=$((pass+1)); echo "  ok: sequence correct (${expected})" >&2
else
  echo "  MISS: expected '${expected}', got '${content}'" >&2
fi

echo "RESULT pass=${pass} total=${total}"
