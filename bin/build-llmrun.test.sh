#!/usr/bin/env bash
# bin/build-llmrun.test.sh — verify build-llmrun's output without loading models.
# Tests that the generated llmrun script is syntactically valid, has no unsubstituted
# template variables, contains all required config values, and the adapter directory exists.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

# Source config and common for env vars and helpers
source "$HERE/config.sh"
source "$HERE/lib/common.sh"

# Use temp directory for generated script
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

pass=0; fail=0
check() {  # desc  expected  actual
  if [ "$2" = "$3" ]; then
    printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"
    pass=$((pass+1))
  else
    printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"
    fail=$((fail+1))
  fi
}

# ── Test 1: Generate script with --dest= ─────────────────────────────────────
info "Testing build-llmrun output generation..."

# --dest= expects a directory path, not a file (build-llmrun appends /llmrun)
GENERATED_SCRIPT="$TMPDIR_TEST/llmrun"
# Run build-llmrun with --dest= to write to temp directory
if ! "$HERE/bin/build-llmrun" --dest="$TMPDIR_TEST" >/dev/null 2>&1; then
  printf '%s\n' "${C_RED}[FAIL]${C_RST} Failed to run build-llmrun"
  exit 1
fi

[ -f "$GENERATED_SCRIPT" ] || {
  printf '%s\n' "${C_RED}[FAIL]${C_RST} Failed to generate script at $GENERATED_SCRIPT"
  exit 1
}

# ── Test 2: No unsubstituted placeholders ──────────────────────────────────────
# Check for patterns like @@VARNAME@@ still in the output
unsubstituted_count=$(grep -o '@@[A-Z_][A-Z_]*@@' "$GENERATED_SCRIPT" | wc -l | tr -d ' ')
check "no unsubstituted placeholders (@@VAR@@ patterns)" "0" "$unsubstituted_count"

# ── Test 3: Bash syntax validation ────────────────────────────────────────────
# Use bash -n to check syntax without executing
bash_syntax_ok="pass"
if ! bash -n "$GENERATED_SCRIPT" 2>/dev/null; then
  bash_syntax_ok="fail"
fi
check "generated script is valid bash syntax" "pass" "$bash_syntax_ok"

# ── Test 4: All substituted values appear in output ──────────────────────────
# These are the five sed substitutions from build-llmrun:
# DATE, PROJECT, ADAPTERS, LMS_URL, LMS_KEY

# DATE: check that today's date appears somewhere
date_today=$(date '+%Y-%m-%d')
date_in_output=$(grep -c "$date_today" "$GENERATED_SCRIPT" || echo 0)
check "generated date ($date_today) appears in output" "1" "$([ "$date_in_output" -gt 0 ] && echo 1 || echo 0)"

# PROJECT: check that $HERE appears in the output
project_in_output=$(grep -c "$HERE" "$GENERATED_SCRIPT" || echo 0)
check "project path ($HERE) appears in output" "1" "$([ "$project_in_output" -gt 0 ] && echo 1 || echo 0)"

# ADAPTERS: check that the adapters path appears
adapters_path="$HERE/adapters"
adapters_in_output=$(grep -c "$adapters_path" "$GENERATED_SCRIPT" || echo 0)
check "adapters path ($adapters_path) appears in output" "1" "$([ "$adapters_in_output" -gt 0 ] && echo 1 || echo 0)"

# LMS_URL: check that the LMS URL appears (must not be empty)
if [ -z "$LMS_BASE_URL" ]; then
  printf '%s\n' "${C_RED}[FAIL]${C_RST} LMS_BASE_URL not set in config.sh"
  fail=$((fail+1))
else
  lms_url_in_output=$(grep -c "$LMS_BASE_URL" "$GENERATED_SCRIPT" || echo 0)
  check "LMS_BASE_URL ($LMS_BASE_URL) appears in output" "1" "$([ "$lms_url_in_output" -gt 0 ] && echo 1 || echo 0)"
fi

# LMS_KEY: check that the LMS key appears (must not be empty)
if [ -z "$LMS_API_KEY" ]; then
  printf '%s\n' "${C_RED}[FAIL]${C_RST} LMS_API_KEY not set in config.sh"
  fail=$((fail+1))
else
  lms_key_in_output=$(grep -c "$LMS_API_KEY" "$GENERATED_SCRIPT" || echo 0)
  check "LMS_API_KEY ($LMS_API_KEY) appears in output" "1" "$([ "$lms_key_in_output" -gt 0 ] && echo 1 || echo 0)"
fi

# ── Test 5: ADAPTERS directory exists ─────────────────────────────────────────
adapters_dir_exists="fail"
if [ -d "$HERE/adapters" ]; then
  adapters_dir_exists="pass"
fi
check "adapters directory exists ($HERE/adapters)" "pass" "$adapters_dir_exists"

# ── Test 6: Required env vars are non-empty ───────────────────────────────────
# These must be set by config.sh for build-llmrun to work
lms_url_status="pass"
[ -z "$LMS_BASE_URL" ] && lms_url_status="fail"
check "LMS_BASE_URL is non-empty" "pass" "$lms_url_status"

lms_key_status="pass"
[ -z "$LMS_API_KEY" ] && lms_key_status="fail"
check "LMS_API_KEY is non-empty" "pass" "$lms_key_status"

# ── Summary ───────────────────────────────────────────────────────────────────
total=$((pass + fail))
if [ "$fail" = 0 ]; then
  printf '\n%s\n' "${C_GRN}all $pass passed${C_RST}"
  exit 0
else
  printf '\n%s\n' "${C_RED}$pass passed, $fail failed${C_RST}"
  exit 1
fi
