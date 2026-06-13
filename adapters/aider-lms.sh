#!/usr/bin/env bash
# Adapter: aider  -> LM Studio (OpenAI-compatible).
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
# Aider treats LM Studio as a generic OpenAI provider via --openai-api-base.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# aider reaches the openai-compatible endpoint via these two flags + the
# "openai/" model prefix. --yes-always auto-approves; we disable git/commits
# and update checks so a run is non-interactive and self-contained.
AIDER_ARGS=(
  --model "openai/${MODEL_ID}"
  --openai-api-base "$LMS_BASE_URL"
  --openai-api-key "$LMS_API_KEY"
  --no-auto-commits --no-dirty-commits --no-git
  --no-check-update --no-show-model-warnings
)
if [ ! -t 0 ]; then
  AIDER_ARGS+=(--yes-always --message "$(cat)")
fi

exec aider "${AIDER_ARGS[@]}" "$@"
