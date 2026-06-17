#!/usr/bin/env bash
# Adapter: interpreter (Open Interpreter) -> LM Studio (OpenAI-compatible).
# Uses the built-in "lmstudio" provider already wired to localhost:1234/v1.
# `interpreter exec` runs non-interactively; the bare TUI starts when stdin is
# a terminal. Model is overridden at runtime via -c without touching config.toml.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

OI_CONFIG=(
  -c 'model_provider="lmstudio"'
  -c "model=\"$MODEL_ID\""
)

if [ ! -t 0 ]; then
  exec interpreter exec -s workspace-write "${OI_CONFIG[@]}" "$(cat)"
else
  exec interpreter "${OI_CONFIG[@]}" "$@"
fi
