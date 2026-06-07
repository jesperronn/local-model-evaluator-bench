#!/usr/bin/env bash
# Adapter: opencode -> LM Studio.
# opencode has a built-in `lmstudio` provider (models.dev) that auto-discovers
# models from http://localhost:1234. If your LM Studio is elsewhere, set the
# base URL in ~/.config/opencode/opencode.json (see docs/SETUP.md).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"

# Model is addressed as provider/model -> lmstudio/<id>.
# opencode reads baseURL from ~/.config/opencode/opencode.json (lmstudio provider).
# No --openai-api-base / --openai-api-key flags supported by this version.
exec opencode run --model "lmstudio/${MODEL_ID}" "$PROMPT"
