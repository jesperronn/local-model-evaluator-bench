#!/usr/bin/env bash
# Adapter: caveman -> LM Studio.
# caveman is a `pi`-based agent. Custom providers live in ~/.pi/agent/models.json;
# we define an `lmstudio` provider there (baseUrl http://localhost:1234/v1,
# api openai-completions) and select it by name. See docs/SETUP.md.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# caveman runs on pi's runtime, so it inherits pi's edit tool and the same
# nested-schema × flat-XML failure. Reapply the recovery shim (idempotent).
# See docs/tools/pi.md (Known issues) and docs/SCORING.md (Workarounds).
"$REPO_ROOT/bin/pi-patch-edit-shim" >/dev/null 2>&1 ||
  echo "warn: pi edit-tool shim not applied (see docs/tools/pi.md)" >&2

CAVEMAN_ARGS=(--provider lmstudio --model "$MODEL_ID")
if [ ! -t 0 ]; then
  CAVEMAN_ARGS+=(--print "$(cat)")
fi

exec caveman "${CAVEMAN_ARGS[@]}" "$@"
