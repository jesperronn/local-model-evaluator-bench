#!/usr/bin/env bash
# Adapter: cline -> mlx_lm.server (OpenAI-compatible at localhost:8080/v1).
# Uses cline's openai provider with a custom base URL.
# Start server first: mlx_lm.server --model <path> --port 8080
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

if ! cline --version >/dev/null 2>&1; then
  CLINE=$(find /Users/jesper/Library/pnpm/store -name "cline" \
    -path "*/cli-darwin-arm64/bin/cline" 2>/dev/null | sort --version-sort --reverse | head -1)
  [ -x "${CLINE:-}" ] || { echo "cline not found; reinstall: pnpm install -g cline" >&2; exit 1; }
else
  CLINE=cline
fi

DATA_DIR="$HOME/.cline-mlx-adapter"
"$CLINE" auth openai \
  --data-dir "$DATA_DIR" \
  --apikey  "mlx" \
  --modelid "$MODEL_ID" \
  --baseurl "http://localhost:8080/v1" >/dev/null 2>&1

CLINE_ARGS=(
  --data-dir "$DATA_DIR"
  -P openai
  --model "$MODEL_ID"
)

if [ ! -t 0 ]; then
  exec "$CLINE" "${CLINE_ARGS[@]}" --auto-approve true "$(cat)"
else
  exec "$CLINE" "${CLINE_ARGS[@]}" --tui
fi
