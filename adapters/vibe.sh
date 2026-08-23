#!/usr/bin/env bash
# Adapter: Mistral Vibe (vibe) -> unified endpoint via LiteLLM proxy.
# Routes through the LiteLLM proxy ($LITELLM_BASE_URL) to any local runtime
# (lms, ollama, mlx, omlx, mtplx) based on model ID prefix.
#
# The proxy must be running: bin/litellm-proxy start
# Model IDs are prefixed by provider: lms/<id>, ollama/<id>, omlx/<id>, mlx/<id>, mtplx/<id>
#
# Vibe has no CLI flags for base URL/model; it only reads a config.toml
# ([[providers]] + [[models]] + active_model). We regenerate one per run
# under an isolated VIBE_HOME so $MODEL_ID can vary between benchmark trials.
# enable_connectors/enable_telemetry/enable_update_checks are turned off to
# avoid vibe's stray calls to mistral.ai.
#
# Adapter accepts --provider to override which backend to target:
#   --provider lms        # route to LM Studio (default if lms/ prefix)
#   --provider ollama     # route to Ollama
#   --provider omlx       # route to oMLX
#   --provider mlx        # route to mlx_lm.server
#   --provider mtplx      # route to MTPLX
#
# Install: cargo install --path <path-to-vibe-repo> (or use system package)
# Contract: CWD is the sandbox to edit. $MODEL_ID set. Prompt on stdin.
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

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# Create an isolated VIBE_HOME with config.toml for the LiteLLM proxy backend
VIBE_ADAPTER_HOME="${VIBE_ADAPTER_HOME:-$HOME/.vibe-litellm-adapter}"
mkdir -p "$VIBE_ADAPTER_HOME"
cat > "$VIBE_ADAPTER_HOME/config.toml" <<EOF
active_model = "bench-model"
enable_telemetry = false
enable_update_checks = false
enable_connectors = false

[[providers]]
name = "bench"
api_base = "$LITELLM_BASE_URL"
api_key_env_var = ""
api_style = "openai"
backend = "generic"

[[models]]
name = "$PREFIXED_MODEL_ID"
provider = "bench"
alias = "bench-model"
temperature = 0.2
input_price = 0.0
output_price = 0.0
thinking = "off"
supports_images = false
EOF

export VIBE_HOME="$VIBE_ADAPTER_HOME"

VIBE_ARGS=(--auto-approve --trust)

if [ ! -t 0 ]; then
  exec vibe -p "$(cat)" "${VIBE_ARGS[@]}"
else
  exec vibe "${VIBE_ARGS[@]}"
fi
