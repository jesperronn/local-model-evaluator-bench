#!/usr/bin/env bash
# Adapter: caveman -> Ollama.
# Uses the `ollama` provider defined in ~/.pi/agent/models.json
# (baseUrl http://localhost:11434/v1, api openai-completions).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# caveman runs on pi's runtime, so it inherits pi's edit tool and the same
# nested-schema × flat-XML failure. Reapply the recovery shim (idempotent).
# See docs/tools/pi.md (Known issues) and docs/SCORING.md (Workarounds).
"$REPO_ROOT/bin/pi-patch-edit-shim" >/dev/null 2>&1 ||
  echo "warn: pi edit-tool shim not applied (see docs/tools/pi.md)" >&2

CAVEMAN_ARGS=(--provider ollama --model "$MODEL_ID" --thinking off)
if [ ! -t 0 ]; then
  CAVEMAN_ARGS+=(--print "$(cat)")
fi

exec caveman "${CAVEMAN_ARGS[@]}" "$@"
