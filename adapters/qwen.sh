#!/usr/bin/env bash
# Adapter: qwen (Qwen Code CLI) -> unified endpoint via LiteLLM proxy.
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
# Qwen Code's "openai" auth type uses OPENAI_API_KEY/OPENAI_BASE_URL/OPENAI_MODEL
# for routing. Three env vars disable telemetry calls to Alibaba:
#   - QWEN_USAGE_STATISTICS_ENABLED=false: disables qwen-logger.ts telemetry
#   - QWEN_CODE_DISABLE_PRECONNECT=1: disables preconnect HEAD-requests
#   - QWEN_CODE_SKIP_UPDATE_CHECK_ONCE=true: skips update check
#
# Install: npm install -g @qwen-code/qwen-code
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

command -v qwen >/dev/null 2>&1 || {
  echo "qwen not found; install: npm install -g @qwen-code/qwen-code" >&2
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

# Set environment variables to route through the LiteLLM proxy.
# LiteLLM does not require a key for localhost access unless LITELLM_MASTER_KEY is set.
export OPENAI_API_KEY="${LITELLM_MASTER_KEY:-litellm}"
export OPENAI_BASE_URL="$LITELLM_BASE_URL"
export OPENAI_MODEL="$PREFIXED_MODEL_ID"
export QWEN_CODE_SUPPRESS_YOLO_WARNING=1
export QWEN_CODE_SKIP_UPDATE_CHECK_ONCE=true
export QWEN_CODE_DISABLE_PRECONNECT=1
export QWEN_USAGE_STATISTICS_ENABLED=false

QWEN_ARGS=(--model "$PREFIXED_MODEL_ID" --approval-mode yolo)

if [ ! -t 0 ]; then
  exec qwen "${QWEN_ARGS[@]}" -p "$(cat)"
else
  exec qwen "${QWEN_ARGS[@]}" "$@"
fi
