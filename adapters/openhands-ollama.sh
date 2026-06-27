#!/usr/bin/env bash
# Adapter: openhands -> Ollama (OpenAI-compatible).
# OpenHands SDK v1.21+ with local LLM support via environment variables.
# Install: uv tool install openhands
# Routes through LiteLLM via LLM_* environment variables.
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail

MODEL_ID="${MODEL_ID:-}"
[ -z "$MODEL_ID" ] && { echo "MODEL_ID not set" >&2; exit 1; }

export LLM_API_KEY="ollama"
export LLM_BASE_URL="http://localhost:11434/v1"
export LLM_MODEL="openai/${MODEL_ID}"
export OPENHANDS_SUPPRESS_BANNER=1

if [ ! -t 0 ]; then
  TASK="$(cat)"
  exec openhands \
    --headless \
    --task "$TASK" \
    --override-with-envs \
    "$@"
else
  exec openhands \
    --override-with-envs \
    "$@"
fi
