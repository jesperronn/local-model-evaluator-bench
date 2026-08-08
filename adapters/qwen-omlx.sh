#!/usr/bin/env bash
# Adapter: qwen (Qwen Code CLI) -> oMLX.
# Qwen Code's "openai" auth type is surfaced without any settings.json —
# OPENAI_API_KEY/OPENAI_BASE_URL/OPENAI_MODEL alone select it. No provider
# catalog to keep in sync, unlike pi/opencode.
# Start the server first: bin/omlx start
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v qwen >/dev/null 2>&1 || {
  echo "qwen not found; install: npm install -g @qwen-code/qwen-code" >&2
  exit 1
}

export OPENAI_API_KEY="$OMLX_API_KEY"
export OPENAI_BASE_URL="$OMLX_BASE_URL"
export OPENAI_MODEL="$MODEL_ID"
export QWEN_CODE_SUPPRESS_YOLO_WARNING=1

QWEN_ARGS=(--model "$MODEL_ID" --approval-mode yolo)

if [ ! -t 0 ]; then
  exec qwen "${QWEN_ARGS[@]}" -p "$(cat)"
else
  exec qwen "${QWEN_ARGS[@]}" "$@"
fi
