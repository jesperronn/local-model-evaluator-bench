#!/usr/bin/env bash
# Adapter: nanocoder -> unified endpoint via Olla proxy (OpenAI format).
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
# Provider config is injected via NANOCODER_PROVIDERS env var (JSON) so no
# config file is needed. The `models` array is populated from Olla's live
# /models list on every run (same pattern as adapters/pi.sh) so it can't go
# stale as models come and go, and the target model is guaranteed to be in
# it. Non-interactive runs use `nanocoder run` (auto-detected via stdin
# check).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

adapter_endpoint || exit 1

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# contextWindow must be set explicitly for local models (nanocoder falls back to
# models.dev metadata which won't have entries for local model keys).
OLLA_MODELS_JSON="$(runtime_models "$EP_URL" | jq -R -s -c 'split("\n") | map(select(length > 0))')"
[ -z "$OLLA_MODELS_JSON" ] || [ "$OLLA_MODELS_JSON" = "[]" ] && OLLA_MODELS_JSON="[\"$BARE_MODEL_ID\"]"

PROVIDER_JSON="$(jq -n \
  --arg name "Olla" \
  --arg baseUrl "$EP_URL" \
  --argjson models "$OLLA_MODELS_JSON" \
  '[{name: $name, baseUrl: $baseUrl, models: $models, contextWindow: 65536}]')"

if [ -t 0 ]; then
  exec env NANOCODER_PROVIDERS="${PROVIDER_JSON}" \
    nanocoder --provider "Olla" --model "${BARE_MODEL_ID}" "$@"
else
  PROMPT="Working directory: $(pwd)

$(cat)"
  # --mode yolo, not the "auto-accept" that `run` defaults to: auto-accept still
  # gates execute_bash behind an interactive "Tool approval required" prompt
  # (file-editing tools like write_file/string_replace are pre-approved, but a
  # shell call is not). With stdin already consumed by the piped prompt there's
  # nothing to answer that prompt with, so nanocoder sits waiting forever -- this
  # is what the smoke-test watchdog was catching as a 120s stall (root cause was
  # in nanocoder's own approval gating, not the proxy or the model).
  # --mode yolo bypasses all such approval prompts, matching mini-swe-agent's
  # agent.mode=yolo fix for the identical class of issue in
  # adapters/mini-swe-agent.sh.
  exec env NANOCODER_PROVIDERS="${PROVIDER_JSON}" NANOCODER_TRUST_DIRECTORY=1 \
    nanocoder --mode yolo run --provider "Olla" --model "${BARE_MODEL_ID}" "${PROMPT}" "$@"
fi
