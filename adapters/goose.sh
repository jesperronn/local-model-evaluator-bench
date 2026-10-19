#!/usr/bin/env bash
# Adapter: goose (Block Goose) -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching and no per-runtime endpoint selection are
# needed here (unlike the old LiteLLM-routed version of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Uses the openai provider with OPENAI_BASE_URL pointing at Olla.
# --with-builtin developer enables file read/write tool calls.
# --no-session (goose run only) prevents goose from storing state between
# benchmark runs. `goose session` has no such flag — it always keeps state.
# --max-turns caps iterations to avoid hangs on self-verify cases.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v goose >/dev/null 2>&1 || {
  echo "goose not found; install: npm install -g @block-foundation/block-goose-cli or equivalent" >&2
  exit 1
}

adapter_endpoint || exit 1

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"
export OPENAI_BASE_URL="$EP_URL"
export OPENAI_API_KEY="$EP_KEY"

export GOOSE_PROVIDER=openai
export GOOSE_MODEL="$BARE_MODEL_ID"

GOOSE_ARGS=(
  --with-builtin developer
  --max-turns 30
)

if [ ! -t 0 ]; then
  exec goose run -i - --no-session "${GOOSE_ARGS[@]}"
else
  exec goose session "${GOOSE_ARGS[@]}" "$@"
fi
