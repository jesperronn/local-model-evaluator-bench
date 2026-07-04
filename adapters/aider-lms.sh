#!/usr/bin/env bash
# Adapter: aider  -> LM Studio (OpenAI-compatible).
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
# Aider treats LM Studio as a generic OpenAI provider via --openai-api-base.
# Note: This adapter is for testing aider as an agent tool. Use `aider` directly for interactive work.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# Parse --model flag if present
declare -a REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      MODEL_ID="$2"
      shift 2
      ;;
    *)
      REMAINING_ARGS+=("$1")
      shift
      ;;
  esac
done

# Read prompt from stdin with timeout
MESSAGE=$(timeout 0.1 cat 2>/dev/null || true)

# Fail if no input received (adapter is test-only, needs a prompt on stdin)
if [ -z "$MESSAGE" ]; then
  cat >&2 <<EOF
Error: aider adapter requires input text (prompt) on stdin.

This adapter is for testing aider as an agent tool via bin/bench.
It cannot be used interactively.

Next steps:
  1. For testing: pipe a prompt via stdin:
     echo "your prompt" | adapters/aider-lms.sh --model qwen/qwen3.5-9b

  2. For interactive work, use aider directly:
     aider --model openai/qwen/qwen3.5-9b \\
       --openai-api-base http://localhost:1234/v1 \\
       --openai-api-key lm-studio
EOF
  exit 1
fi

AIDER_ARGS=(
  --model "openai/${MODEL_ID}"
  --openai-api-base "$LMS_BASE_URL"
  --openai-api-key "$LMS_API_KEY"
  --no-check-update --no-show-model-warnings --no-gitignore
  --yes-always --no-auto-commits --no-dirty-commits --message "$MESSAGE"
)

exec aider "${AIDER_ARGS[@]}" "${REMAINING_ARGS[@]}"
