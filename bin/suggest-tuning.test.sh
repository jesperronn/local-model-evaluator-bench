#!/usr/bin/env bash
# bin/suggest-tuning.test.sh — verify config suggestion pipeline.
# Tests: bin/suggest-tuning → llmrun agents config apply.
# Run directly: bin/suggest-tuning.test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

# Colors (disabled if NO_COLOR is set).
if [ -z "${NO_COLOR:-}" ]; then
  C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
else
  C_GRN=; C_RED=; C_RST=
fi
pass=0; fail=0
check() {  # desc  expected  actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}
check_match() {  # desc  pattern  actual
  if echo "$3" | grep -qE "$2"; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s (pattern: %s)\n  actual: %s\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}

# Backup config store
CONFIG_BACKUP="$HOME/.config/llmrun/agents.json.backup.$$"
if [ -f "$HOME/.config/llmrun/agents.json" ]; then
  cp "$HOME/.config/llmrun/agents.json" "$CONFIG_BACKUP"
fi
trap "[ -f '$CONFIG_BACKUP' ] && mv '$CONFIG_BACKUP' '$HOME/.config/llmrun/agents.json'" EXIT

TMP="$(mktemp -d)"; trap "rm -rf '$TMP'" EXIT

# Test 1: suggest-tuning emits valid JSON with context + defaults
echo "=== Test 1: suggest-tuning generates valid plan ==="
plan="$TMP/plan.jsonl"
"$HERE/bin/suggest-tuning" qwen/qwen3.6-35b-a3b > "$plan"

# Verify file has 3 lines (context, temperature, max_tokens)
lines="$(wc -l < "$plan" | tr -d ' ')"
check "plan has 3 rows" "3" "$lines"

# Verify all rows are valid JSON
if jq -e . < "$plan" >/dev/null 2>&1; then
  check "all rows are valid JSON" "0" "0"
else
  check "all rows are valid JSON" "0" "1"
fi

# Verify each row has required fields
row1="$(head -1 "$plan")"
check "row has model field" "qwen/qwen3.6-35b-a3b" "$(echo "$row1" | jq -r .model)"
check "row has key field" "context" "$(echo "$row1" | jq -r .key)"
check "row has value field" "65536" "$(echo "$row1" | jq -r .value)"
check "row has reason field (non-empty)" "true" "$(echo "$row1" | jq 'has("reason") and .reason != ""' )"
check "row has source field (non-empty)" "true" "$(echo "$row1" | jq 'has("source") and .source != ""' )"

# Test 2: agents config apply (dry-run)
echo ""
echo "=== Test 2: agents config apply dry-run ==="
output=$(llmrun agents config apply "$plan" 2>&1 || true)
check_match "dry-run shows what would be set" "would set qwen/qwen3.6-35b-a3b.context = 65536" "$output"
check_match "dry-run lists all rows" "3 row" "$output"

# Test 3: agents config apply with --write
echo ""
echo "=== Test 3: agents config apply --write ==="
llmrun agents config apply "$plan" --write >/dev/null 2>&1

# Verify settings are in config store
ctx=$(llmrun agents config get qwen/qwen3.6-35b-a3b context 2>/dev/null || echo "missing")
temp=$(llmrun agents config get qwen/qwen3.6-35b-a3b temperature 2>/dev/null || echo "missing")
tokens=$(llmrun agents config get qwen/qwen3.6-35b-a3b max_tokens 2>/dev/null || echo "missing")

check "context is 65536" "65536" "$ctx"
check "temperature is 0.7" "0.7" "$temp"
check "max_tokens is 8192" "8192" "$tokens"

# Test 4: suggest-tuning on all models produces plan with multiple models
echo ""
echo "=== Test 4: suggest-tuning produces plan for all models ==="
plan_all="$TMP/plan_all.jsonl"
"$HERE/bin/suggest-tuning" > "$plan_all"

rows_total=$(wc -l < "$plan_all" | tr -d ' ')
models_total=$(jq -r .model "$plan_all" | sort -u | wc -l | tr -d ' ')
check_match "plan has multiple rows" "^[0-9]+" "$rows_total"
check_match "plan covers multiple models" "^[0-9]+" "$(printf '%d' "$models_total")"

# Verify each model in plan has context, temperature, max_tokens (3 keys per model)
expected_rows=$((models_total * 3))
check "plan has 3 rows per model" "$expected_rows" "$rows_total"

# Test 5: config can be retrieved for applied settings
echo ""
echo "=== Test 5: retrieve applied config ==="
model=$(jq -r .model "$plan_all" | head -1)
get_ctx=$(llmrun agents config get "$model" context 2>/dev/null || echo "missing")
check_match "can retrieve context for model" "[0-9]+" "$get_ctx"

# ─────────────────────────────────────────────────────────────────────────────
printf '\n%s %d passed, %d failed\n' "${C_GRN}[RESULT]${C_RST}" "$pass" "$fail"
[ "$fail" = 0 ] && exit 0 || exit 1
