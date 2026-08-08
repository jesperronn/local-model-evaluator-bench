#!/usr/bin/env bash
# Adapter: nanocoder -> oMLX. Provider config is injected via NANOCODER_PROVIDERS
# env var (JSON) so no config file is needed.
# NOTE: provider name is "oMLX" (no space) — nanocoder-lms.sh's "LM Studio" name
# is currently rejected by installed nanocoder ("Provider name must contain
# only alphanumeric characters, hyphens, and underscores", see
# docs/MODEL-DISCOVERY.md); a space-free name sidesteps that here.
# Non-interactive runs use `nanocoder run` (auto-detected via stdin check).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# contextWindow must be set explicitly for local models (nanocoder falls back to
# models.dev metadata which won't have entries for local model keys).
PROVIDER_JSON=$(cat <<EOF
[{
  "name": "oMLX",
  "baseUrl": "${OMLX_BASE_URL}",
  "models": ["${MODEL_ID}"],
  "contextWindow": 65536
}]
EOF
)

if [ -t 0 ]; then
  exec env NANOCODER_PROVIDERS="${PROVIDER_JSON}" \
    nanocoder --provider "oMLX" --model "${MODEL_ID}" "$@"
else
  PROMPT="Working directory: $(pwd)

$(cat)"
  exec env NANOCODER_PROVIDERS="${PROVIDER_JSON}" NANOCODER_TRUST_DIRECTORY=1 \
    nanocoder run --provider "oMLX" --model "${MODEL_ID}" "${PROMPT}" "$@"
fi
