#!/usr/bin/env bash
# Adapter: aider -> Ollama (OpenAI-compatible at localhost:11434/v1).
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail

AIDER_ARGS=(
  --model "openai/${MODEL_ID}"
  --openai-api-base "${OLLAMA_BASE_URL}"
  --openai-api-key "ollama"
  --edit-format diff
  --no-check-update --no-show-model-warnings --no-gitignore
)
if [ ! -t 0 ]; then
  AIDER_ARGS+=(--yes-always --no-auto-commits --no-dirty-commits --no-git --message "$(cat)")
fi

# Pass all files in CWD so aider has context for edit cases.
# For create-from-scratch tasks (empty sandbox) this array is empty.
mapfile -t FILES < <(find . -type f -not -path './.git/*' -not -name '.*' 2>/dev/null)

exec aider "${AIDER_ARGS[@]}" "${FILES[@]}" "$@"
