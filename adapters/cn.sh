#!/usr/bin/env bash
# Adapter: cn (Continue's headless CLI) -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($EP_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching and no per-runtime endpoint selection are
# needed here (unlike the old LiteLLM-routed version of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Named "cn" (not "continue") because bin/bench resolves adapters via
# `command -v "$adapter"`, and "continue" collides with the bash builtin of
# the same name — that check would silently pass against the wrong thing.
#
# Install: npm install -g @continuedev/cli
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v cn >/dev/null 2>&1 || { echo "cn not found; install: npm install -g @continuedev/cli" >&2; exit 1; }

adapter_endpoint || exit 1

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"
API_BASE="$EP_URL"
API_KEY="$EP_KEY"

CONFIG_DIR="$HOME/.continue-local-adapter"
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

# Regenerated each run so MODEL_ID always matches the current adapter invocation.
cat > "$CONFIG_FILE" <<EOF
name: local-adapter
version: 1.0.0
schema: v1
models:
  - name: local-model
    provider: openai
    model: "${BARE_MODEL_ID}"
    apiBase: "${API_BASE}"
    apiKey: "${API_KEY}"
    roles:
      - chat
      - edit
      - apply
    capabilities:
      - tool_use
EOF

# Forward tuned sampling params to Olla via Continue's
# defaultCompletionOptions. Continue is the only adapter that can carry
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
