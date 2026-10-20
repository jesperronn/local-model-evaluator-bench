#!/usr/bin/env bash
# Adapter: GitHub Copilot CLI -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($EP_URL) — see docs/runtimes/olla.md
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
# COPILOT_PROVIDER_BASE_URL redirects all model calls to Olla's
# OpenAI-compatible endpoint, bypassing GitHub's Copilot service entirely.
# COPILOT_OFFLINE=true prevents the CLI from phoning home to GitHub.
# Docs: https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-byok-models
#
# COPILOT_PROVIDER_MODEL_ID=gpt-4o: a well-known catalog entry copilot uses to
# resolve token limits and agent config. The actual model sent to Olla is in
# COPILOT_PROVIDER_WIRE_MODEL; the catalog entry is only for sizing defaults.
#
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

adapter_endpoint || exit 1

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"
COPILOT_PROVIDER_BASE_URL="$EP_URL"
COPILOT_PROVIDER_API_KEY="$EP_KEY"

# gpt-4o catalog entry makes copilot send a non-function (custom apply_patch) tool, which
# splash rejects with HTTP 400; gpt-4.1 yields function tools only.
COPILOT_CATALOG_ID=gpt-4o
backend_is_splash && COPILOT_CATALOG_ID=gpt-4.1
COPILOT_ARGS=()
if [ ! -t 0 ]; then
  COPILOT_ARGS+=(--allow-all-tools --allow-all-paths --no-ask-user -p "$(cat)")
fi

exec env \
  COPILOT_PROVIDER_BASE_URL="$COPILOT_PROVIDER_BASE_URL" \
  COPILOT_PROVIDER_TYPE="openai" \
  COPILOT_PROVIDER_API_KEY="$COPILOT_PROVIDER_API_KEY" \
  COPILOT_PROVIDER_MODEL_ID="$COPILOT_CATALOG_ID" \
  COPILOT_PROVIDER_WIRE_MODEL="$BARE_MODEL_ID" \
  COPILOT_OFFLINE="true" \
  copilot "${COPILOT_ARGS[@]}" "$@"
