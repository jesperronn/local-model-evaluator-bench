#!/usr/bin/env bash
# Adapter: pi -> unified endpoint via LiteLLM proxy.
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
# Install: npm install -g @earendil-works/pi-coding-agent
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"
PROVIDER="${PROVIDER:-${RUNTIME:-lms}}"

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

command -v pi >/dev/null 2>&1 || {
  echo "pi not found; install: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
}

# Ensure litellm provider is configured in pi's models.json
PI_LIVE_CFG="$HOME/.pi/agent/models.json"
if [ ! -f "$PI_LIVE_CFG" ] || ! jq -e '.providers.litellm' "$PI_LIVE_CFG" >/dev/null 2>&1; then
  mkdir -p "$(dirname "$PI_LIVE_CFG")"
  # Merge litellm provider into existing config or create new one
  if [ -f "$PI_LIVE_CFG" ]; then
    jq '.providers.litellm = {
      "baseUrl": "http://127.0.0.1:4444/v1",
      "api": "openai-completions",
      "apiKey": "litellm",
      "models": [
        {"id": "lms/qwen2.5-coder-7b"},
        {"id": "ollama/gemma4-claude:latest"},
        {"id": "omlx/Qwen3.6-35B-A3B-MLX-4bit"},
        {"id": "omlx/Ornith-1.0-35B-4bit"}
      ]
    }' "$PI_LIVE_CFG" > "$PI_LIVE_CFG.tmp" && mv "$PI_LIVE_CFG.tmp" "$PI_LIVE_CFG"
  fi
fi

# Reapply the qwen3-coder edit-tool XML-recovery shim if missing (idempotent,
# fast no-op when already patched). pi is a global npm install, so the patch is
# wiped on upgrade — reapply per run so scored pi runs stay reproducible.
# See docs/tools/pi.md (Known issues) and docs/SCORING.md (Workarounds).
"$REPO_ROOT/bin/pi-patch-edit-shim" >/dev/null 2>&1 ||
  echo "warn: pi edit-tool shim not applied (see docs/tools/pi.md)" >&2

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# Use the proxy provider to route through the unified endpoint.
# The provider name "litellm" is configured in ~/.pi/agent/models.json
# and points to LITELLM_BASE_URL with all models accessible via their
# provider-prefixed IDs (lms/..., ollama/..., etc.).
PI_ARGS=(--provider litellm --model "$PREFIXED_MODEL_ID")

if [ ! -t 0 ]; then
  exec pi "${PI_ARGS[@]}" -p "$(cat)"
else
  exec pi "${PI_ARGS[@]}" "$@"
fi
