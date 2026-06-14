#!/usr/bin/env bash
# Adapter: hermes -> mlx_lm.server.
# Uses the `mlx` provider defined in ~/.hermes/config.yaml
# (api http://localhost:8080/v1).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

HERMES_ARGS=(--provider mlx -m "$MODEL_ID" -t "file,terminal")
if [ ! -t 0 ]; then
  HERMES_ARGS+=(-z "$(cat)")
fi

exec hermes "${HERMES_ARGS[@]}" "$@"
