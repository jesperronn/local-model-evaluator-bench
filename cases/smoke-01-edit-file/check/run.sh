#!/usr/bin/env bash
# Smoke grader. Runs in the sandbox. Prints RESULT pass=N total=N.
# Tests that the adapter can locate and edit an existing file — the minimal
# capability needed for any tool-calling adapter to be useful.
set -uo pipefail
pass=0; total=2

src="src/transform.js"

if [ -f "$src" ]; then
  if grep -q 'toLowerCase' "$src"; then
    pass=$((pass+1)); echo "  ok: toLowerCase present" >&2
  else
    echo "  MISS: toLowerCase not found in $src" >&2
  fi

  if ! grep -q 'toUpperCase' "$src"; then
    pass=$((pass+1)); echo "  ok: toUpperCase removed" >&2
  else
    echo "  MISS: toUpperCase still present in $src" >&2
  fi
else
  echo "  MISS: $src not found" >&2
fi

echo "RESULT pass=${pass} total=${total}"
