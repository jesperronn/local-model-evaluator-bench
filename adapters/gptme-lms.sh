#!/usr/bin/env bash
# Adapter: gptme -> LM Studio (OpenAI-compatible).
# gptme uses OPENAI_BASE_URL + OPENAI_API_KEY for any openai-compatible backend.
# Install: pip install gptme
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

export OPENAI_BASE_URL="$LMS_BASE_URL"
export OPENAI_API_KEY="$LMS_API_KEY"

# --no-confirm: skip interactive approval prompts in headless mode.
# --workspace .: tells gptme the project root is CWD.
if [ ! -t 0 ]; then
  exec gptme \
    --model "openai/${MODEL_ID}" \
    --workspace "$(pwd)" \
    --no-confirm \
    "$(cat)"
else
  exec gptme \
    --model "openai/${MODEL_ID}" \
    --workspace "$(pwd)" \
    "$@"
fi
