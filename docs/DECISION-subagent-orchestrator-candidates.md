# Decision: orchestrator-layer candidates for the subagent-delegation goal

**Date:** 2026-08-11
**Status:** Ongoing — bernstein and omni smoke-tested, toryo not yet installed

## Context

[docs/ROADMAP-END-GOALS.md](ROADMAP-END-GOALS.md) goal 2 needs an orchestrator
that delegates to subagents, verifies their work, and makes decisions (retry/
re-route/accept/revert) based on that verification — ideally without
depending on a cloud model, per [[feedback_local_models_only]].

Source list surveyed: https://github.com/andyrewlee/awesome-agent-orchestrators
(fetched via a summarizing tool using a smaller model — repo URLs/claims below
were spot-checked live where noted, otherwise treat as unverified).

## Eliminated (cloud-dependent)

- **handoff** — delegates to DeepSeek/Codex/Claude; needs real API accounts.
- **fractal** — cost/depth-cap framing implies metered cloud usage, no
  local-only mode documented.
- (humanlayer, mentioned earlier in the conversation as the reason for this
  filter, was not re-surveyed here — assumed cloud/SaaS per the user's prior.)

## Kept, tested live on this machine (2026-08-11)

### omnigent (`omni`)

Already installed. `omni --help` lists real local-capable harnesses:
`pi`, `opencode`, `hermes`, `qwen`, `goose`, plus a bundled `polly`
orchestrator and a `debby` two-headed brainstorming agent.

- `omni config list` showed Pi already has a **local ollama base_url**
  credential configured (no cloud key), while Claude/Codex show subscription
  credentials as default.
- `omni pi -p "Reply with exactly: OK"` → replied `OK`, routed through the
  local Ollama credential. Confirmed local.
- `omni polly -p "Reply with exactly: OK"` (no flags) → replied `OK`, but
  per omnigent's own docs "polly... is the same agent a bare `omnigent`
  launches when a Claude credential is configured" — this run almost
  certainly used the Claude subscription (cloud), not a local model.
- `omni polly --harness pi --model qwen2.5-coder:7b -p "Reply with exactly: OK"`
  → replied `OK`. Confirmed local (forced Pi harness + local Ollama model).
- **Gotcha:** `omni pi` and `omni polly --harness pi` need a real TTY —
  they attach a tmux pane server-side. A plain piped/non-interactive call
  hangs. Workaround used here: `tmux new-session -d "omni ... > log 2>&1"`
  then `tmux capture-pane -p`.
- **Dependency:** required `tmux` on PATH (user installed it mid-session,
  2026-08-11) — not documented as a hard requirement anywhere we saw before
  hitting the error.

**Verdict:** keep. Confirmed it can run fully local through explicit flags,
including routing the bundled `pi` harness — directly relevant since pi has
no native subagent support (see roadmap doc's matrix), so `omni --harness pi`
is one candidate path to giving pi a delegate layer it doesn't have itself.
Any adapter/case built against `omni polly` must pin `--harness`/`--model`
or it silently falls back to cloud.

### bernstein

Already installed (`uv tool install bernstein`, done by the user before this
session). `bernstein doctor` detected adapters for claude, codex, aider,
copilot, opencode, qwen already on this machine; its own
`templates/capabilities/adapters.yaml` explicitly tags `adapter.ollama` as
`[private_data, untrusted_input]` — no `external_comm` — meaning bernstein's
own capability model already treats Ollama as network-egress-free, unlike
every other adapter it tags.

Setup attempted in a scratch sandbox
(`bernstein init` → `bernstein.yaml` with `cli: aider`, `budget: "$0"`,
`internal_llm_provider: none` to disable its OpenRouter fallback for
evolution/auto_decompose features):

```
preflight: internal_llm_provider is set to 'openrouter_free' but neither
OPENROUTER_API_KEY_FREE nor OPENROUTER_API_KEY_PAID is set...
```

Setting `internal_llm_provider: none` silenced that, but `bernstein
--dry-run` then crashed:

```
File ".../bernstein/cli/main.py", line 837, in cli
    _bg = _splash_future.result(timeout=10)
concurrent.futures._base.TimeoutError
```

Root cause traced into the installed package: `_background_startup()`
(`bernstein/cli/main.py`) calls `discover_agents_cached()`
(`bernstein/core/agents/agent_discovery.py`), which probes every CLI it finds
via `subprocess.run(..., timeout=_PROBE_TIMEOUT_S)` per adapter (each wrapped
in `suppress(Exception)`, so individual probe failures don't surface). With
7+ CLI agents installed on this machine, the *sum* of per-probe timeouts
appears to exceed the outer `_splash_future.result(timeout=10)` in
`main.py`, and that outer timeout is **not** caught — it crashes the whole
CLI on every invocation, dry-run or not.

**Root cause confirmed, not just correlated:** timed `discover_agents()`
directly via the installed venv's `python3` — 17 CLI adapters found on this
machine's PATH (aider, claude, cline, codex, copilot, forge, goose, gptme,
hermes, junie, kilo, ollama, open_interpreter, opencode, openhands, pi, qwen),
`scan_time_ms` **13336ms**. That's not one probe hanging — it's 17 sequential
`subprocess.run(..., timeout=3.0)` calls (`_PROBE_TIMEOUT_S = 3.0` in
`agent_discovery.py`) each taking a normal fraction of a second, summing past
the *fixed, unconfigurable* `_splash_future.result(timeout=10)` in
`bernstein/cli/main.py:837`. No env var (`BERNSTEIN_TIMEOUT` is a *task*
execution setting, unrelated) or config key skips/bounds this scan. Trimming
PATH doesn't reliably help either — most of these binaries live in the same
shared `/opt/homebrew/bin`, so excluding one drags out others.

**Not actually about local-model speed** — the probes are CLI
`--version`/auth-status checks, not model inference calls. It's a fixed
10s UI budget vs. linear-in-installed-adapter-count discovery, and this
repo's whole premise (many local CLI adapters installed at once) is exactly
what triggers it.

**Workaround found — use it:** the buggy wait only lives in the *bare*
`bernstein` invocation path (`cli/main.py`, guarded by
`if ctx.invoked_subcommand is not None: return` — i.e. it only runs when
**no** subcommand was given). Real subcommands bypass it entirely and were
already working fine before this was diagnosed: `bernstein doctor`,
`bernstein agents list/sync`, and — confirmed live —
`bernstein run --goal "..." --cli aider --dry-run`, which produced a normal
scheduling-plan table with no crash. **Verdict: kept, and functional** —
always invoke via `bernstein run [--goal ... | plan.yaml] --cli <adapter>
[--dry-run]`, never the bare `bernstein` / `bernstein --dry-run` form, until
upstream fixes the splash-path timeout.

## Kept, not yet tested

- **toryo** (`npx @jweigel/toryo`) — chains Claude Code, Aider, Gemini CLI,
  Ollama, Codex CLI, Cursor CLI, Cline CLI. Docs state "no mandatory cloud
  account needed if using Ollama locally." Trust-ratchet mechanism:
  `Trust = min(avg_score / 10, 1.0)`, three autonomy tiers (Supervised
  <0.6, Guided 0.6–0.8, Autonomous ≥0.8), commits at score ≥6.0 with
  automatic git revert below that plus a "Ralph Loop" retry. This is a more
  opinionated self-improving-loop policy than bernstein's plain pass/fail
  janitor — worth comparing head-to-head once installed.
- **sub-agents-skills** — not a runner, a Markdown routing-rule format
  (backend/model/permission-set per task). Reference for how to *express*
  routing decisions, not something to smoke-test on its own.

## Not an orchestrator: superpowers

[obra/superpowers](https://github.com/obra/superpowers) is a skills library
(14 skill directories, e.g. `subagent-driven-development`,
`verification-before-completion`, `test-driven-development`,
`dispatching-parallel-agents`), not a runner/dispatcher. Installed into
`~/.agents/skills/` on 2026-08-11 via a shallow clone
(`git clone --depth 1 https://github.com/obra/superpowers /tmp/superpowers-src`,
then copied each `skills/*` dir into `~/.agents/skills/`) so any harness that
reads that path picks them up directly — matches this machine's existing
convention (`~/.agents/skills/` already held unrelated skills like
`bash-shell-testing`, `check`, `spec` before this).

No evidence found (nor expected — it's just prompts) that it depends on or is
restricted to Claude specifically; all install examples in its README target
commercial platforms, but the mechanism (Markdown skill files) is host-agnostic.

Not yet done: classifying which of the 14 skills apply to the *orchestrator*
role (e.g. `dispatching-parallel-agents`, `receiving-code-review`,
`verification-before-completion`) vs. the *subagent* role (e.g.
`test-driven-development`, `systematic-debugging`, `executing-plans`) — see
roadmap doc's open questions.

## Confirmed subagent support / non-support (control group)

- **pi** — confirmed no native subagent primitive. This is the negative
  control for the whole experiment: any orchestrator layer we pick should be
  able to *add* delegation to pi (e.g. via `omni --harness pi` acting as the
  dispatcher) even though pi itself can't do it.
- **omp** — not yet checked for a delegate/task primitive of its own (it's a
  pi fork "with enhanced coding agent features" per its adapter comment in
  this repo — unconfirmed whether that includes subagents).
- **opencode** — confirmed native support (`mode: primary`/`subagent` +
  task tool), already has a working orchestrator adapter in this repo,
  see [adapters/opencode-orch-lms.sh](../adapters/opencode-orch-lms.sh).
- **Claude Code** — confirmed native support (`.claude/agents/*.md` + Task
  tool), no orchestrator adapter built yet in this repo.

## Revisit when

- toryo is installed and smoke-tested the same way bernstein/omni were.
- bernstein's startup hang is root-caused or worked around.
- omp's delegate capability (if any) is checked.
