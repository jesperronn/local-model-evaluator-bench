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

# Determine which provider to use based on model prefix and LITELLM_PROXY_MODE
# This determines both the provider name AND what goes into pi's models.json
if [[ "$MODEL_ID" =~ ^omlx/ ]] || [[ "$MODEL_ID" == "Ornith"* ]]; then
  # oMLX model: use direct oMLX provider
  RUNTIME_PROVIDER="omlx"
  RUNTIME_CONFIG='{
    "baseUrl": "'"$OMLX_BASE_URL"'",
    "api": "openai-completions",
    "apiKey": "'"$OMLX_API_KEY"'",
    "models": [
      {"id": "Ornith-1.5-35B-A3B-MLX-4bit"},
      {"id": "Ornith-1.5-35B-A3B-MLX-6bit"},
      {"id": "Ornith-1.5-9B-MLX-4bit"}
    ]
  }'
else
  # Default to litellm proxy (if auth is set up) or direct lms
  if [ "$LITELLM_PROXY_MODE" = "1" ]; then
    RUNTIME_PROVIDER="litellm"
    RUNTIME_CONFIG='{
      "baseUrl": "'"$LITELLM_BASE_URL"'",
      "api": "openai-completions",
      "apiKey": "'"$LITELLM_MASTER_KEY"'",
      "models": [
        {"id": "lms/qwen2.5-coder-7b"},
        {"id": "ollama/gemma4-claude:latest"},
        {"id": "omlx/Qwen3.6-35B-A3B-MLX-4bit"}
      ]
    }'
  else
    RUNTIME_PROVIDER="lms"
    RUNTIME_CONFIG='{
      "baseUrl": "'"$LMS_BASE_URL"'",
      "api": "openai-completions",
      "apiKey": "'"$LMS_API_KEY"'",
      "models": []
    }'
  fi
fi

# Merge provider config into models.json
PI_LIVE_CFG="$HOME/.pi/agent/models.json"
mkdir -p "$(dirname "$PI_LIVE_CFG")"

if [ -f "$PI_LIVE_CFG" ]; then
  jq --argjson cfg "$(echo "$RUNTIME_CONFIG" | jq .)" ".providers[\"$RUNTIME_PROVIDER\"] = \$cfg" "$PI_LIVE_CFG" > "$PI_LIVE_CFG.tmp" && mv "$PI_LIVE_CFG.tmp" "$PI_LIVE_CFG"
else
  # Create new config if file doesn't exist
  echo "{\"providers\": {\"$RUNTIME_PROVIDER\": $(echo "$RUNTIME_CONFIG" | jq .)}}" | jq . > "$PI_LIVE_CFG"
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

# Use the configured runtime provider (omlx, lms, or litellm depending on proxy mode and model prefix)
# The provider is configured in ~/.pi/agent/models.json above
PI_ARGS=(--provider "$RUNTIME_PROVIDER" --model "$MODEL_ID")

# Ornith-specific optimization: reduce verbose reasoning output
# Only apply --thinking=low to Ornith models; other models may not support it
if [[ "$MODEL_ID" =~ ornith|Ornith ]]; then
  PI_ARGS+=(--thinking low)
fi

if [ ! -t 0 ]; then
  exec pi "${PI_ARGS[@]}" -p "$(cat)"
else
  exec pi "${PI_ARGS[@]}" "$@"
fi
