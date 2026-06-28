#!/usr/bin/env bash
# Smoke grader. Runs in the sandbox. Prints RESULT pass=N total=N + CHECK lines.
# Tests that the adapter can locate, read, and edit an existing file — proves
# replace-tool usage, not full file rewrite (3-line file must still be 3 lines).
set -uo pipefail
source "$REPO_ROOT/lib/grader.sh"

src="src/transform.js"

if [ ! -f "$src" ]; then
  check_fail "hello inserted" "$src not found"
  check_fail "file integrity" "$src not found"
  emit_result
  exit 0
fi

# 1. Check "hello" was inserted
if grep -q '^[[:space:]]*hello[[:space:]]*$' "$src"; then
  check_pass "hello inserted"
else
  check_fail "hello inserted" "word 'hello' not found on its own line in $src"
fi

# 2. Check file still has exactly 3 lines (proves edit, not rewrite)
line_count=$(wc -l < "$src")
if [ "$line_count" -eq 3 ]; then
  check_pass "file integrity (3 lines, edit-in-place confirmed)"
else
  check_fail "file integrity (3 lines, edit-in-place confirmed)" "file has $line_count lines, expected 3"
fi

emit_result
