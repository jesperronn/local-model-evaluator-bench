#!/usr/bin/env bash
# Adapter: gptme -> unified endpoint via LiteLLM proxy.
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
# gptme uses OPENAI_BASE_URL + OPENAI_API_KEY for any openai-compatible backend.
# Install: pip install gptme
# Contract: CWD is the sandbox to edit. Prompt arrives on stdin. $MODEL_ID set.
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

command -v gptme >/dev/null 2>&1 || {
  echo "gptme not found; install: pip install gptme" >&2
  exit 1
}

# Determine which runtime to use based on model prefix or naming
if [[ "$MODEL_ID" =~ ^omlx/ ]] || [[ "$MODEL_ID" == "Ornith"* ]]; then
  RUNTIME_ENDPOINT="$OMLX_BASE_URL"
  RUNTIME_API_KEY="$OMLX_API_KEY"
  RUNTIME_PREFIXED_ID="$MODEL_ID"
elif [[ "$MODEL_ID" =~ ^lms/ ]]; then
  RUNTIME_ENDPOINT="$LMS_BASE_URL"
  RUNTIME_API_KEY="$LMS_API_KEY"
  RUNTIME_PREFIXED_ID="$MODEL_ID"
elif [[ "$LITELLM_PROXY_MODE" == "1" ]]; then
  RUNTIME_ENDPOINT="$LITELLM_BASE_URL"
  RUNTIME_API_KEY="$LITELLM_MASTER_KEY"
  # For litellm proxy: keep the runtime prefix in the model name (see old comment below)
  RUNTIME_PREFIXED_ID="${PROVIDER}/${MODEL_ID}"
else
  # Default to LMS when proxy disabled
  RUNTIME_ENDPOINT="$LMS_BASE_URL"
  RUNTIME_API_KEY="$LMS_API_KEY"
  RUNTIME_PREFIXED_ID="$MODEL_ID"
fi

# gptme's client only recognizes "openai/" as a provider prefix, so wrap the model id
GPTME_MODEL="openai/${RUNTIME_PREFIXED_ID}"

export OPENAI_BASE_URL="$RUNTIME_ENDPOINT"
export OPENAI_API_KEY="$RUNTIME_API_KEY"

# gptme requires the Python bin to be on PATH
export PATH="/Users/jesper/Library/Python/3.14/bin:$PATH"

# --no-confirm: skip interactive approval prompts in headless mode.
# --workspace .: tells gptme the project root is CWD.
# --system: custom system prompt that guides the model to use 'save' for file edits
#   instead of 'append', preventing file duplication issues.
# gptme uses "openai" provider by default when OPENAI_* env vars are set.
SYSTEM_PROMPT="When editing files: use 'save' to write the complete file with corrections. Use 'append' only to add new content at the end. Never append a complete file replacement—use 'save' instead."

if [ ! -t 0 ]; then
  exec gptme \
    --model "${GPTME_MODEL}" \
    --workspace "$(pwd)" \
    --no-confirm \
    --system "$SYSTEM_PROMPT" \
    "$(cat)"
else
  exec gptme \
    --model "${GPTME_MODEL}" \
    --workspace "$(pwd)" \
    --system "$SYSTEM_PROMPT" \
    "$@"
fi
