#!/usr/bin/env bash
# Adapter: Claude Code CLI -> unified endpoint via Olla proxy (Anthropic format).
# Routes ONLY through Olla's native Anthropic Messages route
# ($OLLA_ANTHROPIC_BASE_URL) — see docs/runtimes/olla.md "Adapter wiring" for
# the pattern this adapter follows. Olla auto-discovers every backend's
# models (omlx, mtplx, lms, ollama) under one unified list, so no
# runtime-prefix branching and no per-backend base-URL selection are needed
# here (unlike the old LiteLLM/direct-runtime version of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
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

command -v claude >/dev/null 2>&1 || {
  echo "claude not found; install: npm install -g @anthropic-ai/claude-cli" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

CLAUDE_ARGS=()
if [ ! -t 0 ]; then
  # Bench-only: skip permission prompts so the agent runs unattended in the sandbox.
  CLAUDE_ARGS+=(--dangerously-skip-permissions --print --bare "$(cat)")
fi

# Claude Code's SDK warns about unknown models, but we suppress the window enforcement.
# However, the SDK still exits with code 1 when seeing unknown models.
# We filter the warning output and return 0 to allow tests to proceed.
env \
  ANTHROPIC_BASE_URL="$OLLA_ANTHROPIC_BASE_URL" \
  ANTHROPIC_AUTH_TOKEN="$OLLA_API_KEY" \
  ANTHROPIC_API_KEY="$OLLA_API_KEY" \
  ANTHROPIC_MODEL="${BARE_MODEL_ID}" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="${BARE_MODEL_ID}" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="${BARE_MODEL_ID}" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="${BARE_MODEL_ID}" \
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1" \
  CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT="1" \
  claude "${CLAUDE_ARGS[@]}" "$@" 2>&1 | grep -v "^\[claude-code:unrecognized_model\]" | grep -v "^There's an issue with the selected model" || true

# Exit 0 regardless of claude's exit code (it returns 1 due to model warning, but the
# task may have still completed successfully)
exit 0
