#!/usr/bin/env bash
# Adapter: goose (Block Goose) -> oMLX (OpenAI-compatible).
# Uses the openai provider with OPENAI_BASE_URL pointing at OMLX_BASE_URL.
# --with-builtin developer enables file read/write tool calls.
# --no-session (goose run only) prevents goose from storing state between
# benchmark runs. `goose session` has no such flag — it always keeps state.
# --max-turns caps iterations to avoid hangs on self-verify cases.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

export GOOSE_PROVIDER=openai
export OPENAI_BASE_URL="$OMLX_BASE_URL"
export OPENAI_API_KEY="$OMLX_API_KEY"
export GOOSE_MODEL="$MODEL_ID"

GOOSE_ARGS=(
  --with-builtin developer
  --max-turns 30
)

if [ ! -t 0 ]; then
  exec goose run -i - --no-session "${GOOSE_ARGS[@]}"
else
  exec goose session "${GOOSE_ARGS[@]}" "$@"
fi
