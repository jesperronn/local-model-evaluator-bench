#!/usr/bin/env bash
# Adapter: aider -> mlx_lm.server (OpenAI-compatible at localhost:8080/v1).
# Start server first: mlx_lm.server --model <path> --port 8080
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIDER_ARGS=(
  --model "openai/${MODEL_ID}"
  --openai-api-base "http://localhost:8080/v1"
  --openai-api-key "mlx"
  --model-metadata-file "${SCRIPT_DIR}/aider-mlx-model-metadata.json"
  --no-check-update --no-show-model-warnings --no-gitignore
)
if [ ! -t 0 ]; then
  mapfile -t SANDBOX_FILES < <(find . -type f \
    -not -path '*/.*' \
    -not -name '*.log' \
    -not -name '*.json' \
    -not -name '*.md' \
    2>/dev/null | sort)
  AIDER_ARGS+=(--yes-always --no-auto-commits --no-dirty-commits --message "$(cat)" "${SANDBOX_FILES[@]}")
fi

exec aider "${AIDER_ARGS[@]}" "$@"
