# Testing strategy — a gated funnel

Related: [README](../README.md) · [CASES.md](CASES.md) · [SCORING.md](SCORING.md) · [BENCHMARK-RESULTS.md](../BENCHMARK-RESULTS.md)

How we decide *how much effort* to spend on any `(adapter, model, runtime)`
combination. The principle: **each level is cheaper than the next, and a failure
at any level eliminates the combo before we pay for the level above it.** Effort
widens (more cases, more trials, real concurrency) only for combos that survive
the cheaper gate.

The goal of the project — the *smallest / fastest* local model that still passes
under realistic load — drives one extra rule: we don't just cut combos that
*fail*, we cut combos that *win but are dominated* by a smaller/faster
alternative. That rule lives inside L1 (see L1b below), so it costs no extra
inference.

```
L0  wiring          → can it physically drive a model?      bin/smoke
L1  qualify + prune  → can it do one real task, fast enough,
                       and is it on the speed/size frontier?  bin/qualify  (proposed)
L2  core bench      → real accuracy across the case set      bin/bench --trials 1
L3  confidence bench → median accuracy + latency under load   bin/bench --trials 3+ / bin/bench-overnight
```

---

## L0 — Wiring (`bin/smoke`)

**Question:** can this combo physically reach a model and complete a trivial
edit?

Runs two lightweight cases (`smoke-00-hello`, `smoke-01-edit-file`), single
trial, short timeout. Reports **PASS / PARTIAL** (reached the model, task
incomplete) **/ FAIL** (never reached the model — a wiring problem).

- **Cost:** seconds.
- **Cuts:** broken plumbing — adapter, shim, `bin/tool-call-proxy`, runtime
  wiring, missing/unloaded model.
- **Known blind spot:** L0 proves *liveness, not correctness*. It does not catch
  the pi/qwen `edit`-param mangling (the model recovers via `write`, so the
  smoke case still scores 1.00). Wiring correctness ≠ tool-call correctness.

**Run it when:**

- you changed any shim, adapter, or `bin/tool-call-proxy`,
- you added a new adapter (plumbing first),
- you added a new runtime (every combo's plumbing changes — full sweep).

---

## L1 — Qualify + prune (`bin/qualify`, proposed)

**Question:** can this combo do *one real tool-call task* at all, how fast — and
once we know that, is it even worth benchmarking given what we already have?

Two sub-steps; the second is free.

### L1a — Qualify (one real case, one trial)

Run a single representative bugfix case (default `js-01-slugify-bug`) at a tight
timeout. Record `(pass, seconds)`.

- **Cost:** one short inference per combo.
- **Cuts:** models that can't reliably tool-call on a real task, or are wildly
  too slow, before they ever enter the matrix.

### L1b — Dominance prune (pure arithmetic, no inference)

Over the combos that qualified, drop every one that is **Pareto-dominated**:
another combo passes the same case with score ≥ this one's **and** is faster
**and** is smaller-or-equal in size. Survivors form the **speed/size frontier**.
Only the frontier proceeds to L2.

- **Cost:** none — it's a computation on numbers L1a already collected.
- **Cuts:** the 30B that a 7B already beats on both accuracy *and* speed. This is
  the mechanical version of "eliminate slower models that clearly have a
  smaller/faster alternative."

**Run it when:**

- you added a new model (after L0 has passed once),
- you added a new adapter and it cleared L0.

---

## L2 — Core bench (`bin/bench`, default cases, `--trials 1`)

**Question:** real accuracy across the full case set, single-shot.

The current working matrix: every default case, graded and timed, one trial.

- **Cuts:** models that clear the easy qualifier but fall apart on multi-file,
  rename, or lint-and-test cases.
- These numbers are *indicative*, not leaderboard-grade — single-trial variance
  is material (see [SCORING.md](SCORING.md)).

---

## L3 — Confidence bench (`bin/bench --trials 3+`, full cases, `bin/bench-overnight`)

**Question:** median accuracy and latency under the realistic multi-agent
workload.

Full case set, `--trials 3` or more (median score/seconds), `BENCH_PARALLEL=3`
(orchestrator + agents). Variance-aware.

- **The only tier whose numbers go on the leaderboard.**
- Reserved for L2 survivors — running it on the whole matrix is what the funnel
  exists to avoid.

---

## When to start where

| You changed… | Start at | Why |
|---|---|---|
| shim / adapter / `tool-call-proxy` | **L0** (all combos using it) | wiring regression |
| new model | **L1** (after L0 once) | qualify, sample speed, then prune |
| new adapter | **L0 → L1** | prove plumbing, then capability |
| new runtime | **L0** (full sweep) | every combo's plumbing changes |
| promoting a leaderboard number | **L3** | only tier trusted for scoring |

The funnel never spends L3 effort on a combo that failed L0, and never spends
L2 effort on a combo that L1b proved is dominated.
