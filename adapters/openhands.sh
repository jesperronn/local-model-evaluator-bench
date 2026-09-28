#!/usr/bin/env bash
# Adapter: openhands -> unified endpoint via Olla proxy (OpenAI format).
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
# openhands bundles litellm client-side, which REQUIRES a provider prefix
# (openai/, ollama/, etc.) to parse the model name — the bare id is wrapped
# in "openai/" below to satisfy that client-side check.
#
# Install: uv tool install openhands
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v openhands >/dev/null 2>&1 || {
  echo "openhands not found; install: uv tool install openhands" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# Set environment variables to route through Olla.
export LLM_API_KEY="$OLLA_API_KEY"
export LLM_BASE_URL="$OLLA_BASE_URL"
export LLM_MODEL="openai/${BARE_MODEL_ID}"
export OPENHANDS_SUPPRESS_BANNER=1

# Ensure openhands is on PATH (uv tool install puts it in ~/.local/bin)
export PATH="$HOME/.local/bin:$PATH"

# openhands hardcodes its tmux socket name to "openhands" (see
# openhands.tools.terminal.constants.TMUX_SOCKET_NAME) — not configurable.
# Concurrent trials (bin/bench runs several sandboxes in parallel) all land
# on that same socket and fight over the tmux server, producing
# "tmux set-environment stderr: ['server exited unexpectedly'/'no server
# running']". Give each trial its own TMUX_TMPDIR so the shared name stops
# colliding. Must stay short and outside the (deep) sandbox path: unix
# socket paths are capped at ~104 bytes on macOS, and a sandbox path under
# results/<run>/sandbox/... overflows that ("File name too long").
export TMUX_TMPDIR="${TMPDIR:-/tmp}/oh-tmux-$$"
mkdir -p "$TMUX_TMPDIR"

if [ ! -t 0 ]; then
  TASK="$(cat)"
  exec openhands \
    --headless \
    --task "$TASK" \
    --override-with-envs \
    "$@"
else
  exec openhands \
    --override-with-envs \
    "$@"
fi
