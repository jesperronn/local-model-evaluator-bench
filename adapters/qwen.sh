#!/usr/bin/env bash
# Adapter: qwen (Qwen Code CLI) -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching, no --provider flag, and no direct-runtime
# base-URL selection are needed here (unlike the old LiteLLM-routed version
# of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
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

command -v qwen >/dev/null 2>&1 || {
  echo "qwen not found; install: npm install -g @qwen-code/qwen-code" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

export OPENAI_BASE_URL="$OLLA_BASE_URL"
export OPENAI_API_KEY="$OLLA_API_KEY"
export OPENAI_MODEL="$BARE_MODEL_ID"
export QWEN_CODE_SUPPRESS_YOLO_WARNING=1
export QWEN_CODE_SKIP_UPDATE_CHECK_ONCE=true
export QWEN_CODE_DISABLE_PRECONNECT=1
export QWEN_USAGE_STATISTICS_ENABLED=false

QWEN_ARGS=(--model "$BARE_MODEL_ID" --approval-mode yolo)

if [ ! -t 0 ]; then
  exec qwen "${QWEN_ARGS[@]}" -p "$(cat)"
else
  exec qwen "${QWEN_ARGS[@]}" "$@"
fi
