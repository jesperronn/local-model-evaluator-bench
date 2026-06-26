#!/usr/bin/env bash
# Adapter: forge (antinomyhq/forge) -> LM Studio (OpenAI-compatible).
# Forge is a Rust CLI agent that routes to any OpenAI-compatible backend.
# Install: cargo install forge-cli  (or download binary from GitHub releases)
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# Forge reads the endpoint and key from env vars; --model overrides the default.
export OPENAI_API_BASE="$LMS_BASE_URL"
export OPENAI_API_KEY="$LMS_API_KEY"

if [ ! -t 0 ]; then
  exec forge \
    --model "$MODEL_ID" \
    --no-confirm \
    "$(cat)"
else
  exec forge \
    --model "$MODEL_ID" \
    "$@"
fi
