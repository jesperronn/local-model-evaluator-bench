#!/usr/bin/env bash
# Adapter: codex -> Ollama via tool-call proxy.
# Routes through bin/tool-call-proxy (default port 11435) which converts
# qwen2.5-style text tool calls {"name":...,"arguments":...} to structured
# Responses API function_call items so codex can execute them.
#
# Uses CODEX_OSS_PORT to redirect all Ollama traffic to the proxy while
# keeping --local-provider ollama mode (exec_command tools, not apply_patch).
# The proxy intercepts /api/pull (fake success for custom Modelfile models)
# and /v1/responses (convert raw JSON tool calls to proper function_call).
#
# Start proxy first: bin/tool-call-proxy &
# Override port: OLLAMA_BASE_URL=http://localhost:11435/v1
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

# Extract port from OLLAMA_BASE_URL (e.g. http://localhost:11435/v1 → 11435)
PROXY_PORT="${OLLAMA_BASE_URL##*:}"
PROXY_PORT="${PROXY_PORT%%/*}"

CODEX_COMMON=(
  --oss
  --local-provider ollama
  -m "$MODEL_ID"
)
if [ ! -t 0 ]; then
  exec env CODEX_OSS_PORT="${PROXY_PORT}" codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "${CODEX_COMMON[@]}" "$(cat)" "$@"
else
  exec env CODEX_OSS_PORT="${PROXY_PORT}" codex "${CODEX_COMMON[@]}" "$@"
fi
