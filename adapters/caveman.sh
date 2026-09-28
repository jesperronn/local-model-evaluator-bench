#!/usr/bin/env bash
# Adapter: caveman -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching, provider selection, or hardcoded model list
# is needed here (unlike the previous proxy-routed version of this file).
#
# caveman-code is a pi fork and reads the same
# {providers: {name: {baseUrl, api, apiKey, models:[{id}]}}} schema from
# ~/.cave/agent/models.json (see docs/tools/caveman.md) — this adapter merges
# an "olla" provider into that live file on every run, populated from Olla's
# own live /models list, mirroring adapters/pi.sh's models.json handling.
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Install: npm install -g @juliusbrussee/caveman-code
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v caveman >/dev/null 2>&1 || {
  echo "caveman not found; install: npm install -g @juliusbrussee/caveman-code" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

OLLA_MODELS_JSON="$(runtime_models "$OLLA_BASE_URL" | jq -R -s -c 'split("\n") | map(select(length > 0)) | map({id: .})')"
[ -z "$OLLA_MODELS_JSON" ] && OLLA_MODELS_JSON='[]'

RUNTIME_CONFIG="$(jq -n \
  --arg baseUrl "$OLLA_BASE_URL" \
  --arg apiKey "$OLLA_API_KEY" \
  --argjson models "$OLLA_MODELS_JSON" \
  '{baseUrl: $baseUrl, api: "openai-completions", apiKey: $apiKey, models: $models}')"

# Merge the olla provider config into caveman's live models.json (self-heals
# the file/directory if missing, mirroring adapters/pi.sh).
CAVEMAN_LIVE_CFG="$HOME/.cave/agent/models.json"
mkdir -p "$(dirname "$CAVEMAN_LIVE_CFG")"

if [ -f "$CAVEMAN_LIVE_CFG" ]; then
  jq --argjson cfg "$(echo "$RUNTIME_CONFIG" | jq .)" '.providers["olla"] = $cfg' "$CAVEMAN_LIVE_CFG" > "$CAVEMAN_LIVE_CFG.tmp" && mv "$CAVEMAN_LIVE_CFG.tmp" "$CAVEMAN_LIVE_CFG"
else
  echo "{\"providers\": {\"olla\": $(echo "$RUNTIME_CONFIG" | jq .)}}" | jq . > "$CAVEMAN_LIVE_CFG"
fi

CAVEMAN_ARGS=(
  --provider olla
  --model "$BARE_MODEL_ID"
)

# Ornith-specific optimization: reduce verbose reasoning output
# Only apply --thinking=low to Ornith models; other models may not support it
if [[ "$BARE_MODEL_ID" =~ ornith|Ornith ]]; then
  CAVEMAN_ARGS+=(--thinking low)
fi

if [ ! -t 0 ]; then
  exec caveman "${CAVEMAN_ARGS[@]}" --print "$(cat)"
else
  exec caveman "${CAVEMAN_ARGS[@]}" "$@"
fi
