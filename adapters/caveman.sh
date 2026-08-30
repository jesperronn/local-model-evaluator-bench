#!/usr/bin/env bash
# Adapter: caveman -> unified endpoint via LiteLLM proxy.
# Routes through the LiteLLM proxy ($LITELLM_BASE_URL) to any local runtime
# (lms, ollama, omlx, mtplx) based on model ID prefix.
# Note: mlx is not supported by caveman's current implementation.
#
# The proxy must be running: bin/litellm-proxy start
# Model IDs are prefixed by provider: lms/<id>, ollama/<id>, omlx/<id>, mtplx/<id>
#
# Adapter accepts --provider to override which backend to target:
#   --provider lms        # route to LM Studio (default if lms/ prefix)
#   --provider ollama     # route to Ollama
#   --provider omlx       # route to oMLX
#   --provider mtplx      # route to MTPLX
#
# Install: npm install -g @juliusbrussee/caveman-code
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

command -v caveman >/dev/null 2>&1 || {
  echo "caveman not found; install: npm install -g @juliusbrussee/caveman-code" >&2
  exit 1
}

# Validate provider
case "$PROVIDER" in
  lms|ollama|omlx|mtplx)
    # These are supported
    ;;
  mlx)
    if [ ! -t 0 ]; then cat > /dev/null; fi
    echo "caveman: skipped — MLX not supported by caveman" >&2
    exit 1
    ;;
  *)
    if [ ! -t 0 ]; then cat > /dev/null; fi
    echo "caveman: unknown provider '$PROVIDER' (valid: lms, ollama, omlx)" >&2
    exit 1
    ;;
esac

# Prefix the model ID with the provider name if not already prefixed.
if [[ "$MODEL_ID" =~ ^(lms|ollama|omlx|mtplx)/ ]]; then
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# Caveman doesn't support --api-base via CLI, so configure via environment variables
# that caveman may use for OpenAI-compatible endpoints.
export CAVEMAN_API_KEY="${LITELLM_MASTER_KEY:-litellm}"
export CAVEMAN_API_BASE="$LITELLM_BASE_URL"
export CAVEMAN_MODEL="$PREFIXED_MODEL_ID"

# Also set standard OpenAI env vars in case caveman uses those
export OPENAI_API_KEY="${LITELLM_MASTER_KEY:-litellm}"
export OPENAI_API_BASE="$LITELLM_BASE_URL"

CAVEMAN_ARGS=(
  --model "$PREFIXED_MODEL_ID"
)

if [ ! -t 0 ]; then
  exec caveman "${CAVEMAN_ARGS[@]}" --print "$(cat)"
else
  exec caveman "${CAVEMAN_ARGS[@]}" "$@"
fi
