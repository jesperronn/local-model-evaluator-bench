# Purpose

## The question this project answers

> **What is the smallest and fastest local model + tool combination that reliably completes realistic agentic coding tasks — and how does each choice affect both accuracy and speed?**

Everything in this repo exists to answer that question with measured data rather than claims.

---

## Why both accuracy and speed

Running models locally means competing for RAM and time. The best choice is never just the most accurate model — it is the most accurate model that is also fast enough for the workload.

**When two combinations have equal accuracy, the faster one wins.**

This is not a tiebreaker. Speed is a first-class metric. A model that scores 100% but takes 300s per task is a different choice from one that scores 100% in 40s — especially in a multi-agent setup where three agents run concurrently and each second multiplies.

Both metrics appear on every leaderboard row, every model card, and every tool card — at the same visual level, not one footnote of the other.

---

## What you can learn from this project

| Question | Where to look |
|----------|--------------|
| Which tool + model combo should I use today? | [LEADERBOARD.md](../LEADERBOARD.md) — sorted by accuracy then speed |
| Which model is fastest for a given tool? | [docs/models/](models/) — per-model card, timing section |
| Which tool gets the most out of a given model? | [docs/tools/](tools/) — per-tool card, results by model |
| Which runtime is fastest for my hardware? | [docs/runtimes/](runtimes/) (planned) — per-runtime card |
| What hardware do I need? | [docs/HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md) |
| What are the best current choices? | [docs/templates/best-current-airgapped-local-models-example-2026-06.md](templates/best-current-airgapped-local-models-example-2026-06.md) |

---

## The document hierarchy

```
LEADERBOARD.md              ← the ranked answer: adapter × model, sorted by accuracy then speed
│
├── docs/models/*.md        ← per-model cards: accuracy + speed across all tools/runtimes
├── docs/tools/*.md         ← per-tool cards: accuracy + speed across all models/runtimes
└── docs/runtimes/*.md      ← per-runtime cards: accuracy + speed impact, adapter compat
         │
         └── results/<ts>/results.csv   ← raw measured data that feeds every card
```

Cards are intermediate data-collection artefacts. They exist to record what was measured, when, and under what conditions. The leaderboard is the ranked answer.

The survey-style documents (like `best-current-airgapped-local-models-example-2026-06.md`) translate leaderboard findings into prose recommendations for specific use cases — "for air-gapped deployment, use X" rather than a ranked table.

---

## The end goal

The target workload is a **multi-agent orchestration setup**: an orchestrator model directing 2–3 coding sub-agents, all running concurrently against the same local model. This means:

- The model must handle `--parallel 3–4` without accuracy degradation
- Speed matters more than in single-agent use: each extra second per sub-task multiplies
- The winning combo is the smallest model (fewest RAM GB) that still passes at that concurrency

Single-agent benchmark results are the foundation. They establish baseline accuracy and speed per (tool, model, runtime) triple. Multi-agent cases — concurrent tool calls, handoff patterns — are the next layer.

---

## What is not the goal

- Finding the most accurate model regardless of size or speed
- Reproducing existing coding benchmarks (HumanEval, SWE-bench) — this tests real agentic tool use, not code generation from scratch
- Cloud or API models — only local, air-gap-friendly, open-weight models
