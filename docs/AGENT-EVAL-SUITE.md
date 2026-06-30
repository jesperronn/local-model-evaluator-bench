# Agent evaluation suite — testing any agent on the 100 questions

> **Status: design + skeleton (Task 2).** This describes how to turn
> [QUESTION-SUITE.md](QUESTION-SUITE.md) into a runnable benchmark that scores
> how well *an agent* (a tool × model pair, or a hosted model) can answer
> questions about this project. The skeleton script is `bin/eval-agent`; model
> calls are not yet wired — review this first.

## What it tests vs what lint-cards tests

The 100 questions split by **what they grade**, and the two halves get two tools:

| Questions | Grade target | Tool |
|-----------|--------------|------|
| **C / D / E** (per-card consistency) | the **cards** (docs) | `bin/lint-cards` (built, mechanical) |
| **A / B / F / G** (navigation, decision, scoring, workflow) | an **agent's answers** | `bin/eval-agent` (this doc) |

So `eval-agent` uses the ~58 answerable questions in sections A, B, F, G. The
C/D/E questions are not asked to an agent — they're a doc linter, already done.

## Scoring (matches the project's accuracy-first, speed-tiebreak ethos)

Each question yields:

- **Correctness** (0–1) — did the answer match the expected answer?
- **Citation** (0/1) — did the answer point to the correct source file (the
  `source` field), proving the agent could *navigate* to it, not just guess?
- **Seconds** — wall-clock for the answer (speed is co-equal, as everywhere).

Aggregate per agent:

| Metric | Meaning |
|--------|---------|
| **Findability %** | mean Citation over section A (can it reach the right doc?) |
| **Decision accuracy %** | mean Correctness over section B (does it choose well?) |
| **Method/process %** | mean Correctness over F + G |
| **Citation rate %** | mean Citation over all |
| **Median s** | speed |

A good local agent for *self-service docs* is one that scores high on Findability
**and** is fast — same rule as the rest of the bench.

## Grading method (per your decision: mechanical where possible, LLM-judge for prose)

- **Citation** — mechanical. The expected `source` is a repo path (optionally
  with `#anchor`). Score 1 if the agent's answer text contains that path (or its
  basename). Deterministic, no model.
- **Correctness** — LLM-judge for free-text. A judge model is given the
  question, the expected answer, and the agent's answer, and returns
  `{correct: 0|1, why: "..."}`. Use a strong, consistent judge (e.g. a hosted
  Claude model) so grading doesn't drift with the agent under test.
- Questions may set `grade: "exact"` to skip the judge when the answer is a
  short fact (a number, a filename, a yes/no) — then correctness is a normalized
  string match. Keeps cost down and is fully deterministic for those.

## Two modes of asking

1. **Closed-book** — give the agent only the question. Tests what the model
   *knows* / can infer. Low scores expected; not the point of a docs project.
2. **Open-book (default)** — give the agent the repo (or let the tool's own
   file-reading drive). Tests whether the **docs are navigable** — the real goal.
   Findability % is only meaningful in open-book mode.

The harness records the mode in the scorecard.

## Question bank format

Derived from QUESTION-SUITE.md sections A/B/F/G into `eval/questions.jsonl`
(one JSON object per line):

```json
{"id":"A1","section":"A","mode":"open","grade":"judge","question":"Starting from the README alone, where do I learn the project's end goal?","expected":"README 'End goal': a multi-agent orchestration setup (orchestrator + 2-3 agents) at --parallel 3-4.","source":"README.md#end-goal"}
{"id":"B17","section":"B","grade":"exact","question":"What's the fastest adapter overall, and on what model?","expected":"aider, ~11s avg on qwen3-coder-30b","source":"docs/AGENT-SELECTION.md"}
{"id":"F79","section":"F","grade":"judge","question":"What is the primary score?","expected":"Objective test pass-rate (fraction of assertion points passing).","source":"docs/SCORING.md"}
{"id":"G91","section":"G","grade":"exact","question":"How do I add a new model to the bench?","expected":"Download it in LM Studio and add its id to models.txt.","source":"docs/WORKFLOW.md"}
```

Fields: `id` (matches QUESTION-SUITE numbering), `section`, `question`,
`expected`, `source` (repo path, optional `#anchor`), `grade` (`judge`|`exact`),
`mode` (`open`|`closed`, default `open`).

> **Next step to make this runnable:** extract all ~58 A/B/F/G questions from
> QUESTION-SUITE.md into `eval/questions.jsonl`. The answers + sources already
> live in QUESTION-SUITE.md, so this is a mechanical transcription (could itself
> be a `bin/` one-shot or a small-model job, then spot-checked).

## Skeleton harness — `bin/eval-agent`

```
bin/eval-agent --via lms --model qwen/qwen3.6-35b-a3b [--mode open|closed] [--section A,B] [--out eval/runs/<ts>.csv]
```

Per question: ask the agent → record answer + seconds → grade citation
(mechanical) → grade correctness (exact or judge) → write a row. At the end,
print the aggregate scorecard and save a CSV under `eval/runs/`.

The skeleton is committed as `bin/eval-agent` with the model-call and judge-call
functions stubbed (clearly marked `# TODO: wire`), reusing the same `ask_model`
pattern as `bin/fix-card`. Wire those two functions and drop in
`eval/questions.jsonl` to make it live.

## How this complements the rest of the bench

- `bin/bench` measures whether an agent can **edit code** correctly/fast.
- `bin/eval-agent` measures whether an agent can **navigate these docs** to
  answer real questions — i.e. whether the project is a usable knowledge base,
  and which local model is good enough to serve it.
- `bin/lint-cards` keeps the docs themselves consistent so both stay honest.
