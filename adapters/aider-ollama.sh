#!/usr/bin/env bash
# Adapter: aider -> Ollama (OpenAI-compatible at localhost:11434/v1).
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail

AIDER_ARGS=(
  --model "openai/${MODEL_ID}"
  --openai-api-base "${OLLAMA_BASE_URL}"
  --openai-api-key "ollama"
  --no-auto-commits --no-dirty-commits --no-git
  --no-check-update --no-show-model-warnings
)
if [ ! -t 0 ]; then
  AIDER_ARGS+=(--yes-always --message "$(cat)")
fi

exec aider "${AIDER_ARGS[@]}" "$@"
