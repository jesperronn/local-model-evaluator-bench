#!/usr/bin/env bash
# Smoke grader. Runs in the sandbox. Prints RESULT pass=N total=N.
# Lenient: any hello.txt that contains "OK" (case-insensitive) counts as the
# full path working — capability isn't the point, connectivity is.
set -uo pipefail
pass=0; total=2

if [ -f hello.txt ]; then pass=$((pass+1)); echo "  ok: hello.txt exists" >&2
else echo "  MISS: hello.txt not created" >&2; fi

if [ -f hello.txt ] && grep -qi 'ok' hello.txt; then pass=$((pass+1)); echo "  ok: contains OK" >&2
else echo "  MISS: hello.txt missing/!contains OK" >&2; fi

echo "RESULT pass=${pass} total=${total}"
