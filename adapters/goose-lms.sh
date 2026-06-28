#!/usr/bin/env bash
# Adapter: goose (Block Goose) -> LM Studio (OpenAI-compatible).
# Uses the openai provider with OPENAI_BASE_URL pointing at LMS_BASE_URL.
# --with-builtin developer enables file read/write tool calls.
# --no-session prevents goose from storing state between benchmark runs.
# --max-turns caps iterations to avoid hangs on self-verify cases.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
#
# Known model incompatibilities (revisit when adapter/model updates):
#   nvidia/nemotron-3-nano-omni  — goose 1.39.0, 2026-06-28
#     LM Studio fails to render the model's chat_template:
#     `Error rendering prompt with jinja template: Cannot apply filter
#     "string" to type: NullValue`. Bug in the model's shipped template
#     (a field arrives null and the template doesn't guard for it).
#     Fix is on the model side — override the prompt template in LM Studio
#     model settings, or use an lmstudio-community repack. See run
#     20260628-073902.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

export GOOSE_PROVIDER=openai
export OPENAI_BASE_URL="$LMS_BASE_URL"
export OPENAI_API_KEY="$LMS_API_KEY"
export GOOSE_MODEL="$MODEL_ID"

GOOSE_ARGS=(
  --with-builtin developer
  --no-session
  --max-turns 30
)

if [ ! -t 0 ]; then
  exec goose run -i - "${GOOSE_ARGS[@]}"
else
  exec goose session "${GOOSE_ARGS[@]}" "$@"
fi
