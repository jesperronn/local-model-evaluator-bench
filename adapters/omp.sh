#!/usr/bin/env bash
# Adapter: omp (oh-my-pi) -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching or hardcoded model list is needed here
# (unlike the previous proxy-routed version of this file).
#
# omp's `--config` flag only overlays config.yml-style *settings* for a run —
# confirmed empirically it does NOT register a new model-registry provider
# (`omp models --config <overlay>` still shows only the providers already in
# ~/.omp/agent/models.yml, however that overlay is shaped). Provider
# registration only happens through models.yml itself, and the default
# profile's models.yml is a symlink into the user's own dotfiles — not
# something an adapter should silently rewrite. So this adapter uses an
# isolated `--profile bench-olla` (omp's own mechanism for a separate
# auth/sessions/settings/caches sandbox — see `omp --help`) and self-heals
# *that* profile's own (non-symlinked) models.yml with an "olla" provider
# using `discovery.type: openai-models-list`, so omp queries Olla's live
# /models list itself at startup — same live-discovery behavior as the
# other adapters, without touching the user's real omp config.
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id, and omp addresses the olla provider's models the
# same way ("olla/<bare-id>").
#
# Install: npm install -g @oh-my-pi/pi-coding-agent (or: brew install omp)
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v omp >/dev/null 2>&1 || {
  echo "omp not found; install: npm install -g @oh-my-pi/pi-coding-agent" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# Isolated profile so this adapter never touches the user's own
# ~/.omp/agent/models.yml (that file is commonly a dotfiles symlink).
OMP_PROFILE="bench-olla"
OMP_PROFILE_MODELS="$HOME/.omp/profiles/$OMP_PROFILE/agent/models.yml"
mkdir -p "$(dirname "$OMP_PROFILE_MODELS")"
if [ ! -f "$OMP_PROFILE_MODELS" ]; then
  cat > "$OMP_PROFILE_MODELS" <<YAML
providers:
  olla:
    baseUrl: $OLLA_BASE_URL
    api: openai-completions
    auth: none
    discovery:
      type: openai-models-list
YAML
fi

OMP_ARGS=(
  --profile "$OMP_PROFILE"
  --model "olla/${BARE_MODEL_ID}"
  --auto-approve
)

# Ornith-specific optimization: reduce verbose reasoning output
# Only apply --thinking=low to Ornith models; other models may not support it
if [[ "$BARE_MODEL_ID" =~ ornith|Ornith ]]; then
  OMP_ARGS+=(--thinking=low)
fi

if [ ! -t 0 ]; then
  exec omp "${OMP_ARGS[@]}" -p "$(cat)"
else
  exec omp "${OMP_ARGS[@]}" "$@"
fi
