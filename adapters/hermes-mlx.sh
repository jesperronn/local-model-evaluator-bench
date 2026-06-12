#!/usr/bin/env bash
# Adapter: hermes -> mlx_lm.server.
# Uses the `mlx` provider defined in ~/.hermes/config.yaml
# (api http://localhost:8080/v1). Same toolset config as hermes-ollama.sh.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"

exec hermes \
  --provider mlx \
  -m "$MODEL_ID" \
  -t file,terminal \
  -z "$PROMPT" \
  "$@"
