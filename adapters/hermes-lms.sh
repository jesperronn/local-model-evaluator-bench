#!/usr/bin/env bash
# Adapter: hermes -> LM Studio.
# hermes runs non-interactively with -z (prompt) and -m/--provider. It ships an
# `lmstudio` provider already pointed at LM Studio (see ~/.hermes/config.yaml:
# provider: lmstudio, base_url: http://127.0.0.1:1234/v1). We select it by name.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# -t file exposes write_file, patch, read_file, terminal (for shell commands).
# Do NOT add the terminal toolset alongside file: combining -t file,terminal
# causes a tool-name conflict (both expose a tool named "terminal") and hermes
# resolves it by dropping all file tools, leaving only the process tool. The
# model then can't write files and spins in a failure loop.
#
# --yolo bypasses the smart guardian. Without it, the guardian (an LLM call
# against the same model) times out under bench parallelism when multiple
# adapters compete for model slots, denying every tool call and producing 0
# passes. Sandboxes live under results/ so --yolo is safe here.
HERMES_ARGS=(--provider lmstudio -m "$MODEL_ID" -t file --yolo)
if [ ! -t 0 ]; then
  HERMES_ARGS+=(-z "$(cat)")
fi

exec hermes "${HERMES_ARGS[@]}" "$@"
