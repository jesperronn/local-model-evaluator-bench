#!/usr/bin/env bash
# bin/setup.test.sh — verify the interactive auto-rerun confirm behavior in bin/setup.
# Only 'y'/'Y' within the timeout window should re-run with --force; everything
# else (n, other keys, or timing out) must exit without installing.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
pass=0; fail=0
check() {  # desc  expected  actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}

# Mirrors the confirm block in bin/setup: reads one char with a timeout,
# prints what action would be taken ("force" or "exit").
confirm_action() {
  local response
  if read -t 5 -r -n 1 response 2>/dev/null; then
    case "$response" in
      [yY]) printf 'force\n' ;;
      *)    printf 'exit\n' ;;
    esac
  else
    printf 'exit\n'
  fi
}

check "'y' triggers --force re-run" "force" "$(printf 'y' | confirm_action)"
check "'Y' triggers --force re-run" "force" "$(printf 'Y' | confirm_action)"
check "'n' exits without installing" "exit" "$(printf 'n' | confirm_action)"
check "other key exits without installing" "exit" "$(printf 'x' | confirm_action)"
check "no input (timeout) exits without installing" "exit" "$(: | confirm_action)"

# Verify the timeout in bin/setup was bumped from 3s to 5s.
timeout_line=$(grep -n 'read -t [0-9]* -r -n 1 response' "$HERE/bin/setup")
check "bin/setup uses a 5s read timeout" "1" "$(printf '%s' "$timeout_line" | grep -c 'read -t 5 ')"

# Verify the timeout branch no longer auto-force-installs.
timeout_branch=$(awk '/# Timeout: /,/^    fi$/' "$HERE/bin/setup")
check "timeout branch does not exec --force" "0" "$(printf '%s' "$timeout_branch" | grep -c 'exec ')"

# --- Summary ---
if [ "$fail" = 0 ]; then
  printf '\n%s\n' "${C_GRN}all $pass passed${C_RST}"
else
  printf '\n%s\n' "${C_RED}$pass passed, $fail failed${C_RST}"
  exit 1
fi
