#!/usr/bin/env bash
# Adapter: opencode -> LM Studio.
# opencode has a built-in `lmstudio` provider (models.dev) that auto-discovers
# models from http://localhost:1234. If your LM Studio is elsewhere, set the
# base URL in ~/.config/opencode/opencode.json (see docs/SETUP.md).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
#
# Known model incompatibilities (revisit when adapter/model updates):
#   nvidia/nemotron-3-nano-omni  — opencode 1.17.11, 2026-06-28
#     Opencode server returns `UnknownError` (err_a2be5b8a, err_79181a4f) on
#     every case within ~2s — its tool-call parser rejects what the model
#     emits before any work happens. Likely malformed tool calls or empty
#     content the parser can't normalize. See run 20260628-073902.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# Model is addressed as provider/model -> lmstudio/<id>.
# opencode reads baseURL from ~/.config/opencode/opencode.json (lmstudio provider).
# No --openai-api-base / --openai-api-key flags supported by this version.
if [ -t 0 ]; then
  exec opencode --model "lmstudio/${MODEL_ID}" "$@"
else
  # Prepend CWD so the model uses real paths instead of /path/to/... placeholders.
  PROMPT="Working directory: $(pwd)

$(cat)"
  exec opencode run --dangerously-skip-permissions --model "lmstudio/${MODEL_ID}" "${PROMPT}" "$@"
fi
