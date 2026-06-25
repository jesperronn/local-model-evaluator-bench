#!/usr/bin/env bash
# Adapter: pi -> Ollama.
# Requires ~/.pi/agent/models.json to have an "ollama" provider entry with
# the target models listed (pi builds its provider registry from that file).
# Install: npm install -g @earendil-works/pi-coding-agent
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v pi >/dev/null 2>&1 || {
  echo "pi not found; install: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
}

# Reapply the qwen3-coder edit-tool XML-recovery shim if missing (idempotent,
# fast no-op when already patched). pi is a global npm install, so the patch is
# wiped on upgrade — reapply per run so scored pi runs stay reproducible.
# See docs/tools/pi.md (Known issues) and docs/SCORING.md (Workarounds).
"$REPO_ROOT/bin/pi-patch-edit-shim" >/dev/null 2>&1 ||
  echo "warn: pi edit-tool shim not applied (see docs/tools/pi.md)" >&2

PI_ARGS=(--provider ollama --model "$MODEL_ID")

if [ ! -t 0 ]; then
  exec pi "${PI_ARGS[@]}" -p "$(cat)"
else
  exec pi "${PI_ARGS[@]}" "$@"
fi
