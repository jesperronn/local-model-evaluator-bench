#!/usr/bin/env bash
# test-guardrails.sh — verify guardrails runtime control functionality
# Run after: bin/litellm-proxy start
#
# Tests:
#   1. Guardrails status command (check current state)
#   2. Guardrails on command (enable guardrails dynamically)
#   3. Guardrails off command (disable guardrails dynamically)
#   4. Guardrails config command (show full configuration)
#   5. Status output includes guardrails line
#   6. Verify proxy is still running after each command

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/config.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

test_result() {
  local name="$1"
  local result="$2"

  if [ "$result" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} $name"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $name"
    ((TESTS_FAILED++))
  fi
}

echo "Guardrails Runtime Control Tests"
echo "=================================="
echo ""

# Test 1: Check if proxy is running
echo "Checking proxy status..."
if bin/litellm-proxy status | grep -q "litellm proxy: up"; then
  echo -e "${GREEN}✓${NC} Proxy is running"
else
  echo -e "${RED}✗${NC} Proxy is not running. Start it with: bin/litellm-proxy start"
  exit 1
fi

echo ""
echo "Test 1: Guardrails status command"
echo "-----------------------------------"
if output=$(bin/litellm-proxy guardrails status 2>&1); then
  echo "Output: $output"
  if echo "$output" | grep -qE "guardrails: (on|off)"; then
    test_result "guardrails status command" 0
  else
    test_result "guardrails status command" 1
  fi
else
  test_result "guardrails status command" 1
fi

echo ""
echo "Test 2: Guardrails config command"
echo "----------------------------------"
if output=$(bin/litellm-proxy guardrails config 2>&1); then
  echo "Config output (first 5 lines):"
  echo "$output" | head -5
  if echo "$output" | jq . >/dev/null 2>&1; then
    test_result "guardrails config command returns valid JSON" 0
  else
    test_result "guardrails config command returns valid JSON" 1
  fi
else
  test_result "guardrails config command" 1
fi

echo ""
echo "Test 3: Guardrails on command"
echo "-----------------------------"
if output=$(bin/litellm-proxy guardrails on 2>&1); then
  echo "Output: $output"
  if echo "$output" | grep -qE "guardrails: enabled"; then
    test_result "guardrails on command" 0
  else
    test_result "guardrails on command" 1
  fi
else
  test_result "guardrails on command" 1
fi

# Verify proxy still running
if bin/litellm-proxy status | grep -q "litellm proxy: up"; then
  test_result "Proxy running after guardrails on" 0
else
  test_result "Proxy running after guardrails on" 1
fi

echo ""
echo "Test 4: Verify guardrails status is on"
echo "--------------------------------------"
if output=$(bin/litellm-proxy guardrails status 2>&1); then
  echo "Output: $output"
  if echo "$output" | grep -qE "guardrails: on"; then
    test_result "guardrails status shows on" 0
  else
    test_result "guardrails status shows on" 1
  fi
else
  test_result "guardrails status shows on" 1
fi

echo ""
echo "Test 5: Guardrails off command"
echo "-----------------------------"
if output=$(bin/litellm-proxy guardrails off 2>&1); then
  echo "Output: $output"
  if echo "$output" | grep -qE "guardrails: disabled"; then
    test_result "guardrails off command" 0
  else
    test_result "guardrails off command" 1
  fi
else
  test_result "guardrails off command" 1
fi

# Verify proxy still running
if bin/litellm-proxy status | grep -q "litellm proxy: up"; then
  test_result "Proxy running after guardrails off" 0
else
  test_result "Proxy running after guardrails off" 1
fi

echo ""
echo "Test 6: Verify guardrails status is off"
echo "--------------------------------------"
if output=$(bin/litellm-proxy guardrails status 2>&1); then
  echo "Output: $output"
  if echo "$output" | grep -qE "guardrails: off"; then
    test_result "guardrails status shows off" 0
  else
    test_result "guardrails status shows off" 1
  fi
else
  test_result "guardrails status shows off" 1
fi

echo ""
echo "Test 7: Status output includes guardrails line"
echo "---------------------------------------------"
if output=$(bin/litellm-proxy status 2>&1); then
  echo "Status output:"
  echo "$output"
  if echo "$output" | grep -qE "guardrails:"; then
    test_result "Status includes guardrails line" 0
  else
    test_result "Status includes guardrails line" 1
  fi
else
  test_result "Status includes guardrails line" 1
fi

echo ""
echo "Test 8: Verify proxy reachable after all commands"
echo "------------------------------------------------"
if bin/litellm-proxy status | grep -q "litellm proxy: up"; then
  test_result "Proxy responsive after all tests" 0
else
  test_result "Proxy responsive after all tests" 1
fi

echo ""
echo "Test Summary"
echo "============"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed. Check the output above.${NC}"
  exit 1
fi
