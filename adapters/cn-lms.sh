#!/usr/bin/env bash
# Adapter: cn (Continue's headless CLI) -> LM Studio (OpenAI-compatible).
# Named "cn" (not "continue") because bin/bench resolves adapters via
# `command -v "$adapter"`, and "continue" collides with the bash builtin of
# the same name — that check would silently pass against the wrong thing.
# The adapter name must match the actual CLI binary, same convention as
# aider/cline/codex.
#
# Uses Continue's official headless CLI (`cn`, package @continuedev/cli) —
# a separate headless twin of the Continue.dev VS Code/JetBrains extension,
# NOT the GUI extension itself. See docs/extensions/continue.md for why the
# GUI extension is currently ranked "avoid" (approval-memory failure) while
# this headless CLI can still be benchmarked for accuracy/speed.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
#
# Install: npm install -g @continuedev/cli
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v cn >/dev/null 2>&1 || { echo "cn not found; reinstall: npm install -g @continuedev/cli" >&2; exit 1; }

CONFIG_DIR="$HOME/.continue-lms-adapter"
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

# Regenerated each run so MODEL_ID always matches the current adapter invocation.
cat > "$CONFIG_FILE" <<EOF
name: lms-adapter
version: 1.0.0
schema: v1
models:
  - name: lms-model
    provider: openai
    model: ${MODEL_ID}
    apiBase: ${LMS_BASE_URL}
    apiKey: ${LMS_API_KEY}
    roles:
      - chat
      - edit
      - apply
    capabilities:
      - tool_use
EOF

CN_ARGS=(
  --config "$CONFIG_FILE"
  -p            # print-and-exit (headless) mode
  --auto        # auto mode: allow all tools, no interactive approval prompt
  --silent      # strip <think></think> tags from reasoning models
)

if [ ! -t 0 ]; then
  exec cn "${CN_ARGS[@]}" "$(cat)"
else
  exec cn --config "$CONFIG_FILE"
fi
