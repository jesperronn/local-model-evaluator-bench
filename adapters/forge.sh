#!/usr/bin/env bash
# Adapter: forge -> unified endpoint via LiteLLM proxy.
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
# Install: npm install -g @hoangsonw/forge
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

command -v forge >/dev/null 2>&1 || {
  echo "forge not found; install: npm install -g @hoangsonw/forge" >&2
  exit 1
}

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# Extract the model name part (without provider prefix) for forge
FORGE_MODEL="${PREFIXED_MODEL_ID##*/}"

# Set up the OpenAI-compatible endpoint to point to the LiteLLM proxy
export OPENAI_BASE_URL="$LITELLM_BASE_URL"
export OPENAI_API_KEY="${LITELLM_MASTER_KEY:-default}"

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
