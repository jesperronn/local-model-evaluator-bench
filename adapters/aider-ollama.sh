#!/usr/bin/env bash
# Adapter: aider -> Ollama (OpenAI-compatible at localhost:11434/v1).
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"

exec aider \
  --model "openai/${MODEL_ID}" \
  --openai-api-base "http://localhost:11434/v1" \
  --openai-api-key "ollama" \
  --no-auto-commits --no-dirty-commits --no-git \
  --no-check-update --no-show-model-warnings \
  --yes-always \
  --message "$PROMPT" \
  "$@"
