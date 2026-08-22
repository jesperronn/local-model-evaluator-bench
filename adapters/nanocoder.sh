#!/usr/bin/env bash
# Adapter: nanocoder -> unified endpoint via LiteLLM proxy.
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
# Provider config is injected via NANOCODER_PROVIDERS env var (JSON) so no config file is needed.
# Non-interactive runs use `nanocoder run` (auto-detected via stdin check).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"
PROVIDER="${PROVIDER:-lms}"

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

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# Inject LiteLLM proxy provider config so bench runs are self-contained.
# contextWindow must be set explicitly for local models (nanocoder falls back to
# models.dev metadata which won't have entries for local model keys).
PROVIDER_JSON=$(cat <<EOF
[{
  "name": "LiteLLM",
  "baseUrl": "${LITELLM_BASE_URL}",
  "models": ["${PREFIXED_MODEL_ID}"],
  "contextWindow": 65536
}]
EOF
)

if [ -t 0 ]; then
  exec env NANOCODER_PROVIDERS="${PROVIDER_JSON}" \
    nanocoder --provider "LiteLLM" --model "${PREFIXED_MODEL_ID}" "$@"
else
  PROMPT="Working directory: $(pwd)

$(cat)"
  exec env NANOCODER_PROVIDERS="${PROVIDER_JSON}" NANOCODER_TRUST_DIRECTORY=1 \
    nanocoder run --provider "LiteLLM" --model "${PREFIXED_MODEL_ID}" "${PROMPT}" "$@"
fi
