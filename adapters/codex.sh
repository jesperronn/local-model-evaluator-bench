#!/usr/bin/env bash
# Adapter: codex -> unified endpoint via LiteLLM proxy.
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
# Codex talks to any OpenAI-compatible endpoint via a custom model_provider.
# We pass the provider definition inline with -c overrides so no edit to
# ~/.codex/config.toml is required. NOTE: `lmstudio` is a RESERVED built-in
# provider id in codex and cannot be overridden, so we register our own under
# `litellm_local`. See docs/SETUP.md for the persistent setup.
#
# Codex requires /v1/models to return Ollama format {"models":[...]}, but
# LiteLLM returns OpenAI format {"data":[...]}. This adapter wraps the
# LiteLLM proxy with a models-format transformer (adapters/codex-models-wrapper.py)
# that converts the response before Codex sees it.
#
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
# Install: npm install -g codex-cli
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

command -v codex >/dev/null 2>&1 || { echo "codex not found; install: npm install -g codex-cli" >&2; exit 1; }

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

export LITELLM_API_KEY="$LITELLM_MASTER_KEY"

# Start the models-format wrapper on a local port. The wrapper transforms
# LiteLLM's OpenAI-format /v1/models response to Ollama format.
# Find a free port by trying to bind to one
ADAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_SCRIPT="$ADAPTER_DIR/codex-models-wrapper.py"

# Use Python to find a free port (more portable than nc)
WRAPPER_PORT=$(python3 -c "
import socket
for port in range(19900, 20100):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind(('127.0.0.1', port))
        s.close()
        print(port)
        break
    except OSError:
        pass
" 2>/dev/null)

if [[ -z "$WRAPPER_PORT" ]]; then
  echo "Could not find a free port for wrapper" >&2
  exit 1
fi

# Strip /v1 from LITELLM_BASE_URL here because the wrapper (below) does a
# naive `TARGET_URL + self.path` concatenation: codex's model_provider
# base_url further down KEEPS its /v1 suffix, so codex's own request path
# already carries "/v1/models" / "/v1/responses" — that's what self.path
# will be. Keeping /v1 on both sides here would double it up
# ("/v1/v1/models", a 404); stripping it here and keeping it on the base_url
# given to codex is what makes the two halves add up to exactly one "/v1".
#
# An earlier version of this adapter got this backwards — /v1 stripped here
# (right) but ALSO left off the base_url given to codex (wrong) — so codex
# requested bare "/models"/"/responses", which landed on litellm as
# "/responses" instead of "/v1/responses" (litellm doesn't serve that).
# /v1/models discovery still "worked" by accident (both sides missing /v1
# cancelled out), but every real completion mid-task 404'd, retried, and
# eventually gave up with the generic "high demand" fallback message — with
# no accompanying "failed to refresh available models" error, since discovery
# alone looked fine.
WRAPPER_TARGET_URL="${LITELLM_BASE_URL%/v1}"

# Start wrapper in background, capture its PID
python3 "$WRAPPER_SCRIPT" "$WRAPPER_PORT" "$WRAPPER_TARGET_URL" &
WRAPPER_PID=$!

# Clean up wrapper when this script exits
cleanup() {
  if [[ -n "$WRAPPER_PID" ]] && kill -0 "$WRAPPER_PID" 2>/dev/null; then
    kill "$WRAPPER_PID" 2>/dev/null || true
    wait "$WRAPPER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Give the wrapper a moment to start (increased to ensure it's ready)
sleep 1.0

# Point Codex to the wrapper instead of directly to LiteLLM. Keep the /v1
# suffix here — see the WRAPPER_TARGET_URL comment above for why base_url and
# target must agree on it.
WRAPPER_URL="http://127.0.0.1:$WRAPPER_PORT/v1"

CODEX_COMMON=(
  -c model="$PREFIXED_MODEL_ID"
  -c model_provider="litellm_local"
  -c model_providers.litellm_local.name="LiteLLM Proxy"
  -c model_providers.litellm_local.base_url="$WRAPPER_URL"
  -c model_providers.litellm_local.env_key="LITELLM_API_KEY"
  # codex 0.142.3 dropped wire_api="chat" support; "responses" is now the only
  # valid value. LMS ≥0.3.x and other OpenAI-compatible endpoints accept
  # Responses-API-shaped tool outputs.
  -c model_providers.litellm_local.wire_api="responses"
)
if [ ! -t 0 ]; then
  exec codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "${CODEX_COMMON[@]}" "$(cat)" "$@"
else
  exec codex "${CODEX_COMMON[@]}" "$@"
fi
