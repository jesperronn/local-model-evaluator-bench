#!/usr/bin/env bash
# Adapter: caveman -> Ollama.
# Uses the `ollama` provider defined in ~/.pi/agent/models.json
# (baseUrl http://localhost:11434/v1, api openai-completions).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"

exec caveman \
  --provider ollama \
  --model "$MODEL_ID" \
  --print \
  "$PROMPT" \
  "$@"
