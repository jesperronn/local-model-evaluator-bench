#!/usr/bin/env bash
# Adapter: pi -> mlx_lm.server.
# Requires ~/.pi/agent/models.json to have an "mlx" provider entry pointing
# at localhost:8080/v1 with the target model listed.
# Start server first: mlx_lm.server --model <path> --port 8080
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v pi >/dev/null 2>&1 || {
  echo "pi not found; install: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
}

PI_ARGS=(--provider mlx --model "$MODEL_ID" --thinking off)

if [ ! -t 0 ]; then
  exec pi "${PI_ARGS[@]}" -p "$(cat)"
else
  exec pi "${PI_ARGS[@]}" "$@"
fi
