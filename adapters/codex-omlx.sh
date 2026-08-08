#!/usr/bin/env bash
# Adapter: codex -> oMLX.
# Same custom-provider approach as codex-lms.sh (NOT codex-mlx.sh's stub):
# codex's wire_api enum only accepts "responses", and oMLX (like LM Studio)
# accepts Responses-API-shaped tool outputs, so a custom model_provider with
# wire_api="responses" works. codex-mlx.sh is a stub for a narrower reason
# (mlx_lm.server was only reachable via --oss's ollama/lmstudio local-provider
# path, not a custom provider) that doesn't apply here.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

export OMLX_API_KEY  # codex reads the key from this env var (see -c env_key).

CODEX_COMMON=(
  -c model="$MODEL_ID"
  -c model_provider="omlx_local"
  -c model_providers.omlx_local.name="oMLX"
  -c model_providers.omlx_local.base_url="$OMLX_BASE_URL"
  -c model_providers.omlx_local.env_key="OMLX_API_KEY"
  -c model_providers.omlx_local.wire_api="responses"
)
if [ ! -t 0 ]; then
  exec codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "${CODEX_COMMON[@]}" "$(cat)" "$@"
else
  exec codex "${CODEX_COMMON[@]}" "$@"
fi
