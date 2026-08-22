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
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
# Install: npm install -g codex-cli
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"
PROVIDER="${PROVIDER:-lms}"

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

export LITELLM_API_KEY  # codex reads the key from this env var (see -c env_key).

CODEX_COMMON=(
  -c model="$PREFIXED_MODEL_ID"
  -c model_provider="litellm_local"
  -c model_providers.litellm_local.name="LiteLLM Proxy"
  -c model_providers.litellm_local.base_url="$LITELLM_BASE_URL"
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
