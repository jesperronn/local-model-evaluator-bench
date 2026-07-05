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

## L1 — Qualify + prune (`bin/qualify`)

**Question:** which L0-passing combos are actually viable — and once we know
that, which are dominated by faster/smaller alternatives?

Two sub-steps; the second is free and uses compat.json integration.

### L1a — Qualify (filter L0 results, mark viability)

Read L0 (smoke) results and check compat.json for known failures. Mark each
combo that passed L0 and has no open issues as "qualified". This is a
pre-filter: use `bin/qualify` after L0 to generate a manifest of viable combos.

```bash
bin/smoke                           # runs L0 (writes results/*/results.csv)
bin/qualify --from-smoke <csv>      # reads L0, filters by compat.json
                                    # outputs qualified-combos.json
bin/bench --from-qualified <json>   # uses manifest to skip unviable combos
```

- **Cost:** zero inference (pure filtering).
- **Cuts:** adapters with known open issues in compat.json, early, before
  expensive L2 runs.
- **Output:** `qualified-combos.json` — a manifest of (adapter, model) pairs
  safe to test. Can be piped to `bin/bench --from-qualified` to skip L0
  failures and known-broken combos.

### L1b — Dominance prune (optional post-L2 analysis)

After L2 runs complete, analyze the results and identify which combos are
Pareto-dominated: another combo passes the same case with score ≥ this one's
**and** is faster **and** is smaller-or-equal in size. Mark these for L3
skipping.

- **Cost:** none — a post-hoc computation on L2 results.
- **Cuts:** the 30B that a 7B already beats on both accuracy *and* speed.

**Run it when:**

- you ran L0 and want to skip L0-broken combos before L2 (use `bin/qualify`),
- after L2 completes, to identify dominated combos for L3 skipping (manual analysis).

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

---

## L3 Promotion Criteria

**When to graduate an L2 combo to L3 (confidence tier with leaderboard-grade results):**

An L2 combo is eligible for L3 if it meets either criterion:

1. **Performance threshold:** Score ≥ 0.90 across all cases in the latest L2 run, indicating reliable accuracy without variance risk.

2. **Priority adapters:** Top-tier adapters known to be stable across models (aider, cline, hermes, opencode, pi), even if one case dips below 0.90 due to single-trial variance. These have earned L3 status through repeated L2 evidence.

**Current workflow:** Manual review

1. After L2 completes (`bin/bench --trials 1`), review `results/<timestamp>/results.csv`
2. Identify combos matching criteria above
3. Run with confidence: `bin/bench --agent <name> --model <id> --trials 3+` or `bin/bench-overnight --stale`
4. Leaderboard updates only from L3 results (see [BENCHMARK-RESULTS.md](../BENCHMARK-RESULTS.md))

**Future optimization:** If L2 runs become weekly+, consider `bin/promote-to-l3 --from-run <id> --threshold 0.90` to automate step 2. For now, manual review catches edge cases and adapts thresholds per model family.
