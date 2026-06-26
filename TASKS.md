# TASKS — backlog & overnight loops

Single source of truth for upcoming work and for the automated loops that run
the benchmark unattended. Worked top-to-bottom; an agent (or you) picks the
next `todo` whose `deps` are all `done`, sets it `wip`, and on completion flips
it to `done` and appends a dated worklog line under it.

Status: `todo` · `wip` · `blocked` · `done`   Priority: `P0`–`P3`

Related: [docs/TESTING-STRATEGY.md](docs/TESTING-STRATEGY.md) · [LEADERBOARD.md](LEADERBOARD.md) · [memory/project-benchmark-status.md](memory/project-benchmark-status.md)

---

## The four loops

These compose into one overnight run. All are local-only (need lms/ollama/mlx on
this machine) and triggered by hand or by a `/loop` ralph session — not cloud cron.

### Loop 1 — Find work (`bin/stale`)
Emits the worklist of `(adapter,model,case)` combos needing a (re)run: **missing**
(never run), **failed** (last status ≠ ok), or **stale** (an input — adapter,
case, shim, or `config.sh`/`lib/common.sh`/`bin/bench` — changed after the run
that produced the result). This is the automation of the "what changed → start
where" table in [TESTING-STRATEGY.md](docs/TESTING-STRATEGY.md).
```
bin/stale --runtime lms > results/stale.csv          # full default matrix
bin/stale --failed-only --runtime lms                # just reruns of failures
```

### Loop 2 — Run it (`bin/bench-overnight --worklist`)
Groups the worklist by model (each model loads once), restarts services between
models, and benches the union of each model's flagged adapters × cases with
`bin/bench --resume` semantics. Sequential across models; see **T2** for true
in-model parallel dispatch.
```
bin/stale --runtime lms > results/stale.csv
bin/bench-overnight --worklist results/stale.csv --trials 1
bin/bench-overnight --stale --runtime lms            # scan + run in one shot
```

### Loop 3 — Investigate failures (`bin/investigate`)
For failing/suspicious combos, captures the tool-call transcript and classifies:
`signature:mangled-xml` (auto-fixable via `bin/pi-patch-edit-shim`) vs `clean`
(genuine model failure → record on `docs/tools/<tool>.md` + add a §V invariant via
the **backprop** skill) vs `no-edit` / `no-transcript`. Writes a markdown report
to `results/investigations/<stamp>.md`. **Does not mutate** — the fix + backprop
is the driver's decision.
```
bin/investigate --failures <RUN_ID>                  # all non-ok rows of a run
bin/investigate pi qwen/qwen3-coder-30b smoke-01-edit-file
```
Ralph-loop shape: investigate → if signature, apply shim & rerun that triple →
re-investigate → if clean, record + backprop. Repeat until no signatures remain.

### Loop 4 — This backlog
Pick next unblocked `todo` → `wip` → do it (worktree if it touches tracked files)
→ `done` + worklog. Re-triage when a loop above surfaces a new follow-up.

---

## Backlog

| id | pri | status | deps | task |
|---|---|---|---|---|
| T1 | P1 | todo | — | `bin/qualify` (L1a + L1b dominance prune) — referenced as "proposed" in TESTING-STRATEGY.md but no script exists yet. |
| T2 | P1 | todo | — | True in-model parallel dispatch in `bin/bench`: run N adapters concurrently against the resident model when RAM permits. Today the inner loop is sequential; `BENCH_PARALLEL` only sizes lms's request slots, so "parallel when RAM permits" is not yet real. |
| T3 | P2 | todo | T2 | RAM-aware auto-sizing: derive the parallel width from `run.json` `ram_*_gb` minus model footprint (`lms ls --json`) instead of a fixed `BENCH_PARALLEL=3`. |
| T4 | P2 | todo | — | Auto-generate `LEADERBOARD.md` from L3 CSVs (currently updated by hand). |
| T5 | P3 | todo | — | Add `bin/stale` + the four loops to README and TESTING-STRATEGY.md so the funnel doc points at the automation. |
| T6 | P2 | todo | — | `bin/investigate` for non-pi adapters: today only pi/caveman have transcripts; add a generic tool-call capture (or per-adapter trace) so other adapters get a real verdict instead of `no-transcript`. |
| T7 | P2 | todo | — | Surface `checks.csv` in `bin/report`: a per-check pass-rate view (which sub-step fails most across models) and a per-model "which checks did it miss" drill-down. |
| T8 | P3 | todo | — | `--difficulty` gating in the funnel: have `bin/qualify` (T1) auto-restrict weak models to `easy,medium` and only promote to `hard` after they clear the lower tiers. |

---

## Worklog

<!-- newest first: `- YYYY-MM-DD  <id>  what landed` -->
- 2026-06-25  decomp  Per-check decomposition + difficulty tiers: `lib/grader.sh` (CHECK contract), graders emit `CHECK pass|fail <id>`, `bin/bench` records `checks.csv`, `difficulty` added to all case metas, `--difficulty` filter on `bin/bench`/`bin/stale`. Docs in [CASES.md](docs/CASES.md).
- 2026-06-25  loops  Added `bin/stale` (+ `bin/stale.test.sh`), `bin/bench-overnight --worklist/--stale`, `bin/investigate`, and this backlog.
