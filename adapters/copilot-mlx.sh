#!/usr/bin/env bash
# Adapter: GitHub Copilot CLI -> mlx_lm.server (BYOK mode).
# Same BYOK env var approach as copilot-lms.sh but points at mlx_lm.server's
# OpenAI-compatible endpoint on port 8080.
# Start the server first: mlx_lm.server --model <path> --port 8080
#
# COPILOT_PROVIDER_MODEL_ID=gpt-4o: a well-known catalog entry for token limits.
# COPILOT_PROVIDER_WIRE_MODEL: actual model name sent to mlx_lm.server.
#
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

COPILOT_ARGS=()
if [ ! -t 0 ]; then
  COPILOT_ARGS+=(--allow-all-tools --allow-all-paths --no-ask-user -p "$(cat)")
fi

exec env \
  COPILOT_PROVIDER_BASE_URL="http://localhost:8080/v1" \
  COPILOT_PROVIDER_TYPE="openai" \
  COPILOT_PROVIDER_API_KEY="mlx" \
  COPILOT_PROVIDER_MODEL_ID="gpt-4o" \
  COPILOT_PROVIDER_WIRE_MODEL="$MODEL_ID" \
  COPILOT_OFFLINE="true" \
  copilot "${COPILOT_ARGS[@]}" "$@"
