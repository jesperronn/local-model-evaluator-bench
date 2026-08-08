#!/usr/bin/env bash
# Adapter: opencode -> oMLX.
# Uses the "omlx" provider in ~/.config/opencode/opencode.jsonc
# (baseURL: $OMLX_BASE_URL). Model addressed as omlx/<id>, where <id> is the
# directory basename oMLX reports from /v1/models — NOT the HuggingFace repo
# name. opencode only offers models listed in that provider block; it does not
# query the endpoint. `bin/agents-config --write` regenerates the list from what
# oMLX actually serves.
# Start the server first: bin/omlx start
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

if [ -t 0 ]; then
  exec opencode --model "omlx/${MODEL_ID}" "$@"
else
  exec opencode run --model "omlx/${MODEL_ID}" "$(cat)" "$@"
fi
