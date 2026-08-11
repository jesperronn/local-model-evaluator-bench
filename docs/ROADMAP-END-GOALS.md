# Roadmap — end goals

Two end goals for this project, in dependency order. Goal 2 is built on top of
whatever goal 1 finds — it doesn't make sense to pick an orchestrator before
knowing which local backends are worth orchestrating.

Related: [TASKS.md](../TASKS.md) · [README.md](../README.md) ·
[DECISION-subagent-orchestrator-candidates.md](DECISION-subagent-orchestrator-candidates.md)

---

## Goal 1 — find the best tool(s) to work with local-only models

This is the project's original purpose and is already substantially built:
`adapters/` (per-CLI × per-runtime scripts), `bin/bench`, `cases/`,
`compat.json`, `LEADERBOARD.md`. Not re-litigated here — see README.md and
TASKS.md for current status. Output of this goal is a ranked shortlist of
CLI-agent + local-runtime combos (e.g. aider+ollama, opencode+lms, pi+omlx)
that reliably pass the case suite.

**Hard constraint:** local runtimes only (lms/ollama/mlx/omlx). No cloud
providers get added as *evaluated* backends — see the user's standing
[[feedback_local_models_only]] rule. Cloud CLIs (Claude Code, Codex, Gemini)
only appear in this repo as a bar to compare against, or later, as the
*orchestrator* layer in goal 2 if the orchestrator itself proves cheap enough
to run against a cloud model without violating the point of the exercise —
undecided, see open questions below.

## Goal 2 — find the best tool for orchestrating subagents

New as of 2026-08-11. The ask: an orchestrator that

1. **delegates** work to subagents (either the same harness spawning a
   fresh-context subagent, e.g. Claude Code's Task tool, or a separate
   preconfigured agent process, e.g. an orchestrator calling `pi`),
2. **verifies** the subagent's work (tests, lint, types — not just "did it
   claim success"),
3. is able to make **decisions in the orchestrator layer** based on that
   verification (retry, re-route to a different backend/model, escalate,
   accept, revert).

The subagents being orchestrated are expected to be — or eventually become —
the local-model combos goal 1 finds, so the orchestrator itself needs to be
runnable locally, or at minimum not defeat the token-cost/secret-leak
motivation below by forcing cloud calls at the orchestration layer.

### Why (motivation, carried over from the project's original framing)

Run as many of the tedious/repetitive parts of a coding task as possible on
small local agents so we don't spend unnecessary token cost and don't
accidentally leak secrets to a cloud model. The orchestrator's job is to keep
a human (or a cheap/no-cost coordination layer) in control of *which* backend
sees a given subtask, and to catch bad output before it's trusted.

### What's already built toward this (found while surveying, 2026-08-11)

- [adapters/opencode-orch-lms.sh](../adapters/opencode-orch-lms.sh) — a
  working proof of concept. Configures opencode with a delegate-only
  "orchestrator" primary (edit/write/bash denied, can only invoke the `coder`
  subagent via the task tool) + a `coder` subagent (edit/write/bash allowed).
  Parses opencode's JSON event stream for task-tool spawns, writes a
  `.delegation` marker.
- [lib/delegation-check.sh](../lib/delegation-check.sh) — reads that marker
  and emits a diagnostic `CHECK pass/fail delegated to subagent (N spawned)`
  line folded into `checks.csv`. Baseline (non-orch) adapters leave no
  marker — absence itself records "did not delegate."
- [cases/deleg-01-validate-format-pipeline](../cases/deleg-01-validate-format-pipeline)
  — the first case wired to this: a 3-file JS task (validate → format →
  pipeline) with real `node --test` assertions as the authoritative
  pass/fail, plus the delegation diagnostic layered on top. This is the
  template for testing goal 2 — task success stays authoritative and
  comparable across baseline vs. orchestrator adapters; delegation is a
  separate diagnostic axis, not a scoring hack.

### Confirmed subagent-support matrix (as tested so far)

| Tool | Native subagent/delegate primitive? | Notes |
|---|---|---|
| Claude Code | Yes | `.claude/agents/*.md` + Task tool |
| omp (oh-my-pi) | Untested | pi fork "with enhanced coding agent features" — worth checking for a task/delegate flag |
| pi | No | confirmed no subagent primitive — useful as the negative control |
| opencode | Yes | `mode: primary`/`mode: subagent` + task tool; already has a working orch adapter (above) |

### Orchestrator-layer candidates surveyed (2026-08-11)

See [DECISION-subagent-orchestrator-candidates.md](DECISION-subagent-orchestrator-candidates.md)
for the full writeup. Summary:

- **bernstein** — kept and functional. Local, no-cloud-required, deterministic
  coordination (no model in the loop), plain-signal "janitor" verification
  (tests/lint/types). Hit a real startup bug in the bare `bernstein` command
  (splash path races a fixed 10s wait against a discovery scan that takes
  ~13s with 17 CLI adapters installed) — root-caused and worked around: use
  `bernstein run --goal "..." --cli <adapter> [--dry-run]` (or `doctor`,
  `agents list`), never the bare `bernstein`/`bernstein --dry-run` form. See
  decision doc for the full trace.
- **omnigent (`omni`)** — kept, with caveats. Meta-harness with a
  `--harness pi` mode confirmed to run fully local against Ollama, and a
  bundled `polly` orchestrator — but `polly` **defaults to the Claude
  subscription (cloud)** unless `--harness`/`--model` are forced explicitly.
  Any use of `omni polly` in this repo's adapters/cases must pin those flags.
  Both `omni pi` and `omni polly --harness pi` need a real TTY (tmux
  attach) — no plain-pipe non-interactive mode.
- **toryo** — kept, not yet installed/tested. Chains Claude Code/Aider/
  Gemini CLI/Ollama/Cline; local-capable per its own docs when Ollama is the
  backend. Has a more opinionated self-improving-loop policy (trust score,
  auto-revert below threshold, retry loop) worth comparing against
  bernstein's plainer pass/fail janitor.
- **superpowers** (obra/superpowers) — kept as a *skills layer*, not an
  orchestrator. Installed into `~/.agents/skills/` (2026-08-11) so any
  harness that reads that directory picks the skills up directly. No
  evidence it works with local models specifically, but it's just Markdown
  skill definitions — no cloud dependency of its own. Provides the
  self-verification vocabulary (RED-GREEN-REFACTOR, subagent-driven
  development, verification-before-completion) that an orchestrator's
  "verify" step (point 2 above) should implement. Not yet classified into
  which skills belong on the orchestrator side vs. the subagent side — open
  task.
- **handoff** — eliminated. Requires real API accounts (DeepSeek/OpenAI/
  Anthropic) to delegate — cloud-dependent in the same way as humanlayer.
- **fractal** — eliminated. Cost/depth-cap framing implies metered cloud
  model usage; no local-only mode documented.
- **sub-agents-skills** — kept as a *format* reference (portable Markdown
  routing rules), not something to run/test on its own.

### Open questions

- Can `omp` delegate to a subagent at all? Not yet checked.
- Bernstein's startup-discovery bug is confirmed genuine (13s scan vs. fixed
  10s wait, only in the bare-command path) and worked around via
  `bernstein run`/subcommands — worth reporting upstream, not yet done.
- Is it acceptable for the *orchestrator* layer to call a cloud model (cheap,
  infrequent coordination calls) as long as *subagents* stay local, or does
  the token-cost/secret-leak motivation require the orchestrator to be local
  too? Affects whether Claude Code / `omni polly` (bare) are viable
  orchestrators or must be excluded like the local-only rule excludes them
  from goal 1.
- Vocabulary page (agent/harness/runtime/model/subagent/orchestrator/MoE
  etc., scoped to how this repo actually uses the terms) — requested
  2026-08-11, not yet written.

### Next steps (unordered, pick based on what's blocking)

1. Classify the 14 superpowers skills into orchestrator-side vs.
   subagent-side.
2. Write the vocabulary page.
3. Build a bernstein-driven version of `deleg-01` (or a new case) using
   `bernstein run --cli <adapter>` (never the bare form) and its `janitor`
   verification against a local adapter (aider/opencode pointed at
   Ollama/LM Studio).
4. Install and smoke-test toryo the same way `omni`/bernstein were tested.
5. Check whether `omp` has any delegate/task primitive.
6. Build `adapters/claude-orch-*.sh` mirroring `opencode-orch-lms.sh`, using
   Claude Code's native Task tool + a project-local restricted subagent.
