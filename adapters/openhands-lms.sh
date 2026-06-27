#!/usr/bin/env bash
# Adapter: openhands -> LM Studio (OpenAI-compatible).
# OpenHands SDK v1.21+ with local LLM support via environment variables.
# Install: uv tool install openhands
# Routes through LiteLLM via LLM_* environment variables.
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

export LLM_API_KEY="$LMS_API_KEY"
export LLM_BASE_URL="$LMS_BASE_URL"
export LLM_MODEL="openai/${MODEL_ID}"
export OPENHANDS_SUPPRESS_BANNER=1

# Ensure openhands is on PATH (uv tool install puts it in ~/.local/bin)
export PATH="$HOME/.local/bin:$PATH"

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
