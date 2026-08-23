#!/usr/bin/env bash
# Adapter: GitHub Copilot CLI -> unified endpoint via LiteLLM proxy.
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
# COPILOT_PROVIDER_BASE_URL redirects all model calls to the LiteLLM proxy's
# OpenAI-compatible endpoint, bypassing GitHub's Copilot service entirely.
# COPILOT_OFFLINE=true prevents the CLI from phoning home to GitHub.
# Docs: https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-byok-models
#
# COPILOT_PROVIDER_MODEL_ID=gpt-4o: a well-known catalog entry copilot uses to
# resolve token limits and agent config. The actual model sent to the proxy is in
# COPILOT_PROVIDER_WIRE_MODEL; the catalog entry is only for sizing defaults.
#
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

COPILOT_ARGS=()
if [ ! -t 0 ]; then
  COPILOT_ARGS+=(--allow-all-tools --allow-all-paths --no-ask-user -p "$(cat)")
fi

exec env \
  COPILOT_PROVIDER_BASE_URL="$LITELLM_BASE_URL" \
  COPILOT_PROVIDER_TYPE="openai" \
  COPILOT_PROVIDER_API_KEY="$LITELLM_MASTER_KEY" \
  COPILOT_PROVIDER_MODEL_ID="gpt-4o" \
  COPILOT_PROVIDER_WIRE_MODEL="$PREFIXED_MODEL_ID" \
  COPILOT_OFFLINE="true" \
  copilot "${COPILOT_ARGS[@]}" "$@"
