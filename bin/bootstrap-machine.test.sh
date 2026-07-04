#!/usr/bin/env bash
# bin/bootstrap-machine.test.sh — tests for bin/bootstrap-machine
set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/lib/common.sh"

TMP="$(mktemp -d)"
trap "rm -rf '$TMP'" EXIT

# Test 1: --help shows usage
echo "[TEST] --help"
if "$HERE/bin/bootstrap-machine" --help | grep -q "propose or apply"; then
  echo "[PASS] --help output shows description"
else
  echo "[FAIL] --help output missing"
  exit 1
fi

# Test 2: profile.json is valid JSON
echo "[TEST] profile.json is valid JSON"
if jq empty "$HERE/profile.json" 2>/dev/null; then
  echo "[PASS] profile.json is valid JSON"
else
  echo "[FAIL] profile.json is not valid JSON"
  exit 1
fi

# Test 3: All tiers in profile.json have required fields
echo "[TEST] profile.json tiers have required fields"
for tier in 24 32 48 64 128; do
  if jq --arg t "$tier" '.tiers[$t] | has("primary") and (.primary | has("model") and has("adapters") and has("context") and has("parallel"))' "$HERE/profile.json" | grep -q "true"; then
    echo "  ✓ tier $tier has all required fields"
  else
    echo "[FAIL] tier $tier missing required fields"
    exit 1
  fi
done
echo "[PASS] all tiers have required fields"

# Test 4: Verify tier 32 config
echo "[TEST] tier 32 has benchmarked=true"
if jq --arg t "32" '.tiers[$t].benchmarked' "$HERE/profile.json" | grep -q "true"; then
  echo "[PASS] tier 32 marked as benchmarked"
else
  echo "[FAIL] tier 32 should be benchmarked"
  exit 1
fi

# Test 5: Verify tier 128 has primary and secondary
echo "[TEST] tier 128 primary/secondary config"
has_primary=$(jq '.tiers["128"] | has("primary")' "$HERE/profile.json")
has_secondary=$(jq '.tiers["128"] | has("secondary")' "$HERE/profile.json")
if [ "$has_primary" = "true" ] && [ "$has_secondary" = "true" ]; then
  echo "[PASS] tier 128 has primary and secondary"
else
  echo "[FAIL] tier 128 missing primary or secondary"
  exit 1
fi

# Test 6: Verify models are present in 32GB tier
echo "[TEST] tier 32 includes primary model"
if jq '.tiers["32"].primary.model' "$HERE/profile.json" | grep -q "qwen"; then
  echo "[PASS] tier 32 has primary model"
else
  echo "[FAIL] tier 32 missing primary model"
  exit 1
fi

# Test 7: tier 24 is not benchmarked
echo "[TEST] tier 24 is placeholder"
if jq '.tiers["24"].benchmarked' "$HERE/profile.json" | grep -q "false"; then
  echo "[PASS] tier 24 marked as placeholder"
else
  echo "[FAIL] tier 24 should be placeholder"
  exit 1
fi

# Test 8: Verify dry-run shows BENCH_CONTEXT for tier 32
echo "[TEST] dry-run with --tier 32 shows config"
dry_run_out=$("$HERE/bin/bootstrap-machine" --tier 32 2>&1)
if echo "$dry_run_out" | grep -q "32768"; then
  echo "[PASS] dry-run shows correct config for tier 32"
else
  echo "[FAIL] dry-run output incorrect"
  exit 1
fi

# Test 9: Verify dry-run shows DEFAULT_ADAPTERS
echo "[TEST] dry-run shows adapter list"
dry_run_128=$("$HERE/bin/bootstrap-machine" --tier 128 2>&1)
if echo "$dry_run_128" | grep -q "DEFAULT_ADAPTERS"; then
  echo "[PASS] dry-run includes DEFAULT_ADAPTERS"
else
  echo "[FAIL] dry-run missing DEFAULT_ADAPTERS"
  exit 1
fi

# Test 10: Verify profile.json can be parsed per tier for all tiers
echo "[TEST] all tiers parse correctly"
for tier in 24 32 48 64 128; do
  primary=$(jq --arg t "$tier" '.tiers[$t].primary.model' "$HERE/profile.json" 2>/dev/null)
  if [ -z "$primary" ] || [ "$primary" = "null" ]; then
    echo "[FAIL] tier $tier primary model failed to parse"
    exit 1
  fi
done
echo "[PASS] all tiers parse correctly"

echo ""
echo "════════════════════════════════════════════════════"
echo "✓ all tests passed"
echo "════════════════════════════════════════════════════"
