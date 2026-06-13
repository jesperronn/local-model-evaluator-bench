#!/usr/bin/env bash
# Adapter: GitHub Copilot CLI -> LM Studio (BYOK / bring-your-own-key mode).
# COPILOT_PROVIDER_BASE_URL redirects all model calls to LM Studio's
# OpenAI-compatible endpoint, bypassing GitHub's Copilot service entirely.
# COPILOT_OFFLINE=true prevents the CLI from phoning home to GitHub.
# Docs: https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-byok-models
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

COPILOT_ARGS=(--allow-all-tools --allow-all-paths --no-ask-user)
if [ ! -t 0 ]; then
  COPILOT_ARGS+=(-p "$(cat)")
fi

exec env \
  COPILOT_PROVIDER_BASE_URL="$LMS_BASE_URL" \
  COPILOT_PROVIDER_TYPE="openai" \
  COPILOT_PROVIDER_API_KEY="$LMS_API_KEY" \
  COPILOT_MODEL="$MODEL_ID" \
  COPILOT_OFFLINE="true" \
  copilot "${COPILOT_ARGS[@]}" "$@"
