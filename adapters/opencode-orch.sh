#!/usr/bin/env bash
# Adapter: opencode ORCHESTRATOR variant -> unified endpoint via Olla proxy
# (OpenAI format).
#
# Experiment (subagent-delegation): does a small local model complete a
# multi-file task better when the main agent is FORBIDDEN from editing and must
# delegate every change to a fresh-context subagent? This variant configures a
# delegate-only primary ("orchestrator": permission.edit/write/bash = deny, may
# only spawn the `coder` subagent via the task tool) plus a "coder" subagent
# (edit/write/bash = allow). Both are project-local under the sandbox's
# .opencode/agent/, so they never leak into the user's global config.
#
# "Main makes zero direct edits" is CONFIG-ENFORCED here (the primary has no
# edit tools), so verification reduces to: was a subagent actually spawned?
# After the run we parse opencode's JSON event stream and write a `.delegation`
# marker the case grader (lib/delegation-check.sh) folds into checks.csv.
#
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models under one unified list, but opencode's own provider
# config is static (see docs/tools/opencode.md), so this adapter self-heals
# an "olla" custom provider block into the user's live opencode config and
# refreshes its "models" map from Olla's live /models list on every run — see
# adapters/opencode.sh for the same steps, in more detail.
#
# Compare against the single-agent baseline adapters/opencode.sh.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
#
# NOTE (first-run calibration): the subagent-spawn detection below is a
# heuristic grep over the JSON events. The full raw stream is preserved at
# .opencode-events.json in the sandbox — inspect it on the first real run to
# confirm/tighten the pattern for the opencode version in use (see docs).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v opencode >/dev/null 2>&1 || {
  echo "opencode not found; install via package manager" >&2
  exit 1
}

olla_up || {
  echo "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)" >&2
  exit 1
}

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"

# ── Ensure the live opencode config has an "olla" provider (see
#    adapters/opencode.sh for the detailed rationale). ──────────────────────
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

if ! grep -q '"olla"[[:space:]]*:' "$OPENCODE_CFG"; then
  OLLA_PROVIDER_JSON="$(jq -n --arg url "$OLLA_BASE_URL" --arg key "$OLLA_API_KEY" \
    '{npm: "@ai-sdk/openai-compatible", name: "Olla", options: {baseURL: $url, apiKey: $key}, models: {}}')"
  node "$REPO_ROOT/bin/lib/patch-jsonc-models.mjs" set "$OPENCODE_CFG" provider.olla "$OLLA_PROVIDER_JSON" \
    > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"
fi

OLLA_MODELS_JSON="$(runtime_models "$OLLA_BASE_URL" "$OLLA_API_KEY" | jq -R -s -c \
  'split("\n") | map(select(length > 0)) | map({(.): {name: .}}) | add // {}')"
node "$REPO_ROOT/bin/lib/patch-jsonc-models.mjs" write "$OPENCODE_CFG" olla "$OLLA_MODELS_JSON" \
  > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"

PREFIXED_MODEL_ID="olla/${BARE_MODEL_ID}"

# --- delegate-only agent definitions (project-local, sandbox-scoped) ----------
mkdir -p .opencode/agent

cat > .opencode/agent/orchestrator.md <<'EOF'
---
description: Delegate-only orchestrator. Plans and routes work to the coder subagent; never edits files itself.
mode: primary
permission:
  edit: deny
  write: deny
  bash: deny
  task:
    "*": deny
    coder: allow
---
You are an orchestrator. You must NOT edit, write, or run files yourself — you
have no edit/write/bash tools. Break the task into concrete per-file subtasks
and delegate each to the `coder` subagent via the task tool, giving it the exact
file path and the precise change required. After the coder reports back, read
the files to verify, then delegate any remaining work. Continue until the whole
task is complete.
EOF

cat > .opencode/agent/coder.md <<'EOF'
---
description: Implements a single, well-scoped code change in one file.
mode: subagent
permission:
  edit: allow
  write: allow
  bash: allow
---
You implement exactly the change described in your task prompt. Edit the named
file(s) to satisfy the requirement, keep existing exports intact, and report a
one-line summary when done.
EOF

PROMPT="Working directory: $(pwd)

$(cat)"

events=".opencode-events.json"

# --auto approves permissions not explicitly denied; the orchestrator's
# edit/write/bash denials still hold, forcing delegation. --format json streams
# raw events we parse for task-tool (subagent) spawns.
set +e
opencode run --agent orchestrator --auto --format json \
  --model "$PREFIXED_MODEL_ID" "${PROMPT}" | tee "$events"
rc=${PIPESTATUS[0]}
set -e

# --- delegation detection -----------------------------------------------------
# Heuristic: count task-tool invocations in the JSON event stream. Matches the
# tool name "task" appearing as a JSON string value (config prose lives in the
# .md files above, not in this stream). Confirm the exact shape against
# .opencode-events.json on first run and tighten if needed.
subagents=0
if [ -f "$events" ]; then
  subagents=$(grep -oiE '"(tool|name)"[[:space:]]*:[[:space:]]*"task"' "$events" 2>/dev/null | wc -l | tr -d ' ')
fi
printf 'subagents=%s\n' "${subagents:-0}" > .delegation

exit "$rc"
