#!/usr/bin/env bash
# Minimal test for bin/topwords.sh — run with: ./test.sh
set -uo pipefail
script="./bin/topwords.sh"
fix="./fixture.txt"
chmod +x "$script" 2>/dev/null
fail=0

check() {
  local name="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    echo "ok - $name"
  else
    echo "not ok - $name"
    echo "  want: $(printf '%q' "$want")"
    echo "  got:  $(printf '%q' "$got")"
    fail=1
  fi
}

got3="$(bash "$script" "$fix" 3 2>/dev/null)"
check "top 3" $'3 the\n2 cat\n1 mat' "$got3"

got2="$(bash "$script" "$fix" 2 2>/dev/null)"
check "top 2" $'3 the\n2 cat' "$got2"

top="$(printf '%s\n' "$got3" | head -1)"
check "most frequent word first" "3 the" "$top"

exit "$fail"
