#!/usr/bin/env bash
# Adapter: cn (Continue's headless CLI) -> unified endpoint via LiteLLM proxy.
# Routes through the LiteLLM proxy ($LITELLM_BASE_URL) to any local runtime
# (lms, ollama, mlx, omlx, mtplx) based on model ID prefix.
#
# The proxy must be running: bin/litellm-proxy start
# Model IDs are prefixed by provider: lms/<id>, ollama/<id>, omlx/<id>, mlx/<id>, mtplx/<id>
#
# Adapter accepts --provider to override which backend to target:
#   --provider lms        # route to LM Studio (default if lms/ prefix)
#   --provider ollama     # route to Ollama
#   --provider omlx       # route to oMLX
#   --provider mlx        # route to mlx_lm.server
#   --provider mtplx      # route to MTPLX
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
PROVIDER="${PROVIDER:-lms}"

# Parse --provider flag if passed
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

command -v cn >/dev/null 2>&1 || { echo "cn not found; install: npm install -g @continuedev/cli" >&2; exit 1; }

CONFIG_DIR="$HOME/.continue-litellm-adapter"
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# Regenerated each run so MODEL_ID always matches the current adapter invocation.
cat > "$CONFIG_FILE" <<EOF
name: litellm-adapter
version: 1.0.0
schema: v1
models:
  - name: litellm-model
    provider: openai
    model: ${PREFIXED_MODEL_ID}
    apiBase: ${LITELLM_BASE_URL}
    apiKey: ${LITELLM_API_KEY}
    roles:
      - chat
      - edit
      - apply
    capabilities:
      - tool_use
EOF

# Forward tuned sampling params to the LiteLLM API via Continue's
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
