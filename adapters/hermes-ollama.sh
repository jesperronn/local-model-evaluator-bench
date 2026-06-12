#!/usr/bin/env bash
# Adapter: hermes -> Ollama runtime.
# Uses hermes's built-in `ollama` provider (localhost:11434) instead of
# the lmstudio provider. Same toolsets and no-yolo config as hermes.sh.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"

exec hermes \
  --provider ollama \
  -m "$MODEL_ID" \
  -t file,terminal \
  -z "$PROMPT" \
  "$@"
