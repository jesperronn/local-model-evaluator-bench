#!/usr/bin/env bash
# bin/build-llmrun.test.sh — verify build-llmrun's output without loading models.
# Tests that the generated llmrun script is syntactically valid, has no unsubstituted
# template variables, contains all required config values, the adapter directory
# exists, and --dry-run resolves the correct adapter file for both a
# runtime-suffixed and a unified adapter (and fails for an unknown agent) —
# all without exec'ing an adapter or loading a model.
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

# OMLX_URL/OMLX_KEY: check that the oMLX URL/key appear (must not be empty)
if [ -z "$OMLX_BASE_URL" ]; then
  printf '%s\n' "${C_RED}[FAIL]${C_RST} OMLX_BASE_URL not set in config.sh"
  fail=$((fail+1))
else
  omlx_url_in_output=$(grep -c "$OMLX_BASE_URL" "$GENERATED_SCRIPT" || echo 0)
  check "OMLX_BASE_URL ($OMLX_BASE_URL) appears in output" "1" "$([ "$omlx_url_in_output" -gt 0 ] && echo 1 || echo 0)"
fi

if [ -z "$OMLX_API_KEY" ]; then
  printf '%s\n' "${C_RED}[FAIL]${C_RST} OMLX_API_KEY not set in config.sh"
  fail=$((fail+1))
else
  omlx_key_in_output=$(grep -c "$OMLX_API_KEY" "$GENERATED_SCRIPT" || echo 0)
  check "OMLX_API_KEY ($OMLX_API_KEY) appears in output" "1" "$([ "$omlx_key_in_output" -gt 0 ] && echo 1 || echo 0)"
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

omlx_url_status="pass"
[ -z "$OMLX_BASE_URL" ] && omlx_url_status="fail"
check "OMLX_BASE_URL is non-empty" "pass" "$omlx_url_status"

omlx_key_status="pass"
[ -z "$OMLX_API_KEY" ] && omlx_key_status="fail"
check "OMLX_API_KEY is non-empty" "pass" "$omlx_key_status"

# ── Test 7: --dry-run resolves adapter/runtime/model without exec'ing ────────
# Pick a real adapter from adapters/ so this stays correct as adapters are
# added/removed. The new llmrun uses unified adapters and extracts runtime from
# the model format (e.g., "lms/test-model" extracts lms as the runtime).
# Mirror what proxy model discovery does: use "runtime/model" format.
unified_adapter="$(ls "$HERE/adapters"/*.sh 2>/dev/null | grep -vE 'model-metadata.json$' | head -1)"
if [ -n "$unified_adapter" ]; then
  unified_tool="$(basename "$unified_adapter" .sh)"
  # Test with lms runtime via proxy format
  dr_out="$("$GENERATED_SCRIPT" --agent "$unified_tool" --model lms/test-model --dry-run 2>&1)"
  check "dry-run resolves unified adapter ($unified_tool.sh)" \
    "$unified_adapter" "$(printf '%s\n' "$dr_out" | sed -n 's/^adapter=//p')"
  check "dry-run reports agent=$unified_tool" "agent=$unified_tool" "$(printf '%s\n' "$dr_out" | grep '^agent=')"
  check "dry-run extracts runtime=lms from model format" "runtime=lms" "$(printf '%s\n' "$dr_out" | grep '^runtime=')"
  check "dry-run extracts model=test-model from model format" "model=test-model" "$(printf '%s\n' "$dr_out" | grep '^model=')"
  check "dry-run does not print launching (never execs)" "0" "$(printf '%s\n' "$dr_out" | grep -c 'launching')"
else
  printf '%s\n' "${C_YEL}[SKIP]${C_RST} no unified adapter found — skipping dry-run check"
fi

# Test with ollama runtime via proxy format
if [ -n "$unified_adapter" ]; then
  unified_tool="$(basename "$unified_adapter" .sh)"
  dr_out2="$("$GENERATED_SCRIPT" --agent "$unified_tool" --model ollama/test-model --dry-run 2>&1)"
  check "dry-run extracts runtime=ollama from model format" "runtime=ollama" "$(printf '%s\n' "$dr_out2" | grep '^runtime=')"
else
  printf '%s\n' "${C_YEL}[SKIP]${C_RST} no unified adapter found — skipping ollama dry-run check"
fi

# Unknown agent must fail (non-zero exit) without ever reaching exec — the
# whole point of --dry-run is to catch a bad resolution before it costs a
# model load, so this must not silently succeed.
dr_bad_exit=0
"$GENERATED_SCRIPT" --agent __nonexistent_agent__ --model lms/test-model --dry-run >/dev/null 2>&1 || dr_bad_exit=$?
check "dry-run exits non-zero for an unknown agent" "1" "$([ "$dr_bad_exit" -ne 0 ] && echo 1 || echo 0)"

# ── Summary ───────────────────────────────────────────────────────────────────
total=$((pass + fail))
if [ "$fail" = 0 ]; then
  printf '\n%s\n' "${C_GRN}all $pass passed${C_RST}"
  exit 0
else
  printf '\n%s\n' "${C_RED}$pass passed, $fail failed${C_RST}"
  exit 1
fi
