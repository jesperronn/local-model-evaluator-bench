#!/usr/bin/env bash
# Adapter: mini-swe-agent v2 -> oMLX (OpenAI-compatible).
# mini-swe-agent v2 is the minimal SWE-agent variant (<100 lines agent code).
# Install: python3 -m pip install --break-system-packages mini-swe-agent
# Routes through LiteLLM (litellm_model class by default in v2).
# Local model config: OPENAI_API_BASE + OPENAI_API_KEY env vars.
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

export OPENAI_API_BASE="$OMLX_BASE_URL"
export OPENAI_API_KEY="$OMLX_API_KEY"
export MINI_CONFIG_INTERACTIVE=0
# litellm has no cost table for local model ids; without this it raises
# instead of just skipping cost tracking.
export MSWEA_COST_TRACKING=ignore_errors

# mini-swe-agent v2 requires the Python bin to be on PATH
export PATH="/Users/jesper/Library/Python/3.14/bin:$PATH"

if [ ! -t 0 ]; then
  TASK="$(cat)"
  # agent.mode defaults to "confirm" (interactive per-step approval), which
  # hangs forever with stdin piped. yolo runs unattended.
  exec mini-swe-agent \
    --model "openai/${MODEL_ID}" \
    -c mini.yaml -c agent.mode=yolo \
    --exit-immediately \
    --task "$TASK"
else
  exec mini-swe-agent \
    --model "openai/${MODEL_ID}"
fi
