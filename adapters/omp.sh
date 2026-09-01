#!/usr/bin/env bash
# Adapter: omp (oh-my-pi) -> unified endpoint via LiteLLM proxy.
# Routes through omp's built-in "litellm" provider (LITELLM_BASE_URL/
# LITELLM_API_KEY): omp autodiscovers every model LiteLLM serves and matches
# it by "<runtime>/<model>" id, so no adapter-side "litellm/" prefix needed.
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
# Install: npm install -g <omp-package>
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

command -v omp >/dev/null 2>&1 || {
  echo "omp not found; install: npm install -g <omp-package>" >&2
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

# omp v18+ ignores OPENAI_API_BASE/OPENAI_API_KEY for custom model ids — it
# routes through its own built-in "litellm" provider instead, which reads
# LITELLM_BASE_URL/LITELLM_API_KEY. omp requires a non-empty key value.
export LITELLM_BASE_URL="${LITELLM_BASE_URL:-http://127.0.0.1:4444/v1}"
export LITELLM_API_KEY="${LITELLM_MASTER_KEY:-litellm}"

OMP_ARGS=(--model "$PREFIXED_MODEL_ID")

if [ ! -t 0 ]; then
  exec omp "${OMP_ARGS[@]}" -p "$(cat)"
else
  exec omp "${OMP_ARGS[@]}" "$@"
fi
