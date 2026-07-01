#!/usr/bin/env bash
# bin/prune.test.sh — verify bin/prune's fzf matching, dry-run, and deletion logic.
# Run directly: bin/prune.test.sh
#
# Creates a fully sandboxed environment with fake LM Studio index, mock lms/ollama/fzf,
# then drives bin/prune against it. Uses FZF_INPUT env var to simulate fzf multi-select.

set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"

C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
pass=0; fail=0

check() {  # desc  expected  actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}

check_contains() {  # desc  expected_substring  actual
  if echo "$3" | grep -qF "$2"; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected substring: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- build sandbox ------------------------------------------------------------
# IMPORTANT: bin/prune resolves its own repo root from $0's location
# ($(dirname "$0")/..), so we run a *copy* of the script from inside the
# sandbox repo tree. This test must never write config.sh/common.sh/models*
# fixtures onto the real repo files — a prior version of this test did just
# that (cat > "$HERE/config.sh" ...) with no restore-on-exit, which silently
# clobbered the real config.sh, lib/common.sh, and model lists in place.
SANDBOX="$TMP/sandbox"
REPO="$SANDBOX/repo"
mkdir -p "$SANDBOX/.lmstudio/.internal" \
         "$SANDBOX/.lmstudio/models/lmstudio-community" \
         "$SANDBOX/MOCK_LMS" \
         "$REPO/bin" \
         "$REPO/lib"

cp "$HERE/bin/prune" "$REPO/bin/prune"
PRUNE="$REPO/bin/prune"

# Minimal config.sh / common.sh (sandbox-only, never touches the real repo)
cat > "$REPO/config.sh" <<'EOF'
REPO_ROOT="$HERE"
ADAPTERS_DIR="$HERE/adapters"
CASES_DIR="$HERE/cases"
RESULTS_DIR="$HERE/results"
EOF
cat > "$REPO/lib/common.sh" <<'EOF'
die() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARNING: $*" >&2; }
read_list() { grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$1" 2>/dev/null || true; }
EOF

# Model lists (all referenced, so --unused shows nothing). glm-4.7-flash
# must be included too — it's one of the 3 fixture models in the lms index
# below, and Test 6 asserts "no unused models" before adding a genuine orphan.
cat > "$REPO/models.txt" <<'EOF'
google/gemma-4-26b-a4b
qwen/qwen3-coder-30b
zai-org/glm-4.7-flash
EOF
cat > "$REPO/models-ollama.txt" <<'EOF'
mistralai/devstral-small-2-2512
EOF
cat > "$REPO/models-mlx.txt" <<'EOF'
mlx-community/qwen3-32b
EOF
cat > "$REPO/models-aliases.conf" <<'EOF'
# model-aliases
gemma  google/gemma-4-26b-a4b
qwen3  qwen/qwen3-coder-30b
EOF

# --- fake LM Studio index with 3 controlled models ----------------------------
cat > "$SANDBOX/.lmstudio/.internal/model-index-cache.json" <<EOF
{
  "models": [
    {"autoIdentifiers":["google/gemma-4-26b-a4b"],"concreteModelDirAbsolutePath":"$SANDBOX/.lmstudio/models/lmstudio-community/google__gemma-4-26b-a4b","containingDirAbsolutePath":"$SANDBOX/.lmstudio/models/google/gemma-4-26b-a4b","sizeBytes":23424843776,"containingDirMtime":1700000000000},
    {"autoIdentifiers":["qwen/qwen3-coder-30b"],"concreteModelDirAbsolutePath":"$SANDBOX/.lmstudio/models/lmstudio-community/qwen__qwen3-coder-30b","containingDirAbsolutePath":"$SANDBOX/.lmstudio/models/qwen/qwen3-coder-30b","sizeBytes":18223050752,"containingDirMtime":1699000000000},
    {"autoIdentifiers":["zai-org/glm-4.7-flash"],"concreteModelDirAbsolutePath":"$SANDBOX/.lmstudio/models/lmstudio-community/zai__glm-4.7-flash","containingDirAbsolutePath":"$SANDBOX/.lmstudio/models/zai-org/glm-4.7-flash","sizeBytes":26100000000,"containingDirMtime":1698000000000}
  ]
}
EOF

# Create concrete model dirs so they exist on disk
for name in "google__gemma-4-26b-a4b" "qwen__qwen3-coder-30b" "zai__glm-4.7-flash"; do
  mkdir -p "$SANDBOX/.lmstudio/models/lmstudio-community/$name"
  echo "dummy" > "$SANDBOX/.lmstudio/models/lmstudio-community/$name/model.weights"
done

# --- mock commands -----------------------------------------------------------
cat > "$SANDBOX/MOCK_LMS/lms" <<'MOCKEOF'
#!/usr/bin/env bash
case "$1" in
  ps)
    if [[ "$*" == *"--json"* ]]; then
      echo '[{"modelKey":"google/gemma-4-26b-a4b","lastUsedTime":1700000000000},{"modelKey":"qwen/qwen3-coder-30b","lastUsedTime":1699000000000}]'
    else
      echo "google/gemma-4-26b-a4b loaded"
    fi
    ;;
  unload) exit 0 ;;
esac
MOCKEOF
chmod +x "$SANDBOX/MOCK_LMS/lms"

# Mock ollama (returns 1 model)
cat > "$SANDBOX/MOCK_LMS/ollama" <<'MOCKEOF'
#!/usr/bin/env bash
[ "$1" = "list" ] && printf 'NAME\t\t\t\tID\t\tSIZE\tMODIFIED\nmistralai/devstral-small-2-2512\tabc123\t15.2 GB\t2 weeks ago' && exit 0
[ "$1" = "rm" ] && exit 0
MOCKEOF
chmod +x "$SANDBOX/MOCK_LMS/ollama"

# Mock fzf — outputs FZF_INPUT if the caller set it (even to an empty string,
# which simulates ESC/no-selection), else passes through stdin unchanged.
# Must check "is set" (+set) rather than "is non-empty" (-n): FZF_INPUT=""
# means "user selected nothing," not "fall back to passthrough."
cat > "$SANDBOX/MOCK_LMS/fzf" <<'MOCKEOF'
#!/usr/bin/env bash
[ -n "${FZF_INPUT+set}" ] && echo "$FZF_INPUT" || cat
MOCKEOF
chmod +x "$SANDBOX/MOCK_LMS/fzf"

# Mock jq (needed by prune for lms unload)
cat > "$SANDBOX/MOCK_LMS/jq" <<'MOCKEOF'
#!/usr/bin/env bash
cat
MOCKEOF
chmod +x "$SANDBOX/MOCK_LMS/jq"

# Activate sandbox: PATH with mocks + HOME pointing to sandbox
export PATH="$SANDBOX/MOCK_LMS:$PATH"
export HOME="$SANDBOX"

# --- helper: run prune with env overrides ------------------------------------
# Must preserve SANDBOX_HOME/PATH across subprocesses.
# Writes to the global RUN_PRUNE_OUTPUT rather than returning via stdout.
# Deliberately NOT called as `output="$(run_prune)"` — that form forks a
# subshell for the command substitution, and this function's `unset` calls
# would then only clear the subshell's copy of the PRUNE_*/FZF_INPUT
# variables, leaving the real ones (set by the caller's assignment-only
# "VAR=x \\\noutput=..." lines, which persist in the *caller's* shell)
# leaked forward into later, unrelated test blocks. Calling this as a plain
# command keeps it in the caller's shell, so the unsets actually take effect
# where the leak originates. Call sites use `run_prune; output="$RUN_PRUNE_OUTPUT"`.
run_prune() {
  local runtime="${PRUNE_RUNTIME:-all}"
  local dry_run="${PRUNE_DRY_RUN:-false}"
  local interactive="${PRUNE_INTERACTIVE:-false}"
  local unused="${PRUNE_UNUSED:-false}"
  # Lines like "PRUNE_UNUSED=true \\\noutput=..." are assignment-only simple
  # commands (no command word), so bash keeps them as persistent shell
  # variables rather than scoping them to a subprocess. Clear them here so
  # one test's override never leaks into the next call.
  unset PRUNE_RUNTIME PRUNE_DRY_RUN PRUNE_INTERACTIVE PRUNE_UNUSED

  local args=""
  [[ "$runtime" != "all" ]] && args="--runtime=$runtime"
  [[ "$dry_run" == "true" ]] && args="$args --dry-run"
  [[ "$interactive" == "true" ]] && args="$args --interactive"
  [[ "$unused" == "true" ]] && args="$args --unused"

  # FZF_INPUT (also assignment-only, so also non-exported by default) must be
  # forwarded explicitly or the mocked fzf inside the execve'd bin/prune
  # process never sees it and silently falls back to a stdin passthrough,
  # selecting everything instead of the intended lines. Only forward it when
  # the caller actually set it (possibly to ""), matching the mock's
  # is-set-vs-empty distinction.
  local fzf_env=()
  [ "${FZF_INPUT+set}" = set ] && fzf_env=(FZF_INPUT="$FZF_INPUT")

  # Ensure SANDBOX_HOME is available inside the subprocess for the fzf mock
  RUN_PRUNE_OUTPUT="$(SANDBOX_HOME="$SANDBOX" env -u HOME -u PATH \
    HOME="$SANDBOX" PATH="$SANDBOX/MOCK_LMS:$PATH" "${fzf_env[@]}" \
    bash "$PRUNE" $args 2>&1)"

  unset FZF_INPUT
}

# ============================================================================
# Tests
# ============================================================================

# --- Test 1: fzf matching — single selection ---------------------------------
# The display format is: "%-8s  %-7s  %-10s  %s"
# Padded: [lms]  (8) + "  " (2) + 21.81G  (7) + "  " (2) + 14dd ago  (10) + "  " (2) = 31 chars
# Glob pattern ${line##*  } extracts model ID after last "  "
echo "=== Test: fzf matching — single selection ==="

# --dry-run: these fzf-matching tests exercise selection, not deletion. A real
# (non-dry-run) removal here would delete the sandbox's gemma dir from disk,
# and since collect_lms skips concrete dirs that no longer exist, Test 2's
# multi-select could never match gemma again — a stale shared-sandbox bug.
FZF_INPUT="[lms]  21.81G   14dd ago  google/gemma-4-26b-a4b" \
PRUNE_INTERACTIVE=true \
PRUNE_DRY_RUN=true \
run_prune; output="$RUN_PRUNE_OUTPUT"

check_contains "fzf matches google/gemma-4-26b-a4b from display line" \
  "Removing [lms] google/gemma-4-26b-a4b" "$output"

# Count how many "Removing" lines — should be exactly 1
removing_count=$(echo "$output" | grep -c 'Removing' || true)
check "single selection removes exactly 1 model" "1" "$removing_count"

# --- Test 2: fzf matching — multi-select (key bug fix) -----------------------
echo ""
echo "=== Test: fzf matching — multi-select ==="

GEMMA_LINE="[lms]  21.81G   14dd ago  google/gemma-4-26b-a4b"
GLM_LINE="[lms]  24.36G   25dd ago  zai-org/glm-4.7-flash"
FZF_INPUT="$GEMMA_LINE
$GLM_LINE" \
PRUNE_INTERACTIVE=true \
PRUNE_DRY_RUN=true \
run_prune; output="$RUN_PRUNE_OUTPUT"

check_contains "fzf matches google/gemma-4-26b-a4b in multi-select" \
  "google/gemma-4-26b-a4b" "$output"
check_contains "fzf matches zai-org/glm-4.7-flash in multi-select" \
  "zai-org/glm-4.7-flash" "$output"

# Count "Removing" lines — should be 2 (one per selected model)
removing_count=$(echo "$output" | grep -c 'Removing' || true)
check "multi-select produces 2 removal messages" "2" "$removing_count"

# --- Test 3: fzf empty selection (ESC) ---------------------------------------
echo ""
echo "=== Test: fzf empty selection (ESC) ==="

FZF_INPUT="" \
PRUNE_INTERACTIVE=true \
run_prune; output="$RUN_PRUNE_OUTPUT"

check_contains "fzf empty selection prints 'Nothing selected'" \
  "Nothing selected" "$output"

# --- Test 4: --dry-run mode (no actual deletion) -----------------------------
echo ""
echo "=== Test: --dry-run mode ==="

output="$(bash "$PRUNE" --dry-run 2>&1)"
check_contains "--dry-run shows hint in non-interactive mode" \
  "dry-run" "$output"

# --- Test 5: --runtime filter ------------------------------------------------
echo ""
echo "=== Test: --runtime filter ==="

PRUNE_RUNTIME=lms \
run_prune; output="$RUN_PRUNE_OUTPUT"
check_contains "--runtime=lms shows only lms models" \
  "[lms]" "$output"
! echo "$output" | grep -q '\[ollama\]' && check "--runtime=lms excludes ollama" "true" "true" || check "--runtime=lms excludes ollama" "true" "false"
! echo "$output" | grep -q '\[mlx\]' && check "--runtime=lms excludes mlx" "true" "true" || check "--runtime=lms excludes mlx" "true" "false"

PRUNE_RUNTIME=ollama \
run_prune; output="$RUN_PRUNE_OUTPUT"
check_contains "--runtime=ollama shows ollama models" \
  "[ollama]" "$output"

PRUNE_RUNTIME=mlx \
run_prune; output="$RUN_PRUNE_OUTPUT"
check_contains "--runtime=mlx shows mlx models" \
  "[mlx]" "$output"

# --- Test 6: --unused filter -------------------------------------------------
echo ""
echo "=== Test: --unused filter ==="

# All models in our sandbox are referenced by models.txt / models-ollama.txt / models-mlx.txt
# so --unused should show nothing.
PRUNE_UNUSED=true \
run_prune; output="$RUN_PRUNE_OUTPUT"
check_contains "--unused shows 'No unused models' when all referenced" \
  "No unused models" "$output"

# Add an orphan model dir that's NOT in any model list
mkdir -p "$SANDBOX/.lmstudio/models/lmstudio-community/orphan-model-xyz"
echo "orphan" > "$SANDBOX/.lmstudio/models/lmstudio-community/orphan-model-xyz/orphan.bin"

PRUNE_UNUSED=true \
run_prune; output="$RUN_PRUNE_OUTPUT"
check_contains "--unused shows orphan models not in any list" \
  "orphan" "$output"

# --- Test 7: Non-interactive mode (table output) -----------------------------
echo ""
echo "=== Test: non-interactive table output ==="

run_prune; output="$RUN_PRUNE_OUTPUT"
check_contains "non-interactive mode prints table header" \
  "Runtime" "$output"
check_contains "non-interactive mode prints model entries" \
  "[lms]" "$output"
check_contains "non-interactive mode shows total" \
  "models" "$output"

# --- Test 8: No models case -------------------------------------------------
echo ""
echo "=== Test: no models found ==="

# Temporarily rename the index so lms sees nothing. Must filter to
# --runtime=lms here — the mocked ollama/mlx sources always report their
# fixed entries regardless of the lms index file, so under the default
# --runtime=all this can never actually reach the "no models" branch.
mv "$SANDBOX/.lmstudio/.internal/model-index-cache.json" \
   "$SANDBOX/.lmstudio/.internal/model-index-cache.json.bak"

output="$(bash "$PRUNE" --runtime=lms 2>&1)"
check_contains "no models prints 'No models found'" \
  "No models found" "$output"

# Restore
mv "$SANDBOX/.lmstudio/.internal/model-index-cache.json.bak" \
   "$SANDBOX/.lmstudio/.internal/model-index-cache.json"

# --- Summary -----------------------------------------------------------------
echo ""
if [ "$fail" -eq 0 ]; then
  echo "${C_GRN}all $pass passed${C_RST}"
  exit 0
else
  echo "${C_RED}$fail failed${C_RST}, $pass passed"
  exit 1
fi
