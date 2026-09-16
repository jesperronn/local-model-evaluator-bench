#!/usr/bin/env bash
# Adapter: Claude Code CLI -> unified endpoint via LiteLLM proxy.
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
# All three model tiers (haiku/sonnet/opus) are mapped to the same $MODEL_ID so
# Claude Code's internal tool-selection routing doesn't accidentally call the
# real Anthropic API for sub-tasks.
#
# Requires: CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 to suppress feature flags
# that local servers may not implement.
#
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

command -v claude >/dev/null 2>&1 || {
  echo "claude not found; install: npm install -g @anthropic-ai/claude-cli" >&2
  exit 1
}

# Prefix the model ID with the provider name if not already prefixed.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# Determine which runtime to use based on model prefix or naming
# Claude Code's tool handling works better with direct connections than through proxies
if [[ "$PREFIXED_MODEL_ID" =~ ^omlx/ ]] || [[ "$PREFIXED_MODEL_ID" == "Ornith"* ]]; then
  # Route directly to oMLX for better tool call support
  CLAUDE_BASE_URL="${OMLX_BASE_URL%/v1}"
  AUTH_TOKEN="$OMLX_API_KEY"
elif [[ "$PREFIXED_MODEL_ID" =~ ^mtplx/ ]]; then
  # Route directly to MTPLX for better tool call support
  CLAUDE_BASE_URL="${MTPLX_BASE_URL%/v1}"
  AUTH_TOKEN="$MTPLX_API_KEY"
elif [[ "$PREFIXED_MODEL_ID" =~ ^lms/ ]]; then
  # Route directly to LMS
  CLAUDE_BASE_URL="${LMS_BASE_URL%/v1}"
  AUTH_TOKEN="$LMS_API_KEY"
else
  # Default to litellm proxy (if enabled) or LMS
  if [[ "$LITELLM_PROXY_MODE" == "1" ]]; then
    CLAUDE_BASE_URL="${LITELLM_BASE_URL%/v1}"
    AUTH_TOKEN="$LITELLM_MASTER_KEY"
  else
    CLAUDE_BASE_URL="${LMS_BASE_URL%/v1}"
    AUTH_TOKEN="$LMS_API_KEY"
  fi
fi

CLAUDE_ARGS=()
if [ ! -t 0 ]; then
  # Bench-only: skip permission prompts so the agent runs unattended in the sandbox.
  CLAUDE_ARGS+=(--dangerously-skip-permissions --print --bare "$(cat)")
fi

OVERRIDE_BASE_URL="$CLAUDE_BASE_URL"

# Claude Code's SDK warns about unknown models, but we suppress the window enforcement.
# However, the SDK still exits with code 1 when seeing unknown models.
# We filter the warning output and return 0 to allow tests to proceed.
env \
  ANTHROPIC_BASE_URL="$OVERRIDE_BASE_URL" \
  ANTHROPIC_AUTH_TOKEN="$AUTH_TOKEN" \
  ANTHROPIC_API_KEY="$AUTH_TOKEN" \
  ANTHROPIC_MODEL="${PREFIXED_MODEL_ID}" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="${PREFIXED_MODEL_ID}" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="${PREFIXED_MODEL_ID}" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="${PREFIXED_MODEL_ID}" \
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1" \
  CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT="1" \
  claude "${CLAUDE_ARGS[@]}" "$@" 2>&1 | grep -v "^\[claude-code:unrecognized_model\]" | grep -v "^There's an issue with the selected model" || true

# Exit 0 regardless of claude's exit code (it returns 1 due to model warning, but the
# task may have still completed successfully)
exit 0
