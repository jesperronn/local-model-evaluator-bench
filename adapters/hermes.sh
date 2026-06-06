#!/usr/bin/env bash
# Adapter: hermes -> LM Studio.
# hermes runs non-interactively with -z (prompt) and -m/--provider. Point its
# OpenAI-compatible provider at LM Studio via env. Configure a persistent
# provider with `hermes setup` or `hermes config` (see docs/SETUP.md).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
# NOTE: verify provider name with `hermes model` / `hermes config`; adjust.
set -euo pipefail
PROMPT="$(cat)"

export OPENAI_BASE_URL="$LMS_BASE_URL"
export OPENAI_API_KEY="$LMS_API_KEY"

exec hermes \
  --provider openai \
  -m "$MODEL_ID" \
  --yolo \
  -z "$PROMPT"
