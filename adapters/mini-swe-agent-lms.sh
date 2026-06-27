#!/usr/bin/env bash
# Adapter: mini-swe-agent v2 -> LM Studio (OpenAI-compatible).
# mini-swe-agent v2 is the minimal SWE-agent variant (<100 lines agent code).
# Install: pip install mini-swe-agent
# Routes through LiteLLM (litellm_model class by default in v2).
# Local model config: OPENAI_API_BASE + OPENAI_API_KEY env vars.
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

export OPENAI_API_BASE="$LMS_BASE_URL"
export OPENAI_API_KEY="$LMS_API_KEY"

# mini-swe-agent v2 requires the Python bin to be on PATH
export PATH="/Users/jesper/Library/Python/3.14/bin:$PATH"

if [ ! -t 0 ]; then
  TASK="$(cat)"
  exec mini-swe-agent \
    --model "openai/${MODEL_ID}" \
    --task "$TASK"
else
  exec mini-swe-agent \
    --model "openai/${MODEL_ID}"
fi
