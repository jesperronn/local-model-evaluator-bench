#!/usr/bin/env bash
# Adapter: interpreter (Open Interpreter) -> Ollama (OpenAI-compatible at localhost:11434/v1).
# Inline-configures a provider named "ollama" so no edits to config.toml are
# needed. wire_api="responses" matches the existing Ollama provider in config.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

OI_CONFIG=(
  -c 'model_provider="ollama"'
  -c "model=\"$MODEL_ID\""
  -c "model_providers.ollama.base_url=\"${OLLAMA_BASE_URL}\""
  -c 'model_providers.ollama.wire_api="responses"'
)

if [ ! -t 0 ]; then
  exec interpreter exec "${OI_CONFIG[@]}" "$(cat)"
else
  exec interpreter "${OI_CONFIG[@]}" "$@"
fi
