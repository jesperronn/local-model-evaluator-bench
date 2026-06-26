#!/usr/bin/env bash
# Adapter: mini-swe-agent -> LM Studio (OpenAI-compatible).
# mini-swe-agent is a ~100-line ReAct loop variant from the SWE-agent team.
# Install: pip install mini-swe-agent
# Local model config: OPENAI_API_BASE + OPENAI_API_KEY env vars; model name
# must be prefixed with `openai/` to route through LiteLLM.
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

export OPENAI_API_BASE="$LMS_BASE_URL"
export OPENAI_API_KEY="$LMS_API_KEY"

if [ ! -t 0 ]; then
  exec mini-swe-agent \
    --model "openai/${MODEL_ID}" \
    --repo-path "$(pwd)" \
    --problem-statement "$(cat)" \
    "$@"
else
  exec mini-swe-agent \
    --model "openai/${MODEL_ID}" \
    --repo-path "$(pwd)" \
    "$@"
fi
