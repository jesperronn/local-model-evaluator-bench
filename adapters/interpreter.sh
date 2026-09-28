#!/usr/bin/env bash
# Adapter: interpreter (Open Interpreter) -> unified endpoint via Olla proxy
# (OpenAI format). Routes ONLY through Olla ($OLLA_BASE_URL) — see
# docs/runtimes/olla.md "Adapter wiring" for the pattern this adapter
# follows. Olla auto-discovers every backend's models (omlx, mtplx, lms,
# ollama) under one unified list, so no runtime-prefix branching, no
# --provider flag, and no direct-runtime base-URL selection are needed here
# (unlike the old LiteLLM-routed version of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# IMPORTANT: the installed `interpreter` binary is Open Interpreter's current
# standalone app-server CLI (v0.0.10+, a Codex-CLI-style Rust rewrite), NOT
# the older `pip install open-interpreter` Python package the OPENAI_*
# env-var routing this file used before assumed. It has no OPENAI_BASE_URL
# support at all — it only reads ~/.openinterpreter/config.toml, overridden
# per-run via `-c key=value`. "lmstudio" is a RESERVED built-in
# model_provider id (defaults to http://localhost:1234) that cannot be
# overridden, so we register our own provider (`olla_local`) instead — same
# pattern as adapters/codex.sh uses for the identical reserved-provider
# problem. Unlike codex, this CLI does not appear to require a /v1/models
# format transform for an explicit `-c model=...`, so no wrapper is needed.
#
# Install: see https://docs.openinterpreter.com (uv tool install / standalone binary)
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v interpreter >/dev/null 2>&1 || {
  echo "interpreter not found; install: https://docs.openinterpreter.com" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

OI_CONFIG=(
  -c "model=\"$BARE_MODEL_ID\""
  -c "model_provider=\"olla_local\""
  -c "model_providers.olla_local.name=\"Olla\""
  -c "model_providers.olla_local.base_url=\"$OLLA_BASE_URL\""
  -c "model_providers.olla_local.wire_api=\"chat\""
  -c "approval_policy=\"never\""
)

if [ ! -t 0 ]; then
  exec interpreter exec -s workspace-write "${OI_CONFIG[@]}" "$(cat)"
else
  exec interpreter -s workspace-write -a never "${OI_CONFIG[@]}" "$@"
fi
