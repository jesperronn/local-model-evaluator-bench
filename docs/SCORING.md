# Scoring

Related: [README](../README.md) · [CASES.md](CASES.md) · [ADDING-CASES.md](ADDING-CASES.md) · [BENCHMARK-RESULTS.md](../BENCHMARK-RESULTS.md)

Two metrics are recorded for every run and treated as **co-equal**: **accuracy**
(test pass-rate) and **speed** (`seconds`). The goal is the *smallest/fastest*
local model that still passes — see [Speed](#speed-co-equal-with-accuracy) below.

## Primary score: objective test pass-rate

For each `(adapter, model, case)` triple, `bin/bench`:

1. Copies `cases/<id>/workdir/` into an isolated sandbox.
2. Hands `cases/<id>/task.md` to the CLI adapter (model edits the sandbox).
3. Runs the **hidden** grader `cases/<id>/check/run.sh` against the sandbox.

The grader prints one line:

```
RESULT pass=<n> total=<m>
```

and the case score is `pass / total` (0.00–1.00). For most cases the tests are
**hidden** — they live in `check/` and are copied in only at grading time. For
**self-verify** cases the tests/linter ship in the workdir on purpose (the agent
is told to run them and iterate); the grader still copies a **pristine** copy
from `check/` over them before scoring, so editing the shipped tests can't game
the result. See [CASES.md](CASES.md) for which is which.

`results/<timestamp>/results.csv` has one row per triple:

```
adapter,model,case,pass,total,score,seconds,status,trials
```

`status` is `ok`, `timeout`, or `error(<rc>)` — a tool that crashes or hangs
scores 0 on that case but the run continues. With `--trials N` (below) a row's
`status` is the `|`-joined set of distinct trial statuses (e.g. `ok|timeout`), so
a triple that's flaky across trials is visible at a glance. `trials` is `N`.

### Trials and medians (`--trials N`)

Run-to-run variance is **material** — the same `(tool, model, case)` triple has
swung 4/4 → 0/4 between identical runs — so a single trial is untrustworthy.
`bin/bench --trials N` repeats each triple `N` times in isolated per-trial
sandboxes and records the **median** `score` and **median** `seconds` in
`results.csv` (median is robust to the occasional outlier run). `pass` is derived
from the median score (`round(score × total)`) so it stays an integer consistent
with `score`. Every individual trial is also written to
`results/<timestamp>/trials.csv` (`adapter,model,case,trial,pass,total,score,seconds,status`)
so the variance behind each median stays inspectable. `--trials` defaults to `1`,
in which case the median is just the single trial and no `trials.csv` is written.

### Aggregation

`bin/report` rolls the CSV into two leaderboards:

- **by adapter × model** — which CLI + model combo edits code best, plus the
  `med s` (mean across cases of each case's median seconds) and `trials` columns.
- **by model** — a model's overall pass-rate across all adapters.

Because the unit is "tests passed", scores are comparable across models and
across runs, and a new model needs *zero* manual grading — add it to
`models.txt` and re-run.

## Workarounds and fairness

A model's tool calls sometimes need an **adapter-level shim or wrapper** to work
with a given tool — e.g. qwen3-coder emits flat Hermes/Qwen `<parameter=NAME>`
XML tool calls that cannot encode a tool's nested array-of-objects parameter, so
the call is mangled and rejected. (Concrete case: pi's `edit` tool, see
[docs/tools/pi.md](tools/pi.md).)

**Policy: score *with* a working shim/wrapper, not as-shipped.** The goal is to
find the best `(tool, model)` pairing in practice, and a small adapter shim is a
realistic part of running a model locally — penalising the model for a tool's
strict schema would be unfair and would hide otherwise-capable models.

**But the shim must be recorded.** Every tool card and model card carries a
**`Workarounds needed:`** line stating what was required for the scored result
(e.g. `Workarounds needed: shim — pi edit-tool XML recovery`, or `none`). A score
achieved with a workaround is not the same as one achieved out of the box, and
the card must make that visible. The shim itself should live in / be applied by
the adapter so benchmark runs stay reproducible.

## Speed (co-equal with accuracy)

Every row records `seconds` — wall-clock for the tool+model to complete the
task. For **local** use this is not secondary: the practical objective is the
**smallest, fastest model that still passes**, because model size is RAM you pay
for and latency you wait on. Read the two columns together:

- A model that scores 15/15 in 30s beats one that scores 15/15 in 300s.
- A smaller model that passes is preferable to a larger one that also passes.
- `bin/report` shows `med s` next to `PASS%` so you can pick the cheapest model
  that clears your accuracy bar for a given task.

Caveats when reading `seconds`:
- Some tools **linger after finishing** (don't exit promptly) and get cut at the
  timeout — the edit is done but `seconds` is inflated and `status=timeout`.
- A `timeout` that kills a tool **mid-edit** can leave a half-written file and
  depress the score; raise `--timeout` for slow models and re-run.

## Optional secondary score: LLM-judge quality (not yet wired)

Pass-rate measures *correctness* but not *idiom/quality*. The intended hybrid
adds a second axis: feed the model's diff to a judge model and score
readability / idiomaticity / instruction-following 0–5. This is deliberately
left as a follow-up so the committed harness stays dependency-free and fully
objective. When added it will be a `--judge` flag on `bin/bench` writing an
extra `quality` column; the test pass-rate remains the primary, authoritative
score.

## What a good case looks like

- Tests pin **behavior**, not implementation — they import the named export /
  invoke the script, and assert outputs. They don't grep the source.
- Multiple independent assertions so partial credit is meaningful (a model that
  gets 3/4 edge cases scores 0.75, not 0).
- Deterministic: same edit → same score, every run.

See [ADDING-CASES.md](ADDING-CASES.md) to add one, and [CASES.md](CASES.md) for
the full spec of the existing cases.
