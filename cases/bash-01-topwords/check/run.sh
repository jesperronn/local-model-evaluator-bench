#!/usr/bin/env bash
# Grader for bash-01-topwords. Runs from sandbox root. Prints RESULT pass=N total=N.
set -uo pipefail
fix="$CASE_DIR/check/fixture.txt"
script="./bin/topwords.sh"
pass=0; total=0

check() { # <description> <expected> <actual>
  total=$((total+1))
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "  ok: $1" >&2
  else echo "  MISS: $1 -- expected [$2] got [$3]" >&2; fi
}

chmod +x "$script" 2>/dev/null

# n=3: descending count, alphabetical tie-break.
got3="$(bash "$script" "$fix" 3 2>/dev/null)"
check "top 3" $'3 the\n2 cat\n1 mat' "$got3"

# n=2: just the two clear winners.
got2="$(bash "$script" "$fix" 2 2>/dev/null)"
check "top 2" $'3 the\n2 cat' "$got2"

# n larger than distinct word count -> at most 6 lines, no crash.
got9="$(bash "$script" "$fix" 9 2>/dev/null)"
lines9="$(printf '%s\n' "$got9" | grep -c . )"
check "n>distinct prints <=6 lines" "true" "$([ "$lines9" -le 6 ] && [ "$lines9" -ge 4 ] && echo true || echo false)"

# top line is correct regardless of n.
top="$(printf '%s\n' "$got3" | head -1)"
check "most frequent word first" "3 the" "$top"

echo "RESULT pass=${pass} total=${total}"
