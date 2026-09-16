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

# Determine which runtime to use based on model prefix or naming.
# openhands uses OpenAI-compatible endpoints via LLM_* env vars.
if [[ "$MODEL_ID" =~ ^omlx/ ]] || [[ "$MODEL_ID" == "Ornith"* ]]; then
  API_BASE="$OMLX_BASE_URL"
  API_KEY="$OMLX_API_KEY"
  PREFIXED_MODEL_ID="$MODEL_ID"
elif [[ "$MODEL_ID" =~ ^lms/ ]]; then
  API_BASE="$LMS_BASE_URL"
  API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="$MODEL_ID"
elif [[ "$LITELLM_PROXY_MODE" == "1" ]]; then
  API_BASE="$LITELLM_BASE_URL"
  API_KEY="$LITELLM_MASTER_KEY"
  # Prefix the model ID with the provider name for litellm proxy
  if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
    PREFIXED_MODEL_ID="$MODEL_ID"
  else
    PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
  fi
  # Wrap in openai/ for openhands' client check
  if [[ ! "$PREFIXED_MODEL_ID" =~ ^openai/ ]]; then
    PREFIXED_MODEL_ID="openai/${PREFIXED_MODEL_ID}"
  fi
else
  # Default to LMS when proxy disabled
  API_BASE="$LMS_BASE_URL"
  API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="$MODEL_ID"
  # Wrap in openai/ for openhands' client check
  if [[ ! "$PREFIXED_MODEL_ID" =~ ^openai/ ]]; then
    PREFIXED_MODEL_ID="openai/${PREFIXED_MODEL_ID}"
  fi
fi

# Set environment variables to route through the appropriate runtime.
export LLM_API_KEY="$API_KEY"
export LLM_BASE_URL="$API_BASE"
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
