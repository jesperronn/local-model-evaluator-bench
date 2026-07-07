#!/usr/bin/env bash
# Adapter: opencode ORCHESTRATOR variant -> LM Studio.
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
# Compare against the single-agent baseline adapters/opencode-lms.sh.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
#
# NOTE (first-run calibration): the subagent-spawn detection below is a
# heuristic grep over the JSON events. The full raw stream is preserved at
# .opencode-events.json in the sandbox — inspect it on the first real run to
# confirm/tighten the pattern for the opencode version in use (see docs).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

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

# opencode reads the lmstudio provider baseURL from ~/.config/opencode/opencode.json.
# The coder subagent inherits the session model passed via --model (opencode#17870
# warns subagents can otherwise fall back to the global-config model).
PROMPT="Working directory: $(pwd)

$(cat)"

events=".opencode-events.json"

# --auto approves permissions not explicitly denied; the orchestrator's
# edit/write/bash denials still hold, forcing delegation. --format json streams
# raw events we parse for task-tool (subagent) spawns.
set +e
opencode run --agent orchestrator --auto --format json \
  --model "lmstudio/${MODEL_ID}" "${PROMPT}" | tee "$events"
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
