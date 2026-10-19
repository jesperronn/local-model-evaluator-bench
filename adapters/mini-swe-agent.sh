#!/usr/bin/env bash
# Adapter: mini-swe-agent -> unified endpoint via Olla proxy (OpenAI format).
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
# mini-swe-agent's bundled litellm client parses --model before any network
# call, and only recognizes litellm's built-in provider registry — a bare
# model id throws `LLM Provider NOT provided` before ever reaching Olla.
# Wrapping the bare id in "openai/" satisfies litellm's client-side check
# while still sending the plain id Olla expects.
#
# Install: python3 -m pip install --break-system-packages mini-swe-agent
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# mini-swe-agent v2 requires the Python bin to be on PATH
export PATH="/Users/jesper/Library/Python/3.14/bin:$PATH"

adapter_endpoint || exit 1

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

export OPENAI_API_BASE="$EP_URL"
export OPENAI_API_KEY="$EP_KEY"

export MINI_CONFIG_INTERACTIVE=0
# litellm has no cost table for local model ids; without this it raises
# instead of just skipping cost tracking.
export MSWEA_COST_TRACKING=ignore_errors

PREFIXED_MODEL_ID="openai/${BARE_MODEL_ID}"

if [ ! -t 0 ]; then
  TASK="$(cat)"
  # agent.mode defaults to "confirm" (interactive per-step approval), which
  # hangs forever with stdin piped. yolo runs unattended.
  exec mini-swe-agent \
    --model "${PREFIXED_MODEL_ID}" \
    -c mini.yaml -c agent.mode=yolo \
    --exit-immediately \
    --task "$TASK"
else
  exec mini-swe-agent \
    --model "${PREFIXED_MODEL_ID}"
fi
