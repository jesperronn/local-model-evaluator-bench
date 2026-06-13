#!/usr/bin/env bash
# Adapter: GitHub Copilot CLI -> mlx_lm.server (BYOK mode).
# Same BYOK env var approach as copilot-lms.sh but points at mlx_lm.server's
# OpenAI-compatible endpoint on port 8080.
# Start the server first: mlx_lm.server --model <path> --port 8080
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"

exec env \
  COPILOT_PROVIDER_BASE_URL="http://localhost:8080/v1" \
  COPILOT_PROVIDER_TYPE="openai" \
  COPILOT_PROVIDER_API_KEY="mlx" \
  COPILOT_MODEL="$MODEL_ID" \
  COPILOT_OFFLINE="true" \
  copilot \
    --allow-all-tools \
    --allow-all-paths \
    --no-ask-user \
    --silent \
    -p "$PROMPT" \
    "$@"
