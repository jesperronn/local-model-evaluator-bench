#!/usr/bin/env bash
# Adapter: opencode ORCHESTRATOR variant -> unified endpoint via LiteLLM proxy.
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
# Routes through the LiteLLM proxy ($LITELLM_BASE_URL) to any local runtime
# (lms, ollama, mlx, omlx, mtplx) based on model ID prefix.
#
# Adapter accepts --provider to override which backend to target:
#   --provider lms        # route to LM Studio (default if lms/ prefix)
#   --provider ollama     # route to Ollama
#   --provider omlx       # route to oMLX
#   --provider mlx        # route to mlx_lm.server
#   --provider mtplx      # route to MTPLX
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
PROVIDER="${PROVIDER:-lms}"

# Parse --provider flag if passed
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

command -v opencode >/dev/null 2>&1 || {
  echo "opencode not found; install via package manager" >&2
  exit 1
}

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai|lmstudio)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  # Special case: "lms" maps to "lmstudio" for opencode
  if [ "$PROVIDER" = "lms" ]; then
    PREFIXED_MODEL_ID="lmstudio/${MODEL_ID}"
  else
    PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
  fi
fi

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
