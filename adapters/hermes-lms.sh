#!/usr/bin/env bash
# Adapter: hermes -> LM Studio.
# hermes runs non-interactively with -z (prompt) and -m/--provider. It ships an
# `lmstudio` provider already pointed at LM Studio (see ~/.hermes/config.yaml:
# provider: lmstudio, base_url: http://127.0.0.1:1234/v1). We select it by name.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# -t file,terminal: both toolsets work together since v0.17.0 (the tool-name
# conflict present in v0.16.0 is fixed). Enables write_file, patch, read_file,
# search_files, process, AND direct shell execution via terminal.
HERMES_ARGS=(--provider lmstudio -m "$MODEL_ID" -t file,terminal)
if [ ! -t 0 ]; then
  # Interactive approval mode: the smart guardian will ask for confirmations
  # on potentially risky actions. This provides safety signals during automation.
  HERMES_ARGS+=(-z "$(cat)")
fi

exec hermes "${HERMES_ARGS[@]}" "$@"
