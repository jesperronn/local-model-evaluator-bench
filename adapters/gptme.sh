#!/usr/bin/env bash
# Adapter: gptme -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching is needed here (unlike the previous
# proxy-routed version of this file).
#
# gptme uses OPENAI_BASE_URL + OPENAI_API_KEY for any openai-compatible
# backend; its client only recognizes "openai/" as a provider prefix.
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Install: pip install gptme
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v gptme >/dev/null 2>&1 || {
  echo "gptme not found; install: pip install gptme" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# gptme's client only recognizes "openai/" as a provider prefix, so wrap the model id
GPTME_MODEL="openai/${BARE_MODEL_ID}"

export OPENAI_BASE_URL="$OLLA_BASE_URL"
export OPENAI_API_KEY="$OLLA_API_KEY"

# gptme requires the Python bin to be on PATH
export PATH="/Users/jesper/Library/Python/3.14/bin:$PATH"

# --no-confirm: skip interactive approval prompts in headless mode.
# --workspace .: tells gptme the project root is CWD.
# --system: custom system prompt that guides the model to use 'save' for file edits
#   instead of 'append', preventing file duplication issues.
# gptme uses "openai" provider by default when OPENAI_* env vars are set.
SYSTEM_PROMPT="When editing files: use 'save' to write the complete file with corrections. Use 'append' only to add new content at the end. Never append a complete file replacement—use 'save' instead."

if [ ! -t 0 ]; then
  exec gptme \
    --model "${GPTME_MODEL}" \
    --workspace "$(pwd)" \
    --no-confirm \
    --system "$SYSTEM_PROMPT" \
    "$(cat)"
else
  exec gptme \
    --model "${GPTME_MODEL}" \
    --workspace "$(pwd)" \
    --system "$SYSTEM_PROMPT" \
    "$@"
fi
