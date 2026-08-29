#!/usr/bin/env bash
# Adapter: openhands -> unified endpoint via LiteLLM proxy.
# Routes through the LiteLLM proxy ($LITELLM_BASE_URL) to any local runtime
# (lms, ollama, mlx, omlx, mtplx) based on model ID prefix.
#
# The proxy must be running: bin/litellm-proxy start
# Model IDs are prefixed by provider: lms/<id>, ollama/<id>, omlx/<id>, mlx/<id>, mtplx/<id>
#
# Adapter accepts --provider to override which backend to target:
#   --provider lms        # route to LM Studio (default if lms/ prefix)
#   --provider ollama     # route to Ollama
#   --provider omlx       # route to oMLX
#   --provider mlx        # route to mlx_lm.server
#   --provider mtplx      # route to MTPLX
#
# Install: uv tool install openhands
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"
PROVIDER="${PROVIDER:-${RUNTIME:-lms}}"

# Parse --provider flag if passed
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

command -v openhands >/dev/null 2>&1 || {
  echo "openhands not found; install: uv tool install openhands" >&2
  exit 1
}

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# Set environment variables to route through the LiteLLM proxy.
# LiteLLM does not require a key for localhost access unless LITELLM_MASTER_KEY is set.
export LLM_API_KEY="${LITELLM_MASTER_KEY:-litellm}"
export LLM_BASE_URL="$LITELLM_BASE_URL"
export LLM_MODEL="$PREFIXED_MODEL_ID"
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
