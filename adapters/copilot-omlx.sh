#!/usr/bin/env bash
# Adapter: GitHub Copilot CLI -> oMLX (BYOK mode).
# Same BYOK env var approach as copilot-lms.sh/copilot-mlx.sh but points at
# oMLX's OpenAI-compatible endpoint.
# Start the server first: bin/omlx start
#
# COPILOT_PROVIDER_MODEL_ID=gpt-4o: a well-known catalog entry for token limits.
# COPILOT_PROVIDER_WIRE_MODEL: actual model name sent to oMLX.
#
# Same patch-format incompatibility documented for lms/mlx likely applies here
# too (docs/AGENT-SELECTION.md) — verify smoke result rather than assuming.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

COPILOT_ARGS=()
if [ ! -t 0 ]; then
  COPILOT_ARGS+=(--allow-all-tools --allow-all-paths --no-ask-user -p "$(cat)")
fi

exec env \
  COPILOT_PROVIDER_BASE_URL="$OMLX_BASE_URL" \
  COPILOT_PROVIDER_TYPE="openai" \
  COPILOT_PROVIDER_API_KEY="$OMLX_API_KEY" \
  COPILOT_PROVIDER_MODEL_ID="gpt-4o" \
  COPILOT_PROVIDER_WIRE_MODEL="$MODEL_ID" \
  COPILOT_OFFLINE="true" \
  copilot "${COPILOT_ARGS[@]}" "$@"
