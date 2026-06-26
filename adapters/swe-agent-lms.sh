#!/usr/bin/env bash
# Adapter: swe-agent -> LM Studio (OpenAI-compatible).
# Uses LiteLLM's `openai/` prefix with a custom api_base to redirect to LMS.
# Run with: pip install swe-agent  (or mini-swe-agent for the small variant)
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# LiteLLM model address: openai/<id> with api_base pointing at LM Studio.
LITELLM_MODEL="openai/${MODEL_ID}"

if [ ! -t 0 ]; then
  TASK="$(cat)"
  exec sweagent run \
    --model.name "$LITELLM_MODEL" \
    --model.api_base "$LMS_BASE_URL" \
    --model.api_key "$LMS_API_KEY" \
    --model.cost_tracking ignore_errors \
    --env.repo.path "$(pwd)" \
    --problem_statement.text "$TASK" \
    --output_dir /tmp/swe-agent-out \
    --no-print-trajectory \
    "$@"
else
  exec sweagent run \
    --model.name "$LITELLM_MODEL" \
    --model.api_base "$LMS_BASE_URL" \
    --model.api_key "$LMS_API_KEY" \
    --model.cost_tracking ignore_errors \
    --env.repo.path "$(pwd)" \
    "$@"
fi
