#!/usr/bin/env bash
# Adapter: Mistral Vibe (vibe) -> oMLX (OpenAI-compatible).
# See vibe-lms.sh for why a config.toml is regenerated per run.
# Contract: CWD is the sandbox to edit. $MODEL_ID set. Prompt on stdin.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

VIBE_ADAPTER_HOME="${VIBE_ADAPTER_HOME:-$HOME/.vibe-omlx-adapter}"
mkdir -p "$VIBE_ADAPTER_HOME"
cat > "$VIBE_ADAPTER_HOME/config.toml" <<EOF
active_model = "bench-model"
enable_telemetry = false
enable_update_checks = false
enable_connectors = false

[[providers]]
name = "bench"
api_base = "$OMLX_BASE_URL"
api_key_env_var = ""
api_style = "openai"
backend = "generic"

[[models]]
name = "$MODEL_ID"
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
