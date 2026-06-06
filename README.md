# local-model-editor-bench

A small, repeatable harness for testing how well **local models** (served by
[LM Studio](https://lmstudio.ai)) perform as **code editors**, across several
agentic coding CLIs — and, via the same local server, VS Code / IntelliJ
extensions.

It answers one question per model: *given a real editing task, does the code it
produces actually pass the tests?*

## The three design criteria

1. **Folders with individual test cases** — every task lives in `cases/<id>/`,
   self-contained: the prompt, the starter code, and a hidden grader.
2. **Verification / score of quality** — grading is *objective*: each case ships
   a hidden test suite; the score is the fraction of tests that pass after the
   model edits the code. (An optional LLM-judge quality score can be layered on
   later — see `docs/SCORING.md`.)
3. **Ease of setup & model discovery** — one OpenAI-compatible endpoint
   (LM Studio) feeds every tool. Adding a model = download it in LM Studio +
   one line in `models.txt`. See `docs/SETUP.md` for how each CLI/extension
   discovers models.

## What's tested

**CLIs** (one adapter each in `adapters/`): `aider`, `opencode`, `codex`,
`caveman`, `hermes`. **Editors/extensions** (same LM Studio server):
VS Code + Cline/Continue, JetBrains plugins — see `docs/SETUP.md`.

**Languages**: JavaScript, TypeScript, Bash/CLI. Test cases use Node's built-in
test runner and shell assertions — **zero dependencies to install** (Node 24+
runs `.ts` directly via type-stripping).

## Quick start

```bash
lms server start          # start LM Studio's OpenAI-compatible server
bin/doctor                # check server, installed CLIs, models, cases
bin/bench                 # run the full matrix (adapters x models x cases)
bin/report                # re-print the leaderboard from the latest run
```

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
docs/                SETUP.md (tools + extensions), SCORING.md, ADDING-CASES.md
```

## Adding things

- **A model**: download in LM Studio, add its id to `models.txt`. (`docs/SETUP.md`)
- **A test case**: copy a `cases/<id>/` folder. (`docs/ADDING-CASES.md`)
- **A CLI**: drop a `adapters/<name>.sh` following the adapter contract. (`docs/SETUP.md`)
