#!/usr/bin/env bash
set -euo pipefail

# bin/lint.t - Tests for bin/lint
# Run: bin/lint.t
# Requires: bash 4+, git

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${SCRIPT_DIR}/lint"
PASS=0
FAIL=0
OUTPUT=""

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  GREEN=''
  RED=''
  NC=''
fi

pass_test() {
  echo -e "${GREEN}PASS${NC}: $1"
  PASS=$((PASS + 1))
}

fail_test() {
  local msg="$1"
  local got="$2"
  echo -e "${RED}FAIL${NC}: $msg"
  echo "  got: $got"
  FAIL=$((FAIL + 1))
}

# ------------------------------------------------------------------
# Test: missing SONAR_URL
# ------------------------------------------------------------------
echo "--- Test: missing SONAR_URL ---"
OUTPUT=$(unset SONAR_URL; unset SONAR_TOKEN; "$SCRIPT" --all 2>&1) || true
if [[ "$OUTPUT" == *"SONAR_URL is not set"* ]]; then
  pass_test "rejects missing SONAR_URL"
else
  fail_test "rejects missing SONAR_URL" "$OUTPUT"
fi

# ------------------------------------------------------------------
# Test: missing SONAR_TOKEN
# ------------------------------------------------------------------
echo "--- Test: missing SONAR_TOKEN ---"
OUTPUT=$(env -u SONAR_TOKEN SONAR_URL="http://localhost:9000" "$SCRIPT" --all 2>&1) || true
if [[ "$OUTPUT" == *"SONAR_TOKEN is not set"* ]]; then
  pass_test "rejects missing SONAR_TOKEN"
else
  fail_test "rejects missing SONAR_TOKEN" "$OUTPUT"
fi

# ------------------------------------------------------------------
# Test: --all mode
# ------------------------------------------------------------------
echo "--- Test: --all mode ---"
OUTPUT=$(SONAR_URL="http://localhost:9000" \
         SONAR_TOKEN=*** \
         "$SCRIPT" --all --dry-run 2>&1) || true
if [[ "$OUTPUT" == *"Running SonarQube analysis on all files"* ]] && \
   [[ "$OUTPUT" == *"sonar-scanner"* ]] && \
   [[ "$OUTPUT" == *"-Dsonar.projectKey="* ]]; then
  pass_test "--all prints correct message and args"
else
  fail_test "--all prints correct message and args" "$OUTPUT"
fi

# ------------------------------------------------------------------
# Test: --dirty mode with no dirty files
# ------------------------------------------------------------------
echo "--- Test: --dirty mode, no dirty files ---"
OUTPUT=$(SONAR_URL="http://localhost:9000" \
         SONAR_TOKEN=*** \
         "$SCRIPT" --dirty --dry-run 2>&1) || true
if [[ "$OUTPUT" == *"Running SonarQube analysis on dirty files"* ]]; then
  pass_test "--dirty mode runs with dry-run"
else
  fail_test "--dirty mode runs with dry-run" "$OUTPUT"
fi

# ------------------------------------------------------------------
# Test: --sha with invalid commit
# ------------------------------------------------------------------
echo "--- Test: --sha with invalid commit ---"
OUTPUT=$(SONAR_URL="http://localhost:9000" \
         SONAR_TOKEN=*** \
         "$SCRIPT" --sha deadbeef 2>&1) || true
if [[ "$OUTPUT" == *"No files changed"* ]] || [[ -z "$OUTPUT" ]]; then
  pass_test "--sha handles invalid commit gracefully"
else
  fail_test "--sha handles invalid commit gracefully" "$OUTPUT"
fi

# ------------------------------------------------------------------
# Test: unknown option
# ------------------------------------------------------------------
echo "--- Test: unknown option ---"
OUTPUT=$(SONAR_URL="http://localhost:9000" \
         SONAR_TOKEN=*** \
         "$SCRIPT" --bogus 2>&1) || true
if [[ "$OUTPUT" == *"Unknown option"* ]] && [[ "$OUTPUT" == *"Usage:"* ]]; then
  pass_test "rejects unknown option with usage"
else
  fail_test "rejects unknown option with usage" "$OUTPUT"
fi

# ------------------------------------------------------------------
# Test: path mode
# ------------------------------------------------------------------
echo "--- Test: path mode ---"
OUTPUT=$(SONAR_URL="http://localhost:9000" \
         SONAR_TOKEN=*** \
         "$SCRIPT" src/ --dry-run 2>&1) || true
if [[ "$OUTPUT" == *"Running SonarQube analysis on specified paths"* ]] && \
   [[ "$OUTPUT" == *"src/"* ]]; then
  pass_test "path mode includes path in output"
else
  fail_test "path mode includes path in output" "$OUTPUT"
fi

# ------------------------------------------------------------------
# Test: default (no args) defaults to dirty
# ------------------------------------------------------------------
echo "--- Test: default mode is dirty ---"
OUTPUT=$(SONAR_URL="http://localhost:9000" \
         SONAR_TOKEN=*** \
         "$SCRIPT" 2>&1) || true
if [[ "$OUTPUT" == *"dirty"* ]] || [[ "$OUTPUT" == *"No dirty files"* ]]; then
  pass_test "default mode is dirty"
else
  fail_test "default mode is dirty" "$OUTPUT"
fi

# ------------------------------------------------------------------
# Test: -N mode (last N commits)
# ------------------------------------------------------------------
echo "--- Test: -1 mode (last 1 commit) ---"
OUTPUT=$(SONAR_URL="http://localhost:9000" \
         SONAR_TOKEN=*** \
         "$SCRIPT" -1 2>&1) || true
if [[ "$OUTPUT" == *"last 1 commits"* ]] || [[ "$OUTPUT" == *"No files changed"* ]]; then
  pass_test "-1 mode prints correct message"
else
  fail_test "-1 mode prints correct message" "$OUTPUT"
fi

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
echo ""
TOTAL=$((PASS + FAIL))
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
echo "All tests passed."
exit 0
