#!/usr/bin/env bash
# Adapter: oh-my-pi (omp) -> oMLX (OpenAI-compatible local server).
# omp resolves this via a dedicated "omlx" custom provider registered in
# ~/.omp/agent/models.yml (baseUrl -> $OMLX_BASE_URL). Keeping it a distinct
# provider (rather than sharing the built-in "lm-studio" slot) lets
# `omp models refresh` see omlx, mtplx, lms, etc. all at once.
# Start the server first: bin/omlx start
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v omp >/dev/null 2>&1 || {
  echo "omp not found; install: npm install -g <package>" >&2
  exit 1
}

OMP_ARGS=(--model "omlx/$MODEL_ID")

if [ ! -t 0 ]; then
  exec omp "${OMP_ARGS[@]}" -p "$(cat)"
else
  exec omp "${OMP_ARGS[@]}" "$@"
fi
