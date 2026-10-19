#!/usr/bin/env bash
# Adapter: opencode -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# but opencode's own provider config is static (see docs/tools/opencode.md —
# opencode does not query a provider's endpoint live), so this adapter
# self-heals an "olla" custom provider block into the user's live
# ~/.config/opencode/opencode.jsonc (or .json) and refreshes its "models" map
# from Olla's live /models list on every run, via the comment-preserving
# bin/lib/patch-jsonc-models.mjs helper (also used by bin/agents-config for
# the other providers — invoked here, not modified).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v opencode >/dev/null 2>&1 || {
  echo "opencode not found; install via package manager" >&2
  exit 1
}

adapter_endpoint || exit 1
if [ "${RUNTIME:-}" = "splash" ]; then PROV_ID="splash"; PROV_LABEL="Splash"; else PROV_ID="olla"; PROV_LABEL="Olla"; fi

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# ── Ensure the live opencode config has an "olla" provider, seeded from
#    config-templates/opencode.json if no config exists yet at all. ─────────
OPENCODE_CFG_JSONC="$HOME/.config/opencode/opencode.jsonc"
OPENCODE_CFG_JSON="$HOME/.config/opencode/opencode.json"
if [ -f "$OPENCODE_CFG_JSONC" ]; then
  OPENCODE_CFG="$OPENCODE_CFG_JSONC"
elif [ -f "$OPENCODE_CFG_JSON" ]; then
  OPENCODE_CFG="$OPENCODE_CFG_JSON"
else
  mkdir -p "$(dirname "$OPENCODE_CFG_JSON")"
  cp "$REPO_ROOT/config-templates/opencode.json" "$OPENCODE_CFG_JSON"
  OPENCODE_CFG="$OPENCODE_CFG_JSON"
fi

if ! grep -q "\"$PROV_ID\"[[:space:]]*:" "$OPENCODE_CFG"; then
  OLLA_PROVIDER_JSON="$(jq -n --arg url "$EP_URL" --arg key "$EP_KEY" --arg name "$PROV_LABEL" \
    '{npm: "@ai-sdk/openai-compatible", name: $name, options: {baseURL: $url, apiKey: $key}, models: {}}')"
  node "$REPO_ROOT/bin/lib/patch-jsonc-models.mjs" set "$OPENCODE_CFG" "provider.$PROV_ID" "$OLLA_PROVIDER_JSON" \
    > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"
fi

# Refresh the "olla" provider's model list from Olla's own live discovery, so
# it can't go stale as models come and go (mirrors adapters/pi.sh's live
# models.json merge, adapted to opencode's {id: {name}} map shape).
OLLA_MODELS_JSON="$(runtime_models "$EP_URL" "$EP_KEY" | jq -R -s -c \
  'split("\n") | map(select(length > 0)) | map({(.): {name: .}}) | add // {}')"
node "$REPO_ROOT/bin/lib/patch-jsonc-models.mjs" write "$OPENCODE_CFG" "$PROV_ID" "$OLLA_MODELS_JSON" \
  > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"

PREFIXED_MODEL_ID="${PROV_ID}/${BARE_MODEL_ID}"

if [ -t 0 ]; then
  exec opencode --model "$PREFIXED_MODEL_ID" "$@"
else
  # Prepend CWD so the model uses real paths instead of /path/to/... placeholders.
  PROMPT="Working directory: $(pwd)

$(cat)"
  exec opencode run --model "$PREFIXED_MODEL_ID" "${PROMPT}" "$@"
fi
