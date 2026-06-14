#!/usr/bin/env bash
# Adapter: caveman -> Ollama.
# Uses the `ollama` provider defined in ~/.pi/agent/models.json
# (baseUrl http://localhost:11434/v1, api openai-completions).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

CAVEMAN_ARGS=(--provider ollama --model "$MODEL_ID")
if [ ! -t 0 ]; then
  CAVEMAN_ARGS+=(--print "$(cat)")
fi

exec caveman "${CAVEMAN_ARGS[@]}" "$@"
