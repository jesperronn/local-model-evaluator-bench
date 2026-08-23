#!/usr/bin/env bash
# Adapter: mini-swe-agent -> unified endpoint via LiteLLM proxy.
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
# Install: python3 -m pip install --break-system-packages mini-swe-agent
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

# mini-swe-agent v2 requires the Python bin to be on PATH
export PATH="/Users/jesper/Library/Python/3.14/bin:$PATH"

export OPENAI_API_BASE="$LITELLM_BASE_URL"
export OPENAI_API_KEY="$LITELLM_MASTER_KEY"
export MINI_CONFIG_INTERACTIVE=0
# litellm has no cost table for local model ids; without this it raises
# instead of just skipping cost tracking.
export MSWEA_COST_TRACKING=ignore_errors

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

if [ ! -t 0 ]; then
  TASK="$(cat)"
  # agent.mode defaults to "confirm" (interactive per-step approval), which
  # hangs forever with stdin piped. yolo runs unattended.
  exec mini-swe-agent \
    --model "${PREFIXED_MODEL_ID}" \
    -c mini.yaml -c agent.mode=yolo \
    --exit-immediately \
    --task "$TASK"
else
  exec mini-swe-agent \
    --model "${PREFIXED_MODEL_ID}"
fi
