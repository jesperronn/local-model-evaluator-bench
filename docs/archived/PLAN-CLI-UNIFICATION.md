# Plan: unify `bin/*` scripts into a single `llmrun` command tree

**Status**: implemented — full tree built and tested (see Migration approach
for what's inline vs delegated)
**Created**: 2026-07-02
**Updated**: 2026-07-03 — split into global (`llmrun`) vs project-local scope;
reworked `agents tune` into git-config-shaped `agents config
{list,get,set,unset,apply}` + project-local `suggest-tuning`
**Updated**: 2026-07-03 — `llmrun runtime {status,start,stop,logs}` implemented
in [bin/build-llmrun](../bin/build-llmrun)'s generated template (self-contained,
no `lib/common.sh` dependency, matches the "standalone dotfiles binary"
requirement). `start` fills the gap called out in Problem #1 (lms via
`lms server start`, ollama via app-or-`serve`, mlx via `mlx_lm.server`
backgrounded with model arg required). `bin/rt` is untouched for now — it stays
the richer, bench-aware status tool for this repo; `llmrun runtime status` is
the leaner global equivalent (no bench/results awareness).
**Updated**: 2026-07-03 — rest of the tree implemented and tested (all
commands run against the real running lms/ollama/mlx on this machine, plus the
existing `*.test.sh` suites re-run clean): `llmrun model {list,get,load,unload}`
inline; `model {rm,update}` and `agents sync` delegate by baked project path to
`bin/prune`/`bin/lms_update`/`bin/outdated`/`bin/agents-config` (same
"point to, don't inline" principle the adapters already use — see Migration
approach); `llmrun agents config {list,get,set,unset,apply}` implemented
against a new intermediate store (resolves open Q4, below); project-local
`bin/suggest-tuning` derives real `context` recommendations from
`docs/models/*.md` Quick-verdict tables (cross-checked against the hermes 64K
floor in README.md, emitting both rows on conflict — resolves open Q5);
`bin/troubleshoot` renamed to `bin/debug` with the old name kept as a
deprecated shim (resolves open Q2/Q3); `bin/cards`, `bin/results`, `bin/run`
added as thin project-local dispatchers over the existing lint-cards/fix-card/
sweep-cards, stale/cleanup, and bench/smoke/nightly scripts (resolves open Q1
in favor of "regrouped, not one `bin/dev` mega-dispatcher" — each concern gets
its own small dispatcher instead of a single namespaced entrypoint).
**Context**: dotfiles already run `llmrun`, built from this project via
[bin/build-llmrun](../bin/build-llmrun) (see
[PLAN-LLMRUN-OPENCODE.md](PLAN-LLMRUN-OPENCODE.md) for the original launcher
design). This plan extends that launcher's surface to cover runtime/model
lifecycle and the flat `bin/` scripts that are hard to discover or remember by
name.

## Scope split: `llmrun` is global-only, project stuff stays in `bin/`

Earlier drafts of this plan put `run`/`doctor`/`debug`/`cards`/`results` inside
`llmrun` too, gated on "detect you're inside the repo." That's confusing in
practice: `llmrun` is a *dotfiles binary* — the same name, built once and
copied onto `$PATH`, runs from any directory on any machine. A user (or future
you) typing `llmrun cards lint` from `~` would get a different, repo-dependent
result than typing it from inside this checkout — same command, two behaviors,
depending on `$PWD`. That's the confusion you flagged, and the fix isn't a
detection heuristic, it's a scope boundary:

- **`llmrun`** (global, portable, installed in dotfiles) — only commands that
  make sense with *no* repo checked out: which runtime is running, which
  models exist on disk, and keeping global agent configs
  (`~/.config/opencode/opencode.jsonc`, `~/.pi/agent/models.json`, etc.) in
  sync with what's actually installed. Nothing here reads `cases/`,
  `results/`, or `docs/CARD-SPEC.md`.
- **project-local `bin/*`** (this repo only, run via `cd` + `bin/<script>`,
  never installed globally) — `run` (bench/smoke/nightly), `doctor`, `debug`
  (troubleshoot), `cards` (lint-cards/fix-card/sweep-cards), `results`
  (stale/cleanup), `report`, `viz`. These already only make sense with the
  repo checked out, so there's no ambiguity to resolve — they just don't need
  to pretend to be part of the global binary. The naming/grouping cleanup
  (`rt`→`runtime`-shaped grouping, `doctor` vs `debug` distinction,
  `bench`/`smoke`/`nightly` merge) still applies, just as a project-local
  command — e.g. a single `bin/dev` dispatcher, or simply better-named
  individual scripts. Not decided yet (see open questions).

---

## Problem

`bin/` has ~30 flat scripts. Several problems came up when mapping them:

1. **No runtime `start`** — `bin/rt` has `status/ram/log/watch/who/stop`, but
   nothing starts lms/ollama/mlx.
2. **No unified model lifecycle** — `get` (download) and `load` don't exist as
   standalone commands anywhere; they're only inlined in docs or in
   `build-llmrun`'s generated exec path. `unload` (`lms_gc`) and `update`
   (`lms_update`) are lms-only, while `outdated` checks all three runtimes but
   only reports (doesn't act). `rm` (`bin/prune`) is the one already
   runtime-aware, best-built tool of the bunch.
3. **Names don't say what they do** — `rt`, `prune`, `lms_gc` require already
   knowing the mapping from name → concern. `doctor` vs `troubleshoot` look
   like synonyms but differ on one axis (env-wide vs one-failing-combo) that
   the names don't convey.
4. **`bin/smoke` / `bin/bench` / `bin/nightly`** are the same matrix-runner
   engine at different scope presets, not three different tools.
5. **Docs-hygiene scripts** (`sweep-cards`, `eval-agent`, `lint-cards`,
   `cleanup`, `stale`) form two natural lifecycles (card conformance;
   results-dir hygiene) plus one orphan (`eval-agent`, now finished — see
   below) that were never grouped.

## Target command tree — `llmrun` (global, dotfiles-portable only)

```
llmrun                                        # bare = today's launcher behavior
llmrun <agent> [--runtime] [--model]          # unchanged: --agent/--runtime/--model/prompt

llmrun runtime status [lms|ollama|mlx|all]           # replaces: rt status/ram/who
llmrun runtime start  <lms|ollama|mlx>               # NEW
llmrun runtime stop   <lms|ollama|mlx|all>           # replaces: rt stop
llmrun runtime logs   [--all] [<lms|ollama|mlx>] [-f] [N]  # replaces: rt log/watch; --all shows all runtimes with colored prefixes

llmrun model list     [--runtime]             # NEW
llmrun model get      <id> --runtime X        # NEW
llmrun model load     <id> --runtime X        # extracted from build-llmrun's inline exec logic
llmrun model unload   [<id>] [--idle 30m] --runtime X   # replaces: lms_gc (generalized past lms-only)
llmrun model rm       [<id>] [--unused] [--interactive] # replaces: prune
llmrun model update   [<id>] [--check]        # replaces: lms_update (write) + outdated (read-only via --check)

llmrun agents sync         [--write] [--opencode-only|--pi-only|...]       # = agents-config, generalized

llmrun agents config list  [--target opencode|pi|...]                     # NEW — dump effective settings, all targets
llmrun agents config get   <model> <key>          [--target X]            # NEW — e.g. get hermes context
llmrun agents config set   <model> <key> <value>  [--target X]            # NEW — e.g. set hermes context 65536
llmrun agents config unset <model> <key>          [--target X]            # NEW — remove override, fall back to tool default
llmrun agents config apply <plan.jsonl>  [--write]                        # NEW — bulk-apply a suggestion plan (see below)
```

**Global adapter-config gap (your second question) — real, partially filled,
now split into three pieces instead of one `tune` command.**
[bin/agents-config](../bin/agents-config) already re-derives
`~/.config/opencode/opencode.jsonc`'s model list and
`~/.pi/agent/models.json` from `lms ls --json` / `ollama list`, filtering out
combos `compat.json` marks broken — that's `agents sync`, folded in as-is.
It explicitly does **not** touch per-model context-window/temperature tuning
(see the script's header) — that's the gap the original `agents tune` draft
tried to cover in one shot. On review that conflated two different jobs:

1. **Reading/writing config state** — mechanical, no judgment, works with no
   repo checked out. This is `agents config {list,get,set,unset}`, deliberately
   shaped like `git config`: `list` finally answers "what's configured right
   now?" (nothing does today — you'd open `opencode.jsonc` by hand), `get`/
   `set`/`unset` operate on one `(model, key)` pair per config target.
2. **Deciding what the values *should* be** — needs judgment from this
   project's evidence (a model card's "needs ≥64K context" fact, e.g. Hermes's
   hard-refuse below 64K — see [README.md](../README.md)'s context-window
   note; hardware-recommended settings; what temperature scored best in
   `results/`). That's inherently repo-local — see `bin/suggest-tuning` below,
   not a subcommand of `llmrun` at all.

The bridge between the two is `agents config apply <plan.jsonl>`: it reads a
flat plan (one JSON object per line: `{model, key, value, reason, source}`)
and calls `set` for each row, dry-run by default, `--write` to commit — same
trust convention `agents-config` already uses. `llmrun` never has to know
*why* a value is right, only how to write it; the "why" (reason + source
citation) travels in the plan file and gets printed at apply time for review.

**See [docs/ADAPTER-SETUP.md](ADAPTER-SETUP.md)** for the full zero-friction
adapter onboarding story: combining pre-configuration (via `suggest-tuning` +
`agents config apply`) with card documentation ensures adapters "just work"
out of the box — no manual tuning.

Fold `bin/agents-config` into `agents sync` — it's already global-scope
(writes to `~/.config`, `~/.pi`, not this repo) and already runtime/model
lifecycle-adjacent, so it belongs in `llmrun`, not in project-local `bin/`.

## Project-local scope (not `llmrun`, stays in this repo)

Everything that needs `cases/`, `results/`, or `docs/CARD-SPEC.md` stays a
repo-local concern, run via `cd <project> && bin/<script>` — never installed
onto `$PATH`, so there's no `$PWD`-dependent ambiguity to manage:

```
run    [--agent a,b] [--models a,b] [--cases ...] [--smoke] [--preset nightly]
                                               # replaces: bench (full), smoke (--smoke), nightly (--preset nightly)
doctor [-v]                                   # env-wide sanity check, no target
debug  <agent> <model> [case]                 # renamed from troubleshoot: diagnose ONE failed combo
cards lint  [--type model|tool|runtime] [cards...]   # = lint-cards, unchanged
cards fix   --card X --via model  [claude|lms]       # = fix-card (raw model API loop)
cards fix   --card X --via agent  [opencode-lms]     # = sweep-cards (full agent harness loop)
results stale [--adapter/-model/-case filters]       # = stale, unchanged
results clean [--logs --scratch --sandboxes N --empty]  # = cleanup, unchanged

suggest-tuning [<model>]     # NEW — derive context/temp recommendations from
                             # docs/models/*.md, docs/HARDWARE-RECOMMENDATIONS.md,
                             # compat.json, results/; emit one plan.jsonl row per
                             # recommendation: {model, key, value, reason, source}
```

Typical flow bridging the two scopes:

```
bin/suggest-tuning > /tmp/plan.jsonl        # project-local: derive from evidence
llmrun agents config apply /tmp/plan.jsonl  # global: dry-run preview
llmrun agents config apply /tmp/plan.jsonl --write   # global: commit
```

Whether these become one project-local dispatcher (e.g. `bin/dev run`,
`bin/dev cards lint`) or stay individually named-but-regrouped scripts is an
open question below — either way, they are never part of the `llmrun` binary
that ends up in dotfiles.

**Deliberately left alone (either scope)**: `report`, `viz` (already clear
names, read `results.csv`, natural siblings of `results` but not on the
confusion list), `investigate`, `gen-evals`, `trace-edit`, `trace-tool-calls`,
`tool-call-proxy`, `lint`/`lint-adapters` (SonarQube/adapter-specific linting,
different domain), `mlx-serve-*` wrappers.

## `eval-agent` — resolved

Was the one orphan in the docs-hygiene group (a stubbed skeleton, not part of
the `cards`/`results` lifecycles — it grades *agent* answers against
`docs/QUESTION-SUITE.md`, not doc conformance). Decision: finish it, not
fold it into a namespace. Done as of 2026-07-02: `ask_agent` and
`judge_correct` wired in `bin/eval-agent`, `eval/questions.jsonl` populated
with the 54 A/B/F/G questions. Stays a standalone `bin/eval-agent` — it's a
model-eval tool, not a runtime/model/cards/results lifecycle command, so it
doesn't slot into the tree above.

## Migration approach — done

Built and tested in dependency order, global first: `runtime` → `model` →
`agents config` → `agents sync` → project-local `suggest-tuning` + `agents
config apply` bridge → project-local `run` → `cards`/`results`.

Two different "thin wrapper" strategies were used depending on how
battle-tested and repo-coupled the underlying logic was:

- **Inlined into the `llmrun` template** (self-contained, no repo needed):
  `runtime {status,start,stop,logs}`, `model {list,get,load,unload}`,
  `agents config {list,get,set,unset,apply}`. These were either genuinely new
  (no existing script to preserve) or simple enough (status checks, JSON
  key-value CRUD) to reimplement directly without risking regressions.
- **Delegated by baked project path** (same "point to, don't inline"
  principle `build-llmrun` already uses for adapters): `model rm` →
  `bin/prune`, `model update` → `bin/lms_update`/`bin/outdated`, `agents sync`
  → `bin/agents-config`. These have substantial, already-correct logic
  (HF API staleness checks, LM Studio index parsing, jsonc-preserving node
  patching) that would be all downside to reimplement inline in a bash
  heredoc — copying ~1200 lines of tested logic into the template's string
  literal for no functional gain. `llmrun` calls them via `$_PROJECT/bin/...`,
  same as it already does for adapter scripts. This does mean these three
  subcommands need the source project on disk at the baked path (they `die`
  with a clear message if it's missing) — a strictly smaller requirement than
  "repo checked out at invocation `$PWD`", and the same one adapters already
  had.
- **Project-local dispatchers** (`bin/cards`, `bin/results`, `bin/run`): thin
  argument-translating wrappers over `bin/lint-cards`/`fix-card`/`sweep-cards`,
  `bin/stale`/`cleanup`, and `bin/bench`/`smoke`/`nightly`. Zero changes to the
  underlying engines — all existing `*.test.sh` suites still pass unmodified.
  `bin/troubleshoot` was renamed to `bin/debug` for real (not just a wrapper)
  since it was a single, cheap, self-contained rename; the old name is kept as
  a one-line deprecated shim that execs `bin/debug`.

Old scripts were **not deleted** — `bin/rt`, `prune`, `lms_gc`, `lms_update`,
`outdated`, `agents-config`, `lint-cards`, `fix-card`, `sweep-cards`,
`stale`, `cleanup`, `bench`, `smoke`, `nightly` all still work standalone and
remain the implementation the new entry points call into or sit alongside.
`bin/lms_gc`'s standalone TTL-sweep behavior isn't yet exposed through `llmrun
model unload --idle` in exactly the same shape (the new command reimplements
the idle-scan inline rather than calling `lms_gc`) — worth a follow-up diff if
they drift.

## Open questions — resolved

1. **One dispatcher vs regrouped scripts?** Resolved: regrouped, not a single
   `bin/dev` mega-dispatcher. `bin/cards`, `bin/results`, and `bin/run` are
   three small, independently-invokable dispatchers instead of one namespaced
   entrypoint — matches how these were already invoked standalone, avoids
   forcing every project-local action through one script when only three of
   the six areas actually had a naming/grouping problem worth solving (`doctor`
   and `suggest-tuning` needed no grouping at all).
2. **Delete old scripts or keep as aliases?** Resolved: keep, unaliased, as the
   real implementation. `model rm`/`update` and `agents sync` call them
   directly (see Migration approach) rather than duplicating their logic, so
   deleting them would break `llmrun`. Only `bin/troubleshoot` became a true
   alias (see below).
3. **`debug` vs `troubleshoot` naming?** Resolved: renamed to `bin/debug`.
   `--debug` flag collision risk judged low — `bin/debug` is a top-level
   command, not a flag, and no adapter/tool in this repo uses `--debug`.
   `bin/troubleshoot` kept as a deprecated shim (prints a notice, execs
   `bin/debug`) so any existing muscle memory or references still work.
4. **`agents config` storage model?** Resolved: intermediate store
   (`~/.config/llmrun/agents.json`), not direct read/write of
   `opencode.jsonc`/`pi`'s `models.json`. Those files don't currently have a
   per-model tuning field to write into (checked: both only carry `{id}` model
   list entries, no `context`/`temperature` overrides) — inventing that schema
   in each tool's native format was out of scope for the CRUD layer itself.
   The store is real and working end-to-end (`suggest-tuning | agents config
   apply --write` round-trips), but **reconciling stored overrides into each
   tool's native config format is not yet built** — `agents config` currently
   answers "what did I recommend/decide," not "what will opencode/pi/Cline
   actually use." That reconciliation (one adapter per target format) is the
   next real gap, tracked here rather than silently assumed done.
5. **Conflicting evidence in `suggest-tuning`?** Resolved: emit both rows, no
   auto-pick. Implemented and verified: when a model card's context
   recommendation is below the hermes 64K floor documented in README.md, both
   the card-sourced and README-sourced rows are emitted with distinct
   `reason`/`source` fields, and a human (or a future policy) chooses via
   which row survives to `agents config apply --write`.

## Developer experience principle: copy-paste-friendly error messages

When error messages reference paths or commands, prefer environment variable
or shell syntax that developers can copy-paste directly:

**Good (copy-paste ready):**
```
[FAIL] no ollama log found at ${TMPDIR}/llmrun-ollama.log
```

**Avoid (requires re-typing):**
```
[FAIL] no ollama log found at /var/folders/vc/ckfmj.../T/llmrun-ollama.log
```

This applies to all paths, variables, and command snippets in error messages,
help text, and suggestions. The goal is zero friction when a developer copies
the reference from the output and pastes it into their terminal or editor.

Found and fixed: `llmrun runtime logs` now shows `${TMPDIR}/llmrun-*.log`
instead of the expanded path, and similarly for startup log suggestions.

### `llmrun runtime logs --all` — multi-runtime aggregated logging

**Feature**: When multiple runtimes are running concurrently, `llmrun runtime
logs --all` streams logs from all three (lms, ollama, mlx) with each line
prefixed by `[runtime_name]` in a distinct color — similar to `docker compose
logs` behavior. Works in both static tail and live-follow modes:

```
llmrun runtime logs --all        # tail last 40 lines from all runtimes, exit
llmrun runtime logs --all -f     # live-follow all runtimes until killed
llmrun runtime logs --all 20     # tail last 20 lines from all runtimes
llmrun runtime logs --all 20 -f  # live-follow all with custom line count
```

Each runtime's output is colored: lms (red), ollama (green), mlx (yellow).
Runtimes without accessible logs are silently skipped. When multiple runtimes
have logs available, output is interleaved by wall-clock arrival time (each
process's tail output is captured and multiplexed). This is useful for
debugging adapter sessions when multiple inference backends are in flight.
