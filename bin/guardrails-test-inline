#!/usr/bin/env bash
# test-guardrails-inline.sh — inline validation of guardrails script structure
# This tests the script functions without needing a running proxy

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Validating guardrails script functions..."
echo ""

# Test 1: Verify _get_guardrails_status function exists and is callable
echo "Test 1: Check if _get_guardrails_status function is defined"
if grep -q "_get_guardrails_status()" "$HERE/bin/litellm-proxy"; then
  echo "✓ _get_guardrails_status function is defined"
else
  echo "✗ _get_guardrails_status function is NOT defined"
  exit 1
fi

# Test 2: Verify cmd_guardrails function exists
echo "Test 2: Check if cmd_guardrails function is defined"
if grep -q "cmd_guardrails()" "$HERE/bin/litellm-proxy"; then
  echo "✓ cmd_guardrails function is defined"
else
  echo "✗ cmd_guardrails function is NOT defined"
  exit 1
fi

# Test 3: Verify guardrails subcommand routing
echo "Test 3: Check if guardrails subcommand is routed correctly"
if grep -q "guardrails).*cmd_guardrails" "$HERE/bin/litellm-proxy"; then
  echo "✓ guardrails subcommand routing exists"
else
  echo "✗ guardrails subcommand routing is missing"
  exit 1
fi

# Test 4: Verify all subcommands are handled
echo "Test 4: Check if all guardrails subcommands are implemented"
subcommands=("on" "off" "status" "config")
for cmd in "${subcommands[@]}"; do
  if grep -q "\"$cmd\")" "$HERE/bin/litellm-proxy" | grep -q "cmd_guardrails" || grep -A 50 "cmd_guardrails()" "$HERE/bin/litellm-proxy" | grep -q "$cmd)"; then
    echo "✓ guardrails $cmd subcommand exists"
  else
    echo "✗ guardrails $cmd subcommand is missing"
    exit 1
  fi
done

# Test 5: Verify status command includes guardrails line
echo "Test 5: Check if cmd_status includes guardrails check"
if grep -q "_get_guardrails_status" "$HERE/bin/litellm-proxy" | grep -B 5 -A 5 "cmd_status"; then
  if grep -A 20 "cmd_status()" "$HERE/bin/litellm-proxy" | grep -q "guardrails"; then
    echo "✓ cmd_status includes guardrails line"
  else
    echo "✗ cmd_status does NOT include guardrails line"
    exit 1
  fi
fi

# Test 6: Verify jq filters for guardrails extraction
echo "Test 6: Check if guardrails state parsing logic is present"
if grep -q ".guardrails.*default_on" "$HERE/bin/litellm-proxy"; then
  echo "✓ Guardrails state extraction logic exists"
else
  echo "✗ Guardrails state extraction logic is missing"
  exit 1
fi

# Test 7: Verify error handling for proxy not running
echo "Test 7: Check if error handling for proxy down is present"
if grep -q "check proxy is running" "$HERE/bin/litellm-proxy"; then
  echo "✓ Error handling for proxy down is present"
else
  echo "✗ Error handling for proxy down is missing"
  exit 1
fi

# Test 8: Verify curl calls use /admin/config endpoint
echo "Test 8: Check if /admin/config endpoint is used"
if grep -q "/admin/config" "$HERE/bin/litellm-proxy"; then
  echo "✓ /admin/config endpoint is used"
else
  echo "✗ /admin/config endpoint is NOT used"
  exit 1
fi

# Test 9: Verify POST request for updating config
echo "Test 9: Check if POST updates are implemented"
if grep -q "curl.*-X POST.*admin/config" "$HERE/bin/litellm-proxy"; then
  echo "✓ POST updates to config are implemented"
else
  echo "✗ POST updates to config are NOT implemented"
  exit 1
fi

# Test 10: Verify formatting of guardrails status output
echo "Test 10: Check if guardrails status output formatting is correct"
if grep -q "guardrails: on (presidio," "$HERE/bin/litellm-proxy" || grep -q "on (presidio" "$HERE/bin/litellm-proxy"; then
  echo "✓ Guardrails status output format is correct"
else
  echo "✗ Guardrails status output format may be incorrect"
  exit 1
fi

echo ""
echo "All inline validation tests passed!"
echo ""
echo "To run full integration tests (requires running proxy):"
echo "  bin/litellm-proxy start"
echo "  ./test-guardrails.sh"
