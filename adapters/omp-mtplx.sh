#!/usr/bin/env bash
# Adapter: oh-my-pi (omp) -> MTPLX (OpenAI-compatible local server).
# omp has no "mtplx" provider; it does support pointing its "lm-studio"
# provider at an arbitrary OpenAI-compatible server via LM_STUDIO_BASE_URL,
# so we route through that to reach the MTPLX server at $MTPLX_BASE_URL.
# Start the server first: mtplx quickstart --port 8001 --model <model>
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v omp >/dev/null 2>&1 || {
  echo "omp not found; install: npm install -g <package>" >&2
  exit 1
}

export LM_STUDIO_BASE_URL="$MTPLX_BASE_URL"
OMP_ARGS=(--model "lm-studio/$MODEL_ID")

if [ ! -t 0 ]; then
  exec omp "${OMP_ARGS[@]}" -p "$(cat)"
else
  exec omp "${OMP_ARGS[@]}" "$@"
fi
