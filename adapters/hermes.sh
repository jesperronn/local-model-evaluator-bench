#!/usr/bin/env bash
# Adapter: hermes -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching is needed here (unlike the previous
# proxy-routed version of this file).
#
# Hermes has no built-in Olla provider, so this adapter self-heals a
# `providers.olla` custom-provider block into the user's own
# ~/.hermes/config.yaml (same self-heal pattern used for omlx/mtplx before —
# see config-templates/hermes-config.snippet.yaml) and addresses it as
# `--provider custom:olla`.
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Install: https://docs.hermes.ai/install
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v hermes >/dev/null 2>&1 || {
  echo "hermes not found; install: https://docs.hermes.ai/install" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# Self-heal: ensure ~/.hermes/config.yaml has a "providers.olla" custom
# provider block pointed at Olla. Hermes doesn't discover providers over
# HTTP, so this must exist before `--provider custom:olla` will resolve.
HERMES_CFG="${HERMES_CFG:-$HOME/.hermes/config.yaml}"
if [ -f "$HERMES_CFG" ] && ! grep -q '^  olla:' "$HERMES_CFG"; then
  awk -v url="$OLLA_BASE_URL" -v key="$OLLA_API_KEY" '
    /^providers:/ {
      print
      print "  olla:"
      print "    name: Olla"
      print "    base_url: " url
      print "    api_key: " key
      print "    api_mode: chat_completions"
      next
    }
    { print }
  ' "$HERMES_CFG" > "$HERMES_CFG.tmp" && mv "$HERMES_CFG.tmp" "$HERMES_CFG"
fi

# -t file,terminal: both toolsets work together since v0.17.0 (the tool-name
# conflict present in v0.16.0 is fixed). Enables write_file, patch, read_file,
# search_files, process, AND direct shell execution via terminal.
HERMES_ARGS=(--provider "custom:olla" -m "$BARE_MODEL_ID" -t file,terminal)

if [ ! -t 0 ]; then
  # Interactive approval mode: the smart guardian will ask for confirmations
  # on potentially risky actions. This provides safety signals during automation.
  HERMES_ARGS+=(-z "$(cat)")
fi

exec hermes "${HERMES_ARGS[@]}" "$@"
