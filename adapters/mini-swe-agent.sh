#!/usr/bin/env bash
# Adapter: mini-swe-agent -> unified endpoint via LiteLLM proxy.
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
# Install: python3 -m pip install --break-system-packages mini-swe-agent
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

# mini-swe-agent v2 requires the Python bin to be on PATH
export PATH="/Users/jesper/Library/Python/3.14/bin:$PATH"

# Determine which runtime to use based on model prefix or naming.
# mini-swe-agent uses OpenAI-compatible endpoints via OPENAI_* env vars.
if [[ "$MODEL_ID" =~ ^omlx/ ]] || [[ "$MODEL_ID" == "Ornith"* ]]; then
  export OPENAI_API_BASE="$OMLX_BASE_URL"
  export OPENAI_API_KEY="$OMLX_API_KEY"
  PREFIXED_MODEL_ID="$MODEL_ID"
elif [[ "$MODEL_ID" =~ ^lms/ ]]; then
  export OPENAI_API_BASE="$LMS_BASE_URL"
  export OPENAI_API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="$MODEL_ID"
elif [[ "$LITELLM_PROXY_MODE" == "1" ]]; then
  export OPENAI_API_BASE="$LITELLM_BASE_URL"
  export OPENAI_API_KEY="$LITELLM_MASTER_KEY"
  # Prefix the model ID with the provider name for litellm proxy
  if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
    PREFIXED_MODEL_ID="$MODEL_ID"
  else
    PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
  fi
else
  # Default to LMS when proxy disabled
  export OPENAI_API_BASE="$LMS_BASE_URL"
  export OPENAI_API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="$MODEL_ID"
fi

export MINI_CONFIG_INTERACTIVE=0
# litellm has no cost table for local model ids; without this it raises
# instead of just skipping cost tracking.
export MSWEA_COST_TRACKING=ignore_errors

# mini-swe-agent's bundled litellm client parses --model before any network
# call, and only recognizes litellm's built-in provider registry — our runtime
# prefixes (omlx/, mtplx/, ...) throw `LLM Provider NOT provided` before ever
# reaching the litellm proxy (same root cause as adapters/aider.sh, see its
# comment). Wrapping the already-prefixed id in another "openai/" layer
# satisfies litellm's client-side check while still sending the original
# runtime-prefixed id on the wire, which is what the proxy's wildcard routes
# match on.
if [[ ! "$PREFIXED_MODEL_ID" =~ ^openai/ ]]; then
  PREFIXED_MODEL_ID="openai/${PREFIXED_MODEL_ID}"
fi

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
