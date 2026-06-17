#!/usr/bin/env bash
# Adapter: Claude Code CLI -> Ollama.
# Runs the `claude` CLI pointed at a local Ollama instance instead of the
# Anthropic API. The ANTHROPIC_BASE_URL trick (documented at
# https://www.kdnuggets.com/local-agentic-programming-on-the-cheap-claude-code-ollama-gemma4)
# makes Claude Code treat Ollama's /v1/messages endpoint as a drop-in backend.
#
# All three model tiers (haiku/sonnet/opus) are mapped to the same $MODEL_ID so
# Claude Code's internal tool-selection routing doesn't accidentally call the
# real Anthropic API for sub-tasks.
#
# Requires: CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 to suppress feature flags
# that Ollama doesn't implement.
#
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

CLAUDE_ARGS=()
if [ ! -t 0 ]; then
  CLAUDE_ARGS+=(--allow-dangerously-skip-permissions --print --bare "$(cat)")
fi

exec env \
  ANTHROPIC_BASE_URL="http://localhost:11434" \
  ANTHROPIC_AUTH_TOKEN="ollama" \
  ANTHROPIC_API_KEY="ollama" \
  ANTHROPIC_MODEL="$MODEL_ID" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$MODEL_ID" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$MODEL_ID" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$MODEL_ID" \
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1" \
  claude "${CLAUDE_ARGS[@]}" "$@"
