#!/usr/bin/env bash
# Adapter: forge (@hoangsonw/forge via npm) -> LM Studio (OpenAI-compatible).
# Forge is a local-first agentic coding runtime with model routing.
# Install: npm install -g @hoangsonw/forge
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# Extract model name (remove provider prefix if present)
FORGE_MODEL="${MODEL_ID##*/}"

# Run forge with auto-approve and file permissions, without interactive prompts
if [ ! -t 0 ]; then
  TASK="$(cat)"
  exec forge run \
    --yes \
    --allow-files \
    --allow-shell \
    --non-interactive \
    --skip-permissions \
    --no-banner \
    "$TASK"
else
  exec forge run \
    --yes \
    --allow-files \
    --allow-shell \
    --non-interactive \
    --skip-permissions \
    "$@"
fi
