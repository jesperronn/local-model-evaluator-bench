#!/usr/bin/env bash
# Adapter: caveman -> LM Studio.
# Tool: caveman-code (npm, @juliusbrussee/caveman-code 0.65.2), fixed 2026-07-07.
#
# caveman-code IS its own package (not pi-based anymore) with its own custom
# provider config at ~/.cave/agent/models.json (schema: {providers: {name:
# {baseUrl, api, apiKey, models:[{id}]}}} — same shape as pi's models.json).
# It DOES support local providers via --provider <name>; what was actually
# broken (2026-06-28 to 2026-07-07) was that ~/.cave/agent/models.json didn't
# exist: the dotfiles symlink at ~/.cave/agent/models.json pointed at
# link-file/.cave/agent/models.json, which had never been created for the
# caveman-code package (only the pi equivalent existed). Once that file exists
# with an "lmstudio" provider entry, --provider lmstudio works exactly like pi.
# See docs/tools/caveman.md (Known issues) for the full history.
#
# Install: npm install -g @juliusbrussee/caveman-code
# Config template: config-templates/caveman-agent-models.json (kept in sync
# with installed LM Studio models the same way pi's is — see bin/agents-config).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v caveman >/dev/null 2>&1 || {
  echo "caveman not found; install: npm install -g @juliusbrussee/caveman-code" >&2
  exit 1
}

CAVE_LIVE_CFG="$HOME/.cave/agent/models.json"
if [ ! -f "$CAVE_LIVE_CFG" ] || ! jq -e '.providers.lmstudio' "$CAVE_LIVE_CFG" >/dev/null 2>&1; then
  echo "warn: $CAVE_LIVE_CFG missing an lmstudio provider — copying config-templates/caveman-agent-models.json" >&2
  mkdir -p "$(dirname "$CAVE_LIVE_CFG")"
  cp "$REPO_ROOT/config-templates/caveman-agent-models.json" "$CAVE_LIVE_CFG"
fi

CAVEMAN_ARGS=(--provider lmstudio --model "$MODEL_ID")

if [ ! -t 0 ]; then
  exec caveman "${CAVEMAN_ARGS[@]}" --print "$(cat)"
else
  exec caveman "${CAVEMAN_ARGS[@]}" "$@"
fi
