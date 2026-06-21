#!/usr/bin/env bash
# Adapter: opencode -> mlx_lm.server.
# Uses the "mlx" provider in ~/.config/opencode/opencode.jsonc
# (baseURL: http://localhost:8080/v1). Model addressed as mlx/<id>.
# Start server first: mlx_lm.server --model <path> --port 8080
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

if [ -t 0 ]; then
  exec opencode --model "mlx/${MODEL_ID}" "$@"
else
  exec opencode run --model "mlx/${MODEL_ID}" "$(cat)" "$@"
fi
