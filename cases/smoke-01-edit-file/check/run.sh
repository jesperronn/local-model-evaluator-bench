#!/usr/bin/env bash
# Smoke grader. Runs in the sandbox. Prints RESULT pass=N total=N + CHECK lines.
# Tests that the adapter can locate, read, and edit an existing file — proves
# replace-tool usage, not full file rewrite.
set -uo pipefail
source "$REPO_ROOT/lib/grader.sh"

file="greeting.txt"

if [ ! -f "$file" ]; then
  check_fail "hello inserted" "$file not found"
  check_fail "file integrity" "$file not found"
  emit_result
  exit 0
fi

# 1. Check "hello" was inserted (case-insensitive, on its own line)
if grep -iq '^hello$' "$file"; then
  check_pass "hello inserted"
else
  check_fail "hello inserted" "word 'hello' not found on its own line in $file"
fi

# 2. Check file has exactly 3 lines (start, hello, end — proves edit, not rewrite)
line_count=$(grep -c '' "$file")
if [ "$line_count" -eq 3 ]; then
  check_pass "structure intact (3 lines: start, hello, end)"
else
  check_fail "structure intact (3 lines: start, hello, end)" "$file has $line_count lines, expected 3"
fi

emit_result
