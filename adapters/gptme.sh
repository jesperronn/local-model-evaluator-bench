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

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx)/ ]]; then
  RUNTIME_PREFIXED_ID="$MODEL_ID"
else
  RUNTIME_PREFIXED_ID="${PROVIDER}/${MODEL_ID}"
fi

# gptme's litellm client only recognizes "openai/" as a provider prefix, so the
# runtime tag (omlx/, mtplx/, ...) must stay in the model name itself rather
# than being stripped — otherwise the litellm proxy's model_name wildcard
# (config-templates/litellm.yaml matches on "omlx/*" etc.) never matches a bare
# name and the request 400s with "no healthy deployments for this model" (seen
# 2026-08-29 on Ornith-1.5-35B-A3B-MLX-4bit/omlx). Wrapping the already-
# runtime-prefixed id in another "openai/" layer satisfies gptme's client-side
# check while still sending the original runtime-prefixed id on the wire.
GPTME_MODEL="openai/${RUNTIME_PREFIXED_ID}"

export OPENAI_BASE_URL="$LITELLM_BASE_URL"
export OPENAI_API_KEY="${LITELLM_MASTER_KEY:-litellm}"

# gptme requires the Python bin to be on PATH
export PATH="/Users/jesper/Library/Python/3.14/bin:$PATH"

# --no-confirm: skip interactive approval prompts in headless mode.
# --workspace .: tells gptme the project root is CWD.
# gptme uses "openai" provider by default when OPENAI_* env vars are set.
if [ ! -t 0 ]; then
  exec gptme \
    --model "${GPTME_MODEL}" \
    --workspace "$(pwd)" \
    --no-confirm \
    "$(cat)"
else
  exec gptme \
    --model "${GPTME_MODEL}" \
    --workspace "$(pwd)" \
    "$@"
fi
