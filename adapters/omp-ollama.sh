#!/usr/bin/env bash
# Adapter: oh-my-pi (omp) -> Ollama.
# omp is a fork/variant of pi with enhanced coding agent features.
# Uses --model flag to route to Ollama via local provider setup.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# omp uses --model for explicit model selection
if [ ! -t 0 ]; then
  exec omp --model "$MODEL_ID" "$(cat)"
else
  exec omp --model "$MODEL_ID" "$@"
fi
