# Plan: unify `bin/*` scripts into a single `llmrun` command tree

**Status**: proposed (design discussion only — nothing implemented yet)
**Created**: 2026-07-02
**Updated**: 2026-07-03 — split into global (`llmrun`) vs project-local scope;
reworked `agents tune` into git-config-shaped `agents config
{list,get,set,unset,apply}` + project-local `suggest-tuning`
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

llmrun runtime status [lms|ollama|mlx|all]    # replaces: rt status/ram/who
llmrun runtime start  <lms|ollama|mlx>        # NEW
llmrun runtime stop   <lms|ollama|mlx|all>    # replaces: rt stop
llmrun runtime logs   [-f] [N]                # replaces: rt log/watch

llmrun model list     [--runtime]             # NEW
llmrun model get      <id> --runtime X        # NEW
llmrun model load     <id> --runtime X        # extracted from build-llmrun's inline exec logic
llmrun model unload   [<id>] [--idle 30m] --runtime X   # replaces: lms_gc (generalized past lms-only)
llmrun model rm       [<id>] [--unused] [--interactive] # replaces: prune
llmrun model update   [<id>] [--check]        # replaces: lms_update (write) + outdated (read-only via --check)

llmrun agents sync         [--write] [--opencode-only|--pi-only|...]       # = sync-agent-configs, generalized

llmrun agents config list  [--target opencode|pi|...]                     # NEW — dump effective settings, all targets
llmrun agents config get   <model> <key>          [--target X]            # NEW — e.g. get hermes context
llmrun agents config set   <model> <key> <value>  [--target X]            # NEW — e.g. set hermes context 65536
llmrun agents config unset <model> <key>          [--target X]            # NEW — remove override, fall back to tool default
llmrun agents config apply <plan.jsonl>  [--write]                        # NEW — bulk-apply a suggestion plan (see below)
```

**Global adapter-config gap (your second question) — real, partially filled,
now split into three pieces instead of one `tune` command.**
[bin/sync-agent-configs](../bin/sync-agent-configs) already re-derives
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
trust convention `sync-agent-configs` already uses. `llmrun` never has to know
*why* a value is right, only how to write it; the "why" (reason + source
citation) travels in the plan file and gets printed at apply time for review.

Fold `bin/sync-agent-configs` into `agents sync` — it's already global-scope
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

## Migration approach (not yet started)

Old scripts become thin wrappers (or get deleted) once each new subcommand is
built and verified against the old script's behavior — one namespace at a
time, not a single big-bang rewrite. Suggested order, global first (these are
the ones that had a real functional gap, not just a naming problem):
`runtime` (smallest gap, `rt` already 90% there) → `model` (biggest win, most
scattered today) → `agents config` (git-config-shaped CRUD, needed before
`apply` has anything to call) → `agents sync` (fold in `sync-agent-configs`)
→ project-local `suggest-tuning` + `agents config apply` bridge → project-local
`run` → `cards`/`results` (lowest urgency, already-working scripts with just a
naming/grouping problem).

## Open questions

1. Do the project-local commands (`run`/`doctor`/`debug`/`cards`/`results`/
   `suggest-tuning`) become one dispatcher script (`bin/dev <namespace>
   <verb>`), or just get regrouped/renamed as individual scripts without a
   wrapper? A dispatcher mirrors `llmrun`'s shape (consistent mental model)
   but adds a layer of indirection for commands that are only ever run from
   this one repo anyway.
2. Should `rt`/`prune`/`lms_gc`/`lms_update`/`outdated`/`sync-agent-configs` be
   deleted once ported into `llmrun`, or kept as deprecated aliases for a
   transition period?
3. Naming: is `debug` (vs `troubleshoot`) actually clearer, or does `debug`
   collide with expectations from other tools (e.g. `--debug` flags)?
4. `agents config`'s storage model — does it read/write the target configs
   directly on every call (simplest, always current, but `opencode.jsonc`
   round-tripping must preserve comments/formatting), or maintain its own
   intermediate store (e.g. `~/.config/llmrun/agents.json`) that `sync`/`apply`
   reconcile into each tool's native format? Direct read/write is simpler and
   avoids a second source of truth, but only works for targets `llmrun` knows
   how to parse — Cline/Continue's VS Code `settings.json` format may need a
   per-target adapter either way, which favors the intermediate-store design.
5. `suggest-tuning`'s evidence sources will disagree sometimes (e.g. a
   hardware-recommendation says one context size, a model card's observed
   failure threshold says another) — does it emit both as separate plan rows
   for a human to pick, or does one source always win?
