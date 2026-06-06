# Scoring

## Primary score: objective test pass-rate

For each `(adapter, model, case)` triple, `bin/bench`:

1. Copies `cases/<id>/workdir/` into an isolated sandbox.
2. Hands `cases/<id>/task.md` to the CLI adapter (model edits the sandbox).
3. Runs the **hidden** grader `cases/<id>/check/run.sh` against the sandbox.

The grader prints one line:

```
RESULT pass=<n> total=<m>
```

and the case score is `pass / total` (0.00–1.00). The hidden tests live in
`check/` and are copied into the sandbox **only at grading time**, so the model
never sees them.

`results/<timestamp>/results.csv` has one row per triple:

```
adapter,model,case,pass,total,score,seconds,status
```

`status` is `ok`, `timeout`, or `error(<rc>)` — a tool that crashes or hangs
scores 0 on that case but the run continues.

### Aggregation

`bin/report` rolls the CSV into two leaderboards:

- **by adapter × model** — which CLI + model combo edits code best, plus avg time.
- **by model** — a model's overall pass-rate across all adapters.

Because the unit is "tests passed", scores are comparable across models and
across runs, and a new model needs *zero* manual grading — add it to
`models.txt` and re-run.

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

See `docs/ADDING-CASES.md` to add one.
