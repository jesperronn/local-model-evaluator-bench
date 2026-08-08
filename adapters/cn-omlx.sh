#!/usr/bin/env bash
# Adapter: cn (Continue's headless CLI) -> oMLX (OpenAI-compatible).
# Named "cn" (not "continue") because bin/bench resolves adapters via
# `command -v "$adapter"`, and "continue" collides with the bash builtin of
# the same name — that check would silently pass against the wrong thing.
#
# Uses Continue's official headless CLI (`cn`, package @continuedev/cli).
# See docs/extensions/continue.md.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
#
# Install: npm install -g @continuedev/cli
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v cn >/dev/null 2>&1 || { echo "cn not found; reinstall: npm install -g @continuedev/cli" >&2; exit 1; }

CONFIG_DIR="$HOME/.continue-omlx-adapter"
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

# Regenerated each run so MODEL_ID always matches the current adapter invocation.
cat > "$CONFIG_FILE" <<EOF
name: omlx-adapter
version: 1.0.0
schema: v1
models:
  - name: omlx-model
    provider: openai
    model: ${MODEL_ID}
    apiBase: ${OMLX_BASE_URL}
    apiKey: ${OMLX_API_KEY}
    roles:
      - chat
      - edit
      - apply
    capabilities:
      - tool_use
EOF

# Forward tuned sampling params to the oMLX API via Continue's
# defaultCompletionOptions. Continue is the only omlx adapter that can carry
# per-request temperature/penalties (pi/cline expose no such CLI flags), so the
# ADAPTER_DEFAULT_* knobs from config.sh are honoured here. Penalties are only
# emitted when set (non-empty) — keeps baseline runs byte-identical to before.
{
  echo "    defaultCompletionOptions:"
  echo "      temperature: ${ADAPTER_DEFAULT_TEMPERATURE}"
  [ -n "${ADAPTER_DEFAULT_PRESENCE_PENALTY:-}" ]  && echo "      presencePenalty: ${ADAPTER_DEFAULT_PRESENCE_PENALTY}"
  [ -n "${ADAPTER_DEFAULT_FREQUENCY_PENALTY:-}" ] && echo "      frequencyPenalty: ${ADAPTER_DEFAULT_FREQUENCY_PENALTY}"
} >> "$CONFIG_FILE"

CN_ARGS=(
  --config "$CONFIG_FILE"
  -p            # print-and-exit (headless) mode
  --auto        # auto mode: allow all tools, no interactive approval prompt
)
# Reasoning toggle: default off strips <think> for clean tool output; on lets the
# model reason (paired with a /think directive on the prompt). See config.sh
# ADAPTER_REASONING and docs/troubleshooting-qwen-reasoning-loops.md.
THINK_DIRECTIVE="/no_think"
if [ "${ADAPTER_REASONING:-off}" = "on" ]; then
  THINK_DIRECTIVE="/think"
else
  CN_ARGS+=(--silent)   # strip <think></think> tags from reasoning models
fi

if [ ! -t 0 ]; then
  exec cn "${CN_ARGS[@]}" "${THINK_DIRECTIVE}
$(cat)"
else
  exec cn --config "$CONFIG_FILE"
fi
