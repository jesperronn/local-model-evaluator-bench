#!/usr/bin/env bash
# lib/common.test.sh — verify filter_broken_adapters and related functions.
# Run directly: lib/common.test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/config.sh"
source "$HERE/lib/common.sh"

C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- setup: create test compat.json -----------------------------------------------
REPO_ROOT="$TMP"
export REPO_ROOT

cat > "$TMP/compat.json" << 'EOF'
{
  "broken-tool:test-model:lms": {
    "adapter": "broken-tool",
    "model": "test-model",
    "runtime": "lms",
    "status": "open",
    "symptom": "connection refused — tool not installed"
  },
  "good-tool:test-model:lms": {
    "adapter": "good-tool",
    "model": "test-model",
    "runtime": "lms",
    "status": "resolved"
  },
  "partial-tool:test-model:lms": {
    "adapter": "partial-tool",
    "model": "test-model",
    "runtime": "lms",
    "status": "open",
    "symptom": "model refusal"
  },
  "unknown-tool:test-model:lms": {
    "adapter": "unknown-tool",
    "model": "test-model",
    "runtime": "lms",
    "status": "none"
  }
}
EOF

# --- test: filter_broken_adapters -----------------------------------------------

# Test 1: Filter removes adapters with status=open
result=$(filter_broken_adapters "broken-tool,good-tool" "test-model" "lms")
check "filter removes broken, keeps good" "good-tool" "$result"

# Test 2: Filter preserves unknown adapters (status=none)
result=$(filter_broken_adapters "good-tool,unknown-adapter" "test-model" "lms")
check "filter preserves unknown adapters" "good-tool,unknown-adapter" "$result"

# Test 3: Filter removes multiple broken adapters
result=$(filter_broken_adapters "broken-tool,good-tool,partial-tool" "test-model" "lms")
check "filter removes multiple broken" "good-tool" "$result"

# Test 4: Filter with no broken adapters
result=$(filter_broken_adapters "good-tool,unknown-adapter" "test-model" "lms")
check "filter with no broken returns all" "good-tool,unknown-adapter" "$result"

# Test 5: Filter with all broken adapters returns empty
result=$(filter_broken_adapters "broken-tool,partial-tool" "test-model" "lms")
check "filter with all broken returns empty" "" "$result"

# Test 6: Filter with empty input
result=$(filter_broken_adapters "" "test-model" "lms")
check "filter with empty input returns empty" "" "$result"

# Test 7: Filter with non-existent model (all adapters unknown, not in compat)
result=$(filter_broken_adapters "aider,cline" "unknown-model" "lms")
check "filter unknown model includes all" "aider,cline" "$result"

# --- test: no compat.json file ---------------------------------------------------

# Test 8: Filter returns original list when compat.json missing
rm "$TMP/compat.json"
result=$(filter_broken_adapters "broken-tool,good-tool" "test-model" "lms")
check "filter missing compat.json returns original" "broken-tool,good-tool" "$result"

# --- test: warn_filtered_adapters -----------------------------------------------

# Restore compat.json for warning tests
cat > "$TMP/compat.json" << 'EOF'
{
  "broken-tool:test-model:lms": {
    "adapter": "broken-tool",
    "model": "test-model",
    "runtime": "lms",
    "status": "open",
    "symptom": "connection refused — tool not installed"
  },
  "good-tool:test-model:lms": {
    "adapter": "good-tool",
    "model": "test-model",
    "runtime": "lms",
    "status": "resolved"
  }
}
EOF

# Test 9: warn_filtered_adapters detects filtered adapters
output=$(warn_filtered_adapters "broken-tool,good-tool" "good-tool" "test-model" "lms" 2>&1)
if echo "$output" | grep -q "skipping 1 adapter"; then
  printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "warn detects 1 filtered adapter"
  pass=$((pass+1))
else
  printf '%s %s\n' "${C_RED}[FAIL]${C_RST}" "warn should detect 1 filtered adapter"
  echo "  output: $output"
  fail=$((fail+1))
fi

# Test 10: warn_filtered_adapters shows symptom
output=$(warn_filtered_adapters "broken-tool,good-tool" "good-tool" "test-model" "lms" 2>&1)
if echo "$output" | grep -q "connection refused"; then
  printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "warn includes symptom"
  pass=$((pass+1))
else
  printf '%s %s\n' "${C_RED}[FAIL]${C_RST}" "warn should include symptom"
  echo "  output: $output"
  fail=$((fail+1))
fi

# Test 11: warn_filtered_adapters silent when nothing filtered
output=$(warn_filtered_adapters "good-tool" "good-tool" "test-model" "lms" 2>&1)
if [ -z "$output" ]; then
  printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "warn silent when nothing filtered"
  pass=$((pass+1))
else
  printf '%s %s\n' "${C_RED}[FAIL]${C_RST}" "warn should be silent when nothing filtered"
  fail=$((fail+1))
fi

# --- summary ---
echo
if [ "$fail" -eq 0 ]; then
  echo "${C_GRN}all $pass passed${C_RST}"
  exit 0
else
  echo "${C_RED}$fail failed${C_RST}, $pass passed"
  exit 1
fi
