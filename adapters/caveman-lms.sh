#!/usr/bin/env bash
# Adapter: caveman -> LM Studio.
# caveman is a `pi`-based agent. Custom providers live in ~/.pi/agent/models.json;
# we define an `lmstudio` provider there (baseUrl http://localhost:1234/v1,
# api openai-completions) and select it by name. See docs/SETUP.md.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

CAVEMAN_ARGS=(--provider lmstudio --model "$MODEL_ID")
if [ ! -t 0 ]; then
  CAVEMAN_ARGS+=(--print "$(cat)")
fi

exec caveman "${CAVEMAN_ARGS[@]}" "$@"
