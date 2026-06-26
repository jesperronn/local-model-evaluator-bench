#!/usr/bin/env bash
# Smoke grader. Runs in the sandbox. Prints RESULT pass=N total=N + CHECK lines.
# Lenient: any hello.txt that contains "OK" (case-insensitive) counts as the
# full path working — capability isn't the point, connectivity is.
set -uo pipefail
source "$REPO_ROOT/lib/grader.sh"

if [ -f hello.txt ]; then check_pass "hello.txt exists"; else check_fail "hello.txt exists" "hello.txt not created"; fi

if [ -f hello.txt ] && grep -qi 'ok' hello.txt; then check_pass "contains OK"; else check_fail "contains OK" "hello.txt missing/!contains OK"; fi

emit_result
