#!/usr/bin/env bash
# Adapter: caveman -> oMLX.
# Unlike caveman-mlx.sh (stub — mlx_lm.server used raw HF-repo/path ids that
# caveman's model list can't register as a new provider), oMLX's provider
# entry works the same way pi's does: a named "omlx" provider in caveman's own
# ~/.cave/agent/models.json with a directory-basename model id
# (Ornith-1.0-35B-4bit), which caveman resolves like any other catalog entry.
# Start the server first: bin/omlx start
# Config template: config-templates/caveman-agent-models.json (kept in sync
# with installed oMLX models by bin/agents-config, once the omlx block exists —
# see docs/RUNTIME-OMLX.md).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v caveman >/dev/null 2>&1 || {
  echo "caveman not found; install: npm install -g @juliusbrussee/caveman-code" >&2
  exit 1
}

CAVE_LIVE_CFG="$HOME/.cave/agent/models.json"
if [ ! -f "$CAVE_LIVE_CFG" ] || ! jq -e '.providers.omlx' "$CAVE_LIVE_CFG" >/dev/null 2>&1; then
  echo "warn: $CAVE_LIVE_CFG missing an omlx provider — copying config-templates/caveman-agent-models.json" >&2
  mkdir -p "$(dirname "$CAVE_LIVE_CFG")"
  cp "$REPO_ROOT/config-templates/caveman-agent-models.json" "$CAVE_LIVE_CFG"
fi

CAVEMAN_ARGS=(--provider omlx --model "$MODEL_ID")

if [ ! -t 0 ]; then
  exec caveman "${CAVEMAN_ARGS[@]}" --print "$(cat)"
else
  exec caveman "${CAVEMAN_ARGS[@]}" "$@"
fi
