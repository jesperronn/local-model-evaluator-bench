#!/usr/bin/env bash
# Adapter: forge -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching, no --provider flag, and no direct-runtime
# base-URL selection are needed here (unlike the old LiteLLM-routed version
# of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Install: npm install -g @hoangsonw/forge
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v forge >/dev/null 2>&1 || {
  echo "forge not found; install: npm install -g @hoangsonw/forge" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

export OPENAI_BASE_URL="$OLLA_BASE_URL"
export OPENAI_API_KEY="$OLLA_API_KEY"
export OPENAI_MODEL="$BARE_MODEL_ID"

# Configure forge to use the Olla-routed model for all modes.
# This ensures forge always uses the specified model instead of its defaults
forge config set "models.fast" "$BARE_MODEL_ID" >/dev/null 2>&1 || true
forge config set "models.balanced" "$BARE_MODEL_ID" >/dev/null 2>&1 || true
forge config set "models.heavy" "$BARE_MODEL_ID" >/dev/null 2>&1 || true
forge config set "models.planner" "$BARE_MODEL_ID" >/dev/null 2>&1 || true

# Run forge with auto-approve and file permissions, without interactive prompts
if [ ! -t 0 ]; then
  TASK="$(cat)"
  exec forge run \
    --yes \
    --allow-files \
    --allow-shell \
    --non-interactive \
    --skip-permissions \
    --no-banner \
    "$TASK"
else
  exec forge run \
    --yes \
    --allow-files \
    --allow-shell \
    --non-interactive \
    --skip-permissions \
    "$@"
fi
