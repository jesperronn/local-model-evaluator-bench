#!/usr/bin/env bash
# Adapter: aider  -> LM Studio (OpenAI-compatible).
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
# Aider treats LM Studio as a generic OpenAI provider via --openai-api-base.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

AIDER_ARGS=(
  --model "openai/${MODEL_ID}"
  --openai-api-base "$LMS_BASE_URL"
  --openai-api-key "$LMS_API_KEY"
  --no-check-update --no-show-model-warnings
)
if [ ! -t 0 ]; then
  # Pass existing source files so aider has file content in context.
  # Without this, models must hallucinate file contents from the task description,
  # which causes format failures on small models.
  mapfile -t SANDBOX_FILES < <(find . -type f \
    -not -path '*/.*' \
    -not -name '*.log' \
    -not -name '*.json' \
    -not -name '*.md' \
    2>/dev/null | sort)
  AIDER_ARGS+=(--yes-always --no-auto-commits --no-dirty-commits --message "$(cat)" "${SANDBOX_FILES[@]}")
fi

exec aider "${AIDER_ARGS[@]}" "$@"
