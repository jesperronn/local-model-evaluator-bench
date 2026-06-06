#!/usr/bin/env bash
# Adapter: aider  -> LM Studio (OpenAI-compatible).
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
# Aider treats LM Studio as a generic OpenAI provider via --openai-api-base.
set -euo pipefail
PROMPT="$(cat)"

# aider reaches the openai-compatible endpoint via these two flags + the
# "openai/" model prefix. --yes-always auto-approves; we disable git/commits
# and update checks so a run is non-interactive and self-contained.
exec aider \
  --model "openai/${MODEL_ID}" \
  --openai-api-base "$LMS_BASE_URL" \
  --openai-api-key "$LMS_API_KEY" \
  --no-auto-commits --no-dirty-commits --no-git \
  --no-check-update --no-show-model-warnings \
  --yes-always \
  --message "$PROMPT"
