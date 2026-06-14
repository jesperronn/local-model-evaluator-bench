#!/usr/bin/env bash
# Adapter: opencode -> Ollama.
# Uses the `ollama` provider configured in ~/.config/opencode/opencode.jsonc
# (baseURL: http://localhost:11434/v1). The model is addressed as ollama/<id>.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

if [ -t 0 ]; then
  exec opencode --model "ollama/${MODEL_ID}" "$@"
else
  exec opencode run --model "ollama/${MODEL_ID}" "$(cat)" "$@"
fi
