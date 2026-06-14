#!/usr/bin/env bash
# Adapter: Claude Code CLI -> LM Studio (OpenAI-compatible local server).
# Runs the `claude` CLI pointed at LM Studio's /v1/messages endpoint instead of
# the Anthropic API. The ANTHROPIC_BASE_URL trick makes Claude Code treat LM Studio
# as a drop-in backend.
#
# All three model tiers (haiku/sonnet/opus) are mapped to the same $MODEL_ID so
# Claude Code's internal tool-selection routing doesn't accidentally call the
# real Anthropic API for sub-tasks.
#
# Requires: CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 to suppress feature flags
# that LM Studio's OpenAI server may not implement.
#
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

CLAUDE_ARGS=(--allow-dangerously-skip-permissions)
if [ ! -t 0 ]; then
  CLAUDE_ARGS+=(--print --bare "$(cat)")
fi

exec env \
  ANTHROPIC_BASE_URL="$LMS_BASE_URL" \
  ANTHROPIC_AUTH_TOKEN="$LMS_API_KEY" \
  ANTHROPIC_API_KEY="$LMS_API_KEY" \
  ANTHROPIC_MODEL="$MODEL_ID" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$MODEL_ID" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$MODEL_ID" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$MODEL_ID" \
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1" \
  claude "${CLAUDE_ARGS[@]}" "$@"
