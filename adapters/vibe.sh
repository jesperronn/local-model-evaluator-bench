#!/usr/bin/env bash
# Adapter: Mistral Vibe (vibe) -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($EP_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching, no --provider flag, and no direct-runtime
# base-URL selection are needed here (unlike the old LiteLLM-routed version
# of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Vibe has no CLI flags for base URL/model; it only reads a config.toml
# ([[providers]] + [[models]] + active_model). We regenerate one per run
# under an isolated VIBE_HOME so $MODEL_ID can vary between benchmark trials.
# enable_connectors/enable_telemetry/enable_update_checks are turned off to
# avoid vibe's stray calls to mistral.ai.
#
# Install: cargo install --path <path-to-vibe-repo> (or use system package)
# Contract: CWD is the sandbox to edit. $MODEL_ID set. Prompt on stdin.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

adapter_endpoint || exit 1

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# Create an isolated VIBE_HOME with config.toml pointed at Olla
VIBE_ADAPTER_HOME="${VIBE_ADAPTER_HOME:-$HOME/.vibe-local-adapter}"
mkdir -p "$VIBE_ADAPTER_HOME"
cat > "$VIBE_ADAPTER_HOME/config.toml" <<EOF
active_model = "bench-model"
enable_telemetry = false
enable_update_checks = false
enable_connectors = false

[[providers]]
name = "olla"
api_base = "$EP_URL"
api_key_env_var = ""
api_style = "openai"
backend = "generic"

[[models]]
name = "$BARE_MODEL_ID"
provider = "olla"
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
