#!/usr/bin/env bash
# Adapter: opencode -> Ollama via tool-call proxy.
# Uses the `ollama_proxy` provider in ~/.config/opencode/opencode.jsonc
# (baseURL: http://localhost:11435/v1) which routes through bin/tool-call-proxy.
# Start proxy first: bin/tool-call-proxy &
#
# The model ID must be registered in opencode.jsonc under the ollama_proxy
# provider's models map.  Bare names without a tag (e.g. qwen2.5-coder-7b)
# are normalized to <name>:latest to match the registry entry.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

# Normalize bare model name to <name>:latest (opencode requires exact match)
OPENCODE_MODEL_ID="${MODEL_ID}"
if [[ "${OPENCODE_MODEL_ID}" != *:* ]]; then
  OPENCODE_MODEL_ID="${OPENCODE_MODEL_ID}:latest"
fi

if [ -t 0 ]; then
  exec opencode --model "ollama_proxy/${OPENCODE_MODEL_ID}" "$@"
else
  exec opencode run --model "ollama_proxy/${OPENCODE_MODEL_ID}" "$(cat)" "$@"
fi
