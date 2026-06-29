#!/usr/bin/env bash
# Adapter: nanocoder -> LM Studio.
# nanocoder supports LM Studio natively via a built-in provider. Provider config
# is injected via NANOCODER_PROVIDERS env var (JSON) so no config file is needed.
# Non-interactive runs use `nanocoder run` (auto-detected via stdin check).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# Inject LM Studio provider config so bench runs are self-contained.
# contextWindow must be set explicitly for local models (nanocoder falls back to
# models.dev metadata which won't have entries for local model keys).
PROVIDER_JSON=$(cat <<EOF
[{
  "name": "LM Studio",
  "baseUrl": "${LMS_BASE_URL}",
  "models": ["${MODEL_ID}"],
  "contextWindow": 65536
}]
EOF
)

if [ -t 0 ]; then
  exec env NANOCODER_PROVIDERS="${PROVIDER_JSON}" \
    nanocoder --provider "LM Studio" --model "${MODEL_ID}" "$@"
else
  PROMPT="Working directory: $(pwd)

$(cat)"
  exec env NANOCODER_PROVIDERS="${PROVIDER_JSON}" NANOCODER_TRUST_DIRECTORY=1 \
    nanocoder run --provider "LM Studio" --model "${MODEL_ID}" "${PROMPT}" "$@"
fi
