#!/usr/bin/env bash
# Adapter: interpreter (Open Interpreter) -> Ollama (OpenAI-compatible at localhost:11434/v1).
# Uses the "ollama-launch-codex-app" provider already defined in
# ~/.openinterpreter/config.toml (base_url http://127.0.0.1:11434/v1/,
# wire_api="responses"). "ollama" itself is a reserved built-in provider id
# in this tool and cannot be overridden — using it throws
# "reserved built-in provider IDs".
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

OI_CONFIG=(
  -c 'model_provider="ollama-launch-codex-app"'
  -c "model=\"$MODEL_ID\""
)

if [ ! -t 0 ]; then
  exec interpreter exec -s workspace-write "${OI_CONFIG[@]}" "$(cat)"
else
  exec interpreter "${OI_CONFIG[@]}" "$@"
fi
