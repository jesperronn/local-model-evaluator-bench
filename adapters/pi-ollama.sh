#!/usr/bin/env bash
# Adapter: pi -> Ollama (via OpenAI-compatible API).
# pi does not have a native ollama provider; we point --provider openai at
# Ollama's OpenAI-compatible endpoint (localhost:11434/v1).
# Install: npm install -g @earendil-works/pi-coding-agent
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v pi >/dev/null 2>&1 || {
  echo "pi not found; install: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
}

export OPENAI_BASE_URL="http://localhost:11434/v1"
export OPENAI_API_KEY="ollama"

PI_ARGS=(--provider openai --model "$MODEL_ID")

if [ ! -t 0 ]; then
  exec pi "${PI_ARGS[@]}" -p "$(cat)"
else
  exec pi "${PI_ARGS[@]}" "$@"
fi
