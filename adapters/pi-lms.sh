#!/usr/bin/env bash
# Adapter: pi -> LM Studio (OpenAI-compatible).
# pi (@earendil-works/pi-coding-agent) supports LM Studio via
# --provider lmstudio. The -p flag runs headlessly; without -p it starts the TUI.
# Install: npm install -g @earendil-works/pi-coding-agent
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v pi >/dev/null 2>&1 || {
  echo "pi not found; install: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
}

PI_ARGS=(--provider lmstudio --model "$MODEL_ID")

if [ ! -t 0 ]; then
  exec pi "${PI_ARGS[@]}" -p "$(cat)"
else
  exec pi "${PI_ARGS[@]}" "$@"
fi
