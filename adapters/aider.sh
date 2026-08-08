#!/usr/bin/env bash
# Adapter: aider -> any local runtime (lms | ollama | mlx), all OpenAI-compatible.
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
#
# bin/bench exports LMS_BASE_URL/LMS_API_KEY already pointed at the *active*
# runtime, so the endpoint needs no per-runtime branching here. Only the flags
# that genuinely differ per runtime are switched on $RUNTIME below.
# Note: This adapter is for testing aider as an agent tool. Use `aider` directly
# for interactive work.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"
RUNTIME="${RUNTIME:-lms}"

declare -a REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL_ID="$2"; shift 2;;
    *)       REMAINING_ARGS+=("$1"); shift;;
  esac
done

MESSAGE=$(timeout 0.1 cat 2>/dev/null || true)
if [ -z "$MESSAGE" ]; then
  cat >&2 <<EOF
Error: aider adapter requires input text (prompt) on stdin.

This adapter is for testing aider as an agent tool via bin/bench.
It cannot be used interactively.

Next steps:
  1. For testing: pipe a prompt via stdin:
     echo "your prompt" | adapters/aider.sh --model qwen/qwen3.5-9b

  2. For interactive work, use aider directly:
     aider --model openai/qwen/qwen3.5-9b \\
       --openai-api-base "$LMS_BASE_URL" \\
       --openai-api-key "$LMS_API_KEY"
EOF
  exit 1
fi

AIDER_ARGS=(
  --model "openai/${MODEL_ID}"
  --openai-api-base "$LMS_BASE_URL"
  --openai-api-key "$LMS_API_KEY"
  --no-check-update --no-show-model-warnings --no-gitignore
  --yes-always --no-auto-commits --no-dirty-commits
)

case "$RUNTIME" in
  ollama)
    # Ollama-served models produce cleaner search/replace diffs than whole-file
    # rewrites; without this aider defaults to `whole` and truncates on edits.
    AIDER_ARGS+=(--edit-format diff --no-git)
    ;;
  mlx)
    # aider can't infer context/cost limits for a filesystem model path, so the
    # metadata has to be supplied explicitly or it refuses to run.
    AIDER_ARGS+=(--model-metadata-file "${SCRIPT_DIR}/aider-mlx-model-metadata.json")
    ;;
  omlx)
    # Same reason as mlx: the model id is a bare directory name aider's registry
    # has never heard of. The metadata file is generated from what oMLX serves —
    # regenerate after adding models with: bin/omlx aider-metadata
    AIDER_ARGS+=(--model-metadata-file "${SCRIPT_DIR}/aider-omlx-model-metadata.json")
    # No --edit-format override: aider's default (whole) is what works here.
    # Measured 2026-08-06 on Ornith-1.0-9B-4bit — forcing `diff` (as the ollama
    # branch does) made create-from-scratch fail: the model emitted a bare fenced
    # block instead of a SEARCH/REPLACE pair with an empty SEARCH, so smoke-00
    # never produced the file. Edits passed either way.
    ;;
esac

AIDER_ARGS+=(--message "$MESSAGE")

# Pass the sandbox's source files so aider has context for edit cases. Empty for
# create-from-scratch cases, which is fine.
mapfile -t FILES < <(find . -type f \
  -not -path './.git/*' \
  -not -name '.*' \
  -not -name '*.log' \
  2>/dev/null | sort)

exec aider "${AIDER_ARGS[@]}" "${FILES[@]}" "${REMAINING_ARGS[@]}"
