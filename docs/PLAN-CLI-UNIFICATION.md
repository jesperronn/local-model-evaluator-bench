# Plan: unify `bin/*` scripts into a single `llmrun` command tree

**Status**: proposed (design discussion only — nothing implemented yet)
**Created**: 2026-07-02
**Context**: dotfiles already run `llmrun`, built from this project via
[bin/build-llmrun](../bin/build-llmrun) (see
[PLAN-LLMRUN-OPENCODE.md](PLAN-LLMRUN-OPENCODE.md) for the original launcher
design). This plan extends that launcher's surface to cover runtime/model
lifecycle and the flat `bin/` scripts that are hard to discover or remember by
name.

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

## Target command tree

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

llmrun run            [--agent a,b] [--models a,b] [--cases ...] [--smoke] [--preset nightly]
                                               # replaces: bench (full), smoke (--smoke), nightly (--preset nightly)

llmrun doctor         [-v]                    # env-wide sanity check, no target
llmrun debug <agent> <model> [case]           # renamed from troubleshoot: diagnose ONE failed combo

llmrun cards lint     [--type model|tool|runtime] [cards...]   # = lint-cards, unchanged
llmrun cards fix      --card X --via model  [claude|lms]       # = fix-card (raw model API loop)
llmrun cards fix      --card X --via agent  [opencode-lms]     # = sweep-cards (full agent harness loop)

llmrun results stale  [--adapter/-model/-case filters]         # = stale, unchanged
llmrun results clean  [--logs --scratch --sandboxes N --empty] # = cleanup, unchanged
```

**Deliberately left alone**: `report`, `viz` (already clear names, read
`results.csv`, natural siblings of `results` but not on the confusion list),
`investigate`, `gen-evals`, `trace-edit`, `trace-tool-calls`,
`tool-call-proxy`, `lint`/`lint-adapters` (SonarQube/adapter-specific linting,
different domain), `mlx-serve-*` wrappers.

## Portable vs project-side split

`llmrun` is generated standalone into dotfiles (no `config.sh`/`lib/common.sh`
dependency) so it works on any machine with lms/ollama installed. `runtime`,
`model`, and bare-launch subcommands are genuinely portable — keep them in the
standalone script. `run`, `doctor`, `debug`, `cards`, `results` need this repo
checked out (`cases/`, `results/`, graders, `docs/CARD-SPEC.md`). Expose those
only when `llmrun` detects it's running from inside the repo, or via
`LLMRUN_PROJECT` — otherwise point the user at `cd <project> && bin/...`.

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
time, not a single big-bang rewrite. Suggested order: `runtime` (smallest gap,
`rt` already 90% there) → `model` (biggest win, most scattered today) →
`run` → `cards`/`results` (lowest urgency, already-working scripts with just a
naming/grouping problem).

## Open questions

1. Does `run` really belong inside the portable `llmrun`, or should it stay
   `bin/bench` only, with `llmrun` limited to runtime/model/launch?
2. Should `rt`/`prune`/`lms_gc`/`lms_update`/`outdated` be deleted once ported,
   or kept as deprecated aliases for a transition period?
3. Naming: is `llmrun debug` (vs `troubleshoot`) actually clearer, or does
   `debug` collide with expectations from other tools (e.g. `--debug` flags)?
