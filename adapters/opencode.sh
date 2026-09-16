#!/usr/bin/env bash
# Adapter: opencode -> unified endpoint via LiteLLM proxy.
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
# opencode reads the provider baseURL from ~/.config/opencode/opencode.json
# (lmstudio provider for lms, ollama for ollama, etc.).
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

command -v opencode >/dev/null 2>&1 || {
  echo "opencode not found; install via package manager" >&2
  exit 1
}

# Determine which runtime to use based on model prefix or naming.
# Configure environment variables that opencode uses to reach its configured providers.
if [[ "$MODEL_ID" =~ ^omlx/ ]] || [[ "$MODEL_ID" == "Ornith"* ]]; then
  export LITELLM_BASE_URL="$OMLX_BASE_URL"
  export LITELLM_API_KEY="$OMLX_API_KEY"
  # For opencode's model reference, use omlx prefix
  PREFIXED_MODEL_ID="omlx/${MODEL_ID#omlx/}"
elif [[ "$MODEL_ID" =~ ^lms/ ]]; then
  export LITELLM_BASE_URL="$LMS_BASE_URL"
  export LITELLM_API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="lmstudio/${MODEL_ID#lms/}"
elif [[ "$LITELLM_PROXY_MODE" == "1" ]]; then
  export LITELLM_BASE_URL="${LITELLM_BASE_URL:-http://127.0.0.1:4444/v1}"
  export LITELLM_API_KEY="$LITELLM_MASTER_KEY"
  # Prefix the model ID with the provider name if not already prefixed
  if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai|lmstudio)/ ]]; then
    PREFIXED_MODEL_ID="$MODEL_ID"
  else
    if [ "$PROVIDER" = "lms" ]; then
      PREFIXED_MODEL_ID="lmstudio/${MODEL_ID}"
    else
      PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
    fi
  fi
else
  # Default to LMS when proxy disabled
  export LITELLM_BASE_URL="$LMS_BASE_URL"
  export LITELLM_API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="lmstudio/${MODEL_ID#lms/}"
fi

if [ -t 0 ]; then
  exec opencode --model "$PREFIXED_MODEL_ID" "$@"
else
  # Prepend CWD so the model uses real paths instead of /path/to/... placeholders.
  PROMPT="Working directory: $(pwd)

$(cat)"
  exec opencode run --model "$PREFIXED_MODEL_ID" "${PROMPT}" "$@"
fi
