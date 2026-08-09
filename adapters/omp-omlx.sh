#!/usr/bin/env bash
# Adapter: oh-my-pi (omp) -> oMLX (OpenAI-compatible local server).
# omp resolves an "omlx" provider the same way pi does: a named omlx entry in
# omp's own catalog (typically ~/.omp/models.json) pointing at $OMLX_BASE_URL.
# Start the server first: bin/omlx start
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v omp >/dev/null 2>&1 || {
  echo "omp not found; install: npm install -g <package>" >&2
  exit 1
}

OMP_ARGS=(--provider omlx --model "$MODEL_ID")

if [ ! -t 0 ]; then
  exec omp "${OMP_ARGS[@]}" -p "$(cat)"
else
  exec omp "${OMP_ARGS[@]}" "$@"
fi
