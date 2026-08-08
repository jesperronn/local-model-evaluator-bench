#!/usr/bin/env bash
# Adapter: hermes -> oMLX.
# Uses the `omlx` provider defined in ~/.hermes/config.yaml
# (base_url http://127.0.0.1:8000/v1). Unlike lms/mlx, hermes's config already
# has this provider block (per docs/MODEL-DISCOVERY.md hermes's config is
# machine-serialized; bin/agents-config only syncs settings, not this block).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

HERMES_ARGS=(--provider omlx -m "$MODEL_ID" -t "file,terminal")
if [ ! -t 0 ]; then
  HERMES_ARGS+=(-z "$(cat)")
fi

exec hermes "${HERMES_ARGS[@]}" "$@"
