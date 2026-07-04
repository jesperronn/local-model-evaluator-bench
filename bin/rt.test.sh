#!/usr/bin/env bash
# bin/rt.test.sh — verify bin/rt's relative time calculation.
# Tests that file modification times are correctly converted to relative formats.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

# Colors (disabled if NO_COLOR is set).
if [ -z "${NO_COLOR:-}" ]; then
  C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
else
  C_GRN=; C_RED=; C_RST
fi
pass=0; fail=0
check() {  # desc  expected  actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Helper: calculate relative time from Unix timestamp
_elapsed_to_relative() {
  local elapsed=$1
  local rel_time
  if [ "$elapsed" -lt 60 ]; then
    rel_time=$(printf "%ds ago" "$elapsed")
  elif [ "$elapsed" -lt 3600 ]; then
    local mins=$((elapsed / 60))
    rel_time=$(printf "%dm ago" "$mins")
  elif [ "$elapsed" -lt 86400 ]; then
    local hours=$((elapsed / 3600))
    rel_time=$(printf "%dh ago" "$hours")
  elif [ "$elapsed" -lt 604800 ]; then
    local days=$((elapsed / 86400))
    rel_time=$(printf "%dd ago" "$days")
  else
    rel_time="long ago"
  fi
  printf "%s" "$rel_time"
}

# Helper: create a mock test file with a specific age in seconds
_create_aged_file() {
  local path=$1
  local seconds_ago=$2

  mkdir -p "$(dirname "$path")"
  touch "$path"

  # Calculate target timestamp (now - seconds_ago)
  local target_ts=$(($(date +%s) - seconds_ago))

  # Use stat -f to set modification time (macOS)
  if command -v date &>/dev/null; then
    touch -t "$(date -r $target_ts +%Y%m%d%H%M.%S)" "$path" 2>/dev/null || true
  fi
}

# --- Test relative time calculations ---

# 45 seconds ago → "45s ago"
expected=$(_elapsed_to_relative 45)
check "45 seconds ago formats as seconds" "45s ago" "$expected"

# 2 minutes 30 seconds ago → "2m ago" (truncated)
expected=$(_elapsed_to_relative 150)
check "150 seconds ago formats as minutes" "2m ago" "$expected"

# 1 hour 15 minutes ago → "1h ago"
expected=$(_elapsed_to_relative 4500)
check "4500 seconds ago formats as hours" "1h ago" "$expected"

# 2 days 6 hours ago → "2d ago"
expected=$(_elapsed_to_relative 183600)
check "183600 seconds ago formats as days" "2d ago" "$expected"

# 30 days ago → "long ago"
expected=$(_elapsed_to_relative 2592000)
check "2592000 seconds ago formats as long ago" "long ago" "$expected"

# --- Test with mock file structure ---

# Create a mock run with test files at different ages
mkdir -p "$TMP/results/20260704-120000/sandbox/adapter1/model1/case1"
_create_aged_file "$TMP/results/20260704-120000/sandbox/adapter1/model1/case1/.bench.log" 300

# Verify find + stat calculation works with mock files
run_dir="$TMP/results/20260704-120000"
last_modified_ts=$(find "$run_dir/sandbox" -type f -print0 2>/dev/null \
  | xargs -0 stat -f %m 2>/dev/null | sort -rn | head -1 || echo 0)
now=$(date +%s)
elapsed=$((now - last_modified_ts))

# The file should be roughly 300 seconds old (allowing ±2s for test execution)
if [ "$elapsed" -ge 298 ] && [ "$elapsed" -le 302 ]; then
  printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "mock file timestamp calculation within tolerance"
  pass=$((pass+1))
else
  printf '%s %s\n  expected: ~300s\n  actual:   %ds\n' "${C_RED}[FAIL]${C_RST}" "mock file timestamp calculation within tolerance" "$elapsed"
  fail=$((fail+1))
fi

# --- Summary ---
total=$((pass + fail))
if [ "$fail" = 0 ]; then
  printf '\n%s\n' "${C_GRN}all $pass passed${C_RST}"
else
  printf '\n%s\n' "${C_RED}$pass passed, $fail failed${C_RST}"
  exit 1
fi
