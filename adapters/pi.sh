#!/usr/bin/env bash
# Adapter: pi -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching and no hardcoded model list are needed here
# (unlike the old LiteLLM-routed version of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Install: npm install -g @earendil-works/pi-coding-agent
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v pi >/dev/null 2>&1 || {
  echo "pi not found; install: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# RUNTIME=splash (set by bin/bench for splash/<id> models): talk to the splash
# server directly, bypassing Olla (not registered there). See docs/tools/splash.md.
if [ "${RUNTIME:-}" = "splash" ]; then
  splash_up || { echo "splash not reachable at $SPLASH_BASE_URL (user starts it)" >&2; exit 1; }
  PROV_NAME="splash"; PROV_URL="$SPLASH_BASE_URL"; PROV_KEY="$SPLASH_API_KEY"
else
  olla_up || {
    echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
    exit 1
  }
  PROV_NAME="olla"; PROV_URL="$OLLA_BASE_URL"; PROV_KEY="$OLLA_API_KEY"
fi

# pi only recognizes a provider (and lists its models via --list-models) when
# its models.json entry has a non-empty `models` array — unlike Olla itself,
# pi's own config is static, so it can't be left empty and rely on Olla's
# discovery alone. Populate it from Olla's live /models list on every run
# instead of a hardcoded list, so it never goes stale as models come and go.
OLLA_MODELS_JSON="$(runtime_models "$PROV_URL" | jq -R -s -c 'split("\n") | map(select(length > 0)) | map({id: .})')"
[ -z "$OLLA_MODELS_JSON" ] && OLLA_MODELS_JSON='[]'

RUNTIME_CONFIG="$(jq -n \
  --arg baseUrl "$PROV_URL" \
  --arg apiKey "$PROV_KEY" \
  --argjson models "$OLLA_MODELS_JSON" \
  '{baseUrl: $baseUrl, api: "openai-completions", apiKey: $apiKey, models: $models}')"

# Merge the olla provider config into pi's live models.json.
PI_LIVE_CFG="$HOME/.pi/agent/models.json"
mkdir -p "$(dirname "$PI_LIVE_CFG")"

if [ -f "$PI_LIVE_CFG" ]; then
  jq --arg prov "$PROV_NAME" --argjson cfg "$(echo "$RUNTIME_CONFIG" | jq .)" '.providers[$prov] = $cfg' "$PI_LIVE_CFG" > "$PI_LIVE_CFG.tmp" && mv "$PI_LIVE_CFG.tmp" "$PI_LIVE_CFG"
else
  echo "{\"providers\": {\"$PROV_NAME\": $(echo "$RUNTIME_CONFIG" | jq .)}}" | jq . > "$PI_LIVE_CFG"
fi

# Reapply the qwen3-coder edit-tool XML-recovery shim if missing (idempotent,
# fast no-op when already patched). pi is a global npm install, so the patch is
# wiped on upgrade — reapply per run so scored pi runs stay reproducible.
# See docs/tools/pi.md (Known issues) and docs/SCORING.md (Workarounds).
"$REPO_ROOT/bin/pi-patch-edit-shim" >/dev/null 2>&1 ||
  echo "warn: pi edit-tool shim not applied (see docs/tools/pi.md)" >&2

PI_ARGS=(--provider "$PROV_NAME" --model "$BARE_MODEL_ID")

# Ornith-specific optimization: reduce verbose reasoning output
# Only apply --thinking=low to Ornith models; other models may not support it
if [[ "$BARE_MODEL_ID" =~ ornith|Ornith ]]; then
  PI_ARGS+=(--thinking low)
fi

if [ ! -t 0 ]; then
  exec pi "${PI_ARGS[@]}" -p "$(cat)"
else
  exec pi "${PI_ARGS[@]}" "$@"
fi
