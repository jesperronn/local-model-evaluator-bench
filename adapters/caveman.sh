#!/usr/bin/env bash
# Adapter: caveman -> LM Studio.
# caveman is a `pi`-based agent. Custom providers live in ~/.pi/agent/models.json;
# we define an `lmstudio` provider there (baseUrl http://localhost:1234/v1,
# api openai-completions) and select it by name. See docs/SETUP.md.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"

exec caveman \
  --provider lmstudio \
  --model "$MODEL_ID" \
  --print \
  "$PROMPT"
