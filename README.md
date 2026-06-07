# local-model-editor-bench

A small, repeatable harness for testing how well **local models** (served by
[LM Studio](https://lmstudio.ai)) perform as **code editors**, across several
agentic coding CLIs — and, via the same local server, VS Code / IntelliJ
extensions.

## Purpose

When you run models **locally**, the best model isn't the biggest — it's the
**smallest and fastest one that can still do the job**. Every extra GB of model
is RAM you don't have and seconds you wait. So this harness scores two things as
**co-equal**:

- **Accuracy** — does the produced code actually pass the tests? (fraction of
  hidden sub-tests passing)
- **Speed** — how long did the tool+model take? (`seconds` per run, surfaced as
  `avg s` in the leaderboard)

The headline question per task is therefore: **what is the smallest / fastest
local model that reliably passes — and which tool gets the most out of it?**
Tool choice matters as much as model choice, especially on smaller models.

## The design criteria

1. **Folders with individual test cases** — every task lives in `cases/<id>/`,
   self-contained: the prompt, the starter code, and a hidden grader.
2. **Objective verification + timing** — each case ships a hidden test suite;
   the score is the fraction of tests passing after the model edits the code,
   **and** the wall-clock time is recorded. Both go in `results/<ts>/results.csv`.
   (An optional LLM-judge quality score can be layered on later — see
   [docs/SCORING.md](docs/SCORING.md).)
3. **Ease of setup & model discovery** — one OpenAI-compatible endpoint
   (LM Studio) feeds every tool. Adding a model = download it in LM Studio +
   one line in `models.txt`. See [docs/SETUP.md](docs/SETUP.md) for how each
   CLI/extension discovers models.

## Documentation

- [docs/CASES.md](docs/CASES.md) — **precise spec of every test case + the run
  procedure** (enough to recreate each case's code in another framework).
- [docs/SCORING.md](docs/SCORING.md) — how scoring (accuracy + speed) works.
- [docs/SETUP.md](docs/SETUP.md) — LM Studio, per-tool provider config, IDE
  extensions, and the hermes no-yolo setup.
- [docs/ADDING-CASES.md](docs/ADDING-CASES.md) — how to add a new case.
- [BENCHMARK-RESULTS.md](BENCHMARK-RESULTS.md) — recorded results + per-tool
  findings across models.

## What's tested

**CLIs** (one adapter each in `adapters/`): `aider`, `opencode`, `codex`,
`caveman`, `hermes`. **Editors/extensions** (same LM Studio server):
VS Code + Cline/Continue, JetBrains plugins — see `docs/SETUP.md`.

**Languages**: JavaScript, TypeScript, Bash/CLI. Test cases use Node's built-in
test runner and shell assertions — **zero dependencies to install** (Node 24+
runs `.ts` directly via type-stripping).

**Case kinds** (full spec in [docs/CASES.md](docs/CASES.md)): one-shot bugfix /
feature edits, **multi-file** edits, and **self-verifying** tasks that ship a
test/lint suite in the workdir and instruct the agent to *iterate until green*
(this is what separates agents that run a verify-fix loop from those that don't).

## Quick start

```bash
lms server start          # start LM Studio's OpenAI-compatible server
bin/doctor                # check server, installed CLIs, models, cases
bin/smoke                 # load a small model, verify every tool can drive it
bin/bench                 # run the full matrix (adapters x models x cases)
bin/report                # re-print the leaderboard from the latest run
```

`bin/smoke` is the recommended first step on a new machine: it loads
`$SMOKE_MODEL` (a small model, auto-unloaded after idle) and runs one trivial
task through every adapter, classifying each as **PASS** / **PARTIAL** (reached
the model, didn't finish) / **FAIL** (couldn't reach the model — a wiring issue
to fix in `adapters/`). It flushes out provider-flag problems before you spend
time on a full benchmark.

Narrow a run while iterating:

```bash
bin/bench --adapters aider,opencode --models qwen/qwen3-coder-30b --cases js-01-slugify-bug
bin/bench --list          # show what would run, without running
```

Results land in `results/<timestamp>/`: a `results.csv` plus a per-run sandbox
with each tool's edits and logs (`.bench.log`) for inspection.

## Layout

```
config.sh            endpoint + defaults (edit to match your setup)
models.txt           models under test — one LM Studio id per line
adapters/<cli>.sh    how each CLI is driven non-interactively against LM Studio
cases/<id>/          task.md (prompt) + workdir/ (starter) + check/ (hidden grader)
lib/                 shared bash helpers + the node:test scorer
bin/bench            run the matrix    bin/report  leaderboard    bin/doctor  preflight
docs/                CASES.md (per-case spec), SCORING.md, SETUP.md, ADDING-CASES.md
```

## Adding things

- **A model**: download in LM Studio, add its id to `models.txt`. (`docs/SETUP.md`)
- **A test case**: copy a `cases/<id>/` folder. (`docs/ADDING-CASES.md`)
- **A CLI**: drop a `adapters/<name>.sh` following the adapter contract. (`docs/SETUP.md`)
