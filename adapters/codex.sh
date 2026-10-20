#!/usr/bin/env bash
# Adapter: codex -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching and no per-runtime endpoint selection are
# needed here (unlike the old LiteLLM-routed version of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Codex talks to any OpenAI-compatible endpoint via a custom model_provider.
# We pass the provider definition inline with -c overrides so no edit to
# ~/.codex/config.toml is required. NOTE: `lmstudio` is a RESERVED built-in
# provider id in codex and cannot be overridden, so we register our own under
# `olla_local`. See docs/SETUP.md for the persistent setup.
#
# Codex requires /v1/models to return Ollama format {"models":[...]}, but
# Olla's OpenAI-compatible route returns OpenAI format {"data":[...]}. This
# adapter wraps Olla with a models-format transformer
# (adapters/codex-models-wrapper.py) that converts the response before Codex
# sees it.
#
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
# Install: npm install -g codex-cli
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v codex >/dev/null 2>&1 || { echo "codex not found; install: npm install -g codex-cli" >&2; exit 1; }

adapter_endpoint || exit 1

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# Start or reuse the singleton models-format wrapper. The wrapper transforms
# Olla's OpenAI-format /v1/models response to Ollama format for codex
# compatibility. All concurrent codex.sh invocations share one wrapper
# instance for efficiency.
ADAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_MANAGER="$ADAPTER_DIR/codex-wrapper-manager.sh"

# Strip /v1 from Olla's OpenAI-compatible base URL — the wrapper re-adds it
# (see WRAPPER_URL below) the same way it always has.
WRAPPER_TARGET_URL="$EP_ROOT"
export BENCH_EP_KEY="$EP_KEY"

# Start or reuse the singleton wrapper via the manager
WRAPPER_PORT=$("$WRAPPER_MANAGER" start "$WRAPPER_TARGET_URL") || {
  echo "Failed to start codex-models-wrapper" >&2
  exit 1
}

# Clean up wrapper reference when this script exits
# The manager ref-counts, so the wrapper stays running until the last user exits
cleanup() {
  "$WRAPPER_MANAGER" stop 2>/dev/null || true
}
trap cleanup EXIT

# Wrapper is ready (manager ensures this before returning)
sleep 0.1

# Point Codex to the wrapper. Keep the /v1 suffix for the same reason as before.
WRAPPER_URL="http://127.0.0.1:$WRAPPER_PORT/v1"

CODEX_COMMON=(
  -c model="$BARE_MODEL_ID"
  -c model_provider="olla_local"
  -c model_providers.olla_local.name="Olla Proxy"
  -c model_providers.olla_local.base_url="$WRAPPER_URL"
  -c model_providers.olla_local.env_key="BENCH_EP_KEY"
  # codex 0.142.3 dropped wire_api="chat" support; "responses" is now the only
  # valid value. LMS ≥0.3.x and other OpenAI-compatible endpoints accept
  # Responses-API-shaped tool outputs.
  -c model_providers.olla_local.wire_api="responses"
)
# splash /v1/responses only accepts function tools: codex's built-in
# web_search tool (type "web_search") is rejected with HTTP 400 (bisected; the
# MCP "namespace" tools are accepted). Disable it, and force the JSON function
# variant of apply_patch (freeform "custom" would be rejected the same way).
if backend_is_splash; then
  CODEX_COMMON+=(-c web_search="disabled" -c apply_patch_tool_type="function")
fi
if [ ! -t 0 ]; then
  exec codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "${CODEX_COMMON[@]}" "$(cat)" "$@"
else
  exec codex "${CODEX_COMMON[@]}" "$@"
fi
