#!/usr/bin/env bash
# Adapter: caveman -> LM Studio.
# caveman uses an OpenAI-compatible provider; point it at LM Studio via the
# OPENAI_BASE_URL env var and select it with --provider openai.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
# NOTE: verify the exact provider flag with `caveman --help`; adjust if needed.
set -euo pipefail
PROMPT="$(cat)"

export OPENAI_BASE_URL="$LMS_BASE_URL"
export OPENAI_API_KEY="$LMS_API_KEY"

exec caveman \
  --provider openai \
  --model "$MODEL_ID" \
  --api-key "$LMS_API_KEY" \
  --print \
  "$PROMPT"
