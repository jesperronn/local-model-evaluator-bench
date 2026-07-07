#!/usr/bin/env bash
# Adapter: caveman -> Ollama.
# Tool: caveman-code (npm, @juliusbrussee/caveman-code 0.65.2), fixed 2026-07-07.
#
# Requires ~/.cave/agent/models.json to have an "ollama" provider entry with
# the target models listed (caveman-code builds its provider registry from
# that file — same schema as pi's ~/.pi/agent/models.json). This was missing
# entirely until 2026-07-07 (see docs/tools/caveman.md, Version history), which
# made every provider name — including "ollama" — resolve to nothing.
#
# Install: npm install -g @juliusbrussee/caveman-code
# Config template: config-templates/caveman-agent-models.json (kept in sync by
# bin/agents-config --agent caveman, same as pi's).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v caveman >/dev/null 2>&1 || {
  echo "caveman not found; install: npm install -g @juliusbrussee/caveman-code" >&2
  exit 1
}

CAVE_LIVE_CFG="$HOME/.cave/agent/models.json"
if [ ! -f "$CAVE_LIVE_CFG" ] || ! jq -e '.providers.ollama' "$CAVE_LIVE_CFG" >/dev/null 2>&1; then
  echo "warn: $CAVE_LIVE_CFG missing an ollama provider — copying config-templates/caveman-agent-models.json" >&2
  mkdir -p "$(dirname "$CAVE_LIVE_CFG")"
  cp "$REPO_ROOT/config-templates/caveman-agent-models.json" "$CAVE_LIVE_CFG"
fi

CAVEMAN_ARGS=(--provider ollama --model "$MODEL_ID")

if [ ! -t 0 ]; then
  exec caveman "${CAVEMAN_ARGS[@]}" --print "$(cat)"
else
  exec caveman "${CAVEMAN_ARGS[@]}" "$@"
fi
