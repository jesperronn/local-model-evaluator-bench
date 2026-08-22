#!/usr/bin/env bash
# Adapter: Claude Code CLI -> unified endpoint via provider routing.
# Routes to different local runtimes (lms, ollama, mlx, omlx) via ANTHROPIC_BASE_URL.
# The ANTHROPIC_BASE_URL trick makes Claude Code treat local servers as drop-in backends.
#
# Adapter accepts --provider to select which backend to target:
#   --provider lms        # route to LM Studio
#   --provider ollama     # route to Ollama
#   --provider omlx       # route to oMLX
#   --provider mlx        # route to mlx_lm.server
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

command -v claude >/dev/null 2>&1 || {
  echo "claude not found; install: npm install -g @anthropic-ai/claude-cli" >&2
  exit 1
}

# Map provider to base URL. Claude Code's Stainless SDK appends /v1/messages,
# so we pass the base without the /v1 suffix.
case "$PROVIDER" in
  lms)
    CLAUDE_BASE_URL="${LMS_BASE_URL%/v1}"
    AUTH_TOKEN="$LMS_API_KEY"
    ;;
  ollama)
    CLAUDE_BASE_URL="http://localhost:11434"
    AUTH_TOKEN="ollama"
    ;;
  omlx)
    CLAUDE_BASE_URL="${OMLX_BASE_URL%/v1}"
    AUTH_TOKEN="$OMLX_API_KEY"
    ;;
  mlx)
    CLAUDE_BASE_URL="http://localhost:8080"
    AUTH_TOKEN="mlx"
    ;;
  *)
    if [ ! -t 0 ]; then cat > /dev/null; fi  # drain stdin when piped
    echo "claude: unknown provider '$PROVIDER' (valid: lms, ollama, omlx, mlx)" >&2
    exit 1
    ;;
esac

CLAUDE_ARGS=()
if [ ! -t 0 ]; then
  # Bench-only: skip permission prompts so the agent runs unattended in the sandbox.
  # Only active when stdin is piped (non-interactive). Interactive sessions never set this.
  SKIP_PERMS="--allow-dangerously-skip-permissions"
  CLAUDE_ARGS+=($SKIP_PERMS --print --bare "$(cat)")
fi

exec env \
  ANTHROPIC_BASE_URL="$CLAUDE_BASE_URL" \
  ANTHROPIC_AUTH_TOKEN="$AUTH_TOKEN" \
  ANTHROPIC_API_KEY="$AUTH_TOKEN" \
  ANTHROPIC_MODEL="$MODEL_ID" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$MODEL_ID" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$MODEL_ID" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$MODEL_ID" \
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1" \
  claude "${CLAUDE_ARGS[@]}" "$@"
