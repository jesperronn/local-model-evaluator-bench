#!/usr/bin/env bash
# Adapter: goose (Block Goose) -> unified endpoint via LiteLLM proxy.
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
# Uses the openai provider with OPENAI_BASE_URL pointing at LITELLM_BASE_URL.
# --with-builtin developer enables file read/write tool calls.
# --no-session (goose run only) prevents goose from storing state between
# benchmark runs. `goose session` has no such flag — it always keeps state.
# --max-turns caps iterations to avoid hangs on self-verify cases.
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

command -v goose >/dev/null 2>&1 || {
  echo "goose not found; install: npm install -g @block-foundation/block-goose-cli or equivalent" >&2
  exit 1
}

# Determine which runtime to use based on model prefix or naming.
# goose uses OpenAI-compatible endpoints via OPENAI_* env vars.
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

export GOOSE_PROVIDER=openai
export GOOSE_MODEL="$PREFIXED_MODEL_ID"

GOOSE_ARGS=(
  --with-builtin developer
  --max-turns 30
)

if [ ! -t 0 ]; then
  exec goose run -i - --no-session "${GOOSE_ARGS[@]}"
else
  exec goose session "${GOOSE_ARGS[@]}" "$@"
fi
