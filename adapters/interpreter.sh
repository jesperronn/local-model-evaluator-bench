#!/usr/bin/env bash
# Adapter: interpreter (Open Interpreter) -> unified endpoint via LiteLLM proxy.
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
# Install: pip install open-interpreter
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

command -v interpreter >/dev/null 2>&1 || {
  echo "interpreter not found; install: pip install open-interpreter" >&2
  exit 1
}

# Determine which runtime to use based on model prefix or naming.
# Open Interpreter uses OpenAI-compatible configuration via OPENAI_* env vars.
if [[ "$MODEL_ID" =~ ^omlx/ ]] || [[ "$MODEL_ID" == "Ornith"* ]]; then
  export OPENAI_BASE_URL="$OMLX_BASE_URL"
  export OPENAI_API_KEY="$OMLX_API_KEY"
  PREFIXED_MODEL_ID="$MODEL_ID"
elif [[ "$MODEL_ID" =~ ^lms/ ]]; then
  export OPENAI_BASE_URL="$LMS_BASE_URL"
  export OPENAI_API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="$MODEL_ID"
elif [[ "$LITELLM_PROXY_MODE" == "1" ]]; then
  export OPENAI_BASE_URL="$LITELLM_BASE_URL"
  export OPENAI_API_KEY="$LITELLM_MASTER_KEY"
  # Prefix the model ID with the provider name for litellm proxy
  if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx)/ ]]; then
    PREFIXED_MODEL_ID="$MODEL_ID"
  else
    PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
  fi
else
  # Default to LMS when proxy disabled
  export OPENAI_BASE_URL="$LMS_BASE_URL"
  export OPENAI_API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="$MODEL_ID"
fi

# Open Interpreter uses OpenAI-compatible configuration via environment variables.
OI_CONFIG=(
  -c "model=\"$PREFIXED_MODEL_ID\""
)

if [ ! -t 0 ]; then
  exec interpreter exec -s workspace-write "${OI_CONFIG[@]}" "$(cat)"
else
  exec interpreter "${OI_CONFIG[@]}" "$@"
fi
