# Local Model Evaluator Bench

Small, repeatable harness for testing how well **local models** (served by
[LM Studio](https://lmstudio.ai)) perform on **agentic coding workflows**, across
several agentic coding CLIs — and, via the same local server, VS Code / IntelliJ
extensions.

## End goal

The target workload is a **multi-agent orchestration setup**: an orchestrator
model directing 2–3 coding agents, all running concurrently against the same
local model. That means the model must handle parallel inference slots
(`--parallel 3–4`) without degrading, and the cases must reflect realistic
agentic sub-tasks — not just one-shot edits.

The current single-agent cases are the foundation. They establish baseline
accuracy and speed per (tool, model) pair. Multi-agent cases (orchestrator +
sub-agents, concurrent tool calls, hand-off patterns) are the next layer.

## Purpose

When you run models **locally**, the best model isn't the biggest — it's the
**smallest and fastest one that can still do the job under realistic load**.
Every extra GB of model is RAM you don't have; every extra second per sub-task
multiplies across all agents. So this harness scores two things as **co-equal**:

- **Accuracy** — does the produced code actually pass the tests? (fraction of
  hidden sub-tests passing)
- **Speed** — how long did the tool+model take? (`seconds` per run, surfaced as
  `med s` in the leaderboard)

The headline question per task is: **what is the smallest / fastest local model
that reliably passes at realistic concurrency — and which tool gets the most out
of it?** Tool choice matters as much as model choice, especially on smaller models.

> **`--parallel` and benchmarking realism:** `config.sh` sets `BENCH_PARALLEL=3`
> (orchestrator + 2–3 agents, the target workload). Drop to `BENCH_PARALLEL=1`
> for best single-request throughput. When memory allows — especially for small
> models on a 128 GB machine — benchmark at the concurrency you'll actually run
> (e.g. `BENCH_PARALLEL=4`) to see how accuracy and latency hold up under load.
> A model that scores well at `--parallel 1` but degrades at `--parallel 4` is
> not a good fit for a multi-agent setup.

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
4. **Favour modern-efficiency architectures** — because the goal is
   *smallest/fastest that still passes*, prefer models built for fast local
   inference: **MLX**-native builds on Apple Silicon, **MoE / A3B** (sparse,
   few active params → big-model quality at small-model speed), **QAT**
   (quantization-aware-trained → runs quantized with little quality loss), and
   **MTP** (multi-token prediction → ~1.4–2× generation speed, no accuracy
   cost). These features are what keep a large local model fast enough to be
   worth benchmarking. Pick a **quantization** that matches the workload — see
   the model-selection guidance in [docs/SETUP.md](docs/SETUP.md#2-adding-a-model-under-test).

## Documentation

- [docs/CASES.md](docs/CASES.md) — **precise spec of every test case + the run
  procedure** (enough to recreate each case's code in another framework).
- [docs/SCORING.md](docs/SCORING.md) — how scoring (accuracy + speed) works.
- [docs/TESTING-STRATEGY.md](docs/TESTING-STRATEGY.md) — the gated funnel (L0 wiring → L1 qualify+prune → L2 core bench → L3 confidence) for deciding how much effort to spend per combo.
- [docs/SETUP.md](docs/SETUP.md) — LM Studio, per-tool provider config, IDE
  extensions, and the hermes no-yolo setup.
- [docs/extensions/](docs/extensions/) — IDE extension / plugin recommendations
  (separate category from CLI adapters); start with
  [Cline](docs/extensions/cline.md).
- [docs/ADDING-CASES.md](docs/ADDING-CASES.md) — how to add a new case.
- [docs/MODEL-RESEARCH.md](docs/MODEL-RESEARCH.md) — dated log of model candidates
  worth benchmarking, with sources + re-runnable search queries.
- [BENCHMARK-RESULTS.md](BENCHMARK-RESULTS.md) — recorded results + per-tool
  findings across models.
- [LEADERBOARD.md](LEADERBOARD.md) — auto-generated leaderboard tables
  (written by `bin/report --all --save`; `bin/viz` builds the HTML dashboard at
  `results/index.html`).

## What's tested

**CLIs** (one adapter each in `adapters/`): `aider`, `opencode`, `codex`,
`caveman`, `hermes`. **Editors/extensions** (same LM Studio server, separate
category — graded by hand): VS Code + Cline/Continue, JetBrains plugins — see
[docs/extensions/](docs/extensions/) and `docs/SETUP.md`.

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
```

`bin/smoke` is the recommended first step on a new machine: it loads
`$SMOKE_MODEL` (a small model, auto-unloaded after idle) and runs one trivial
task through every adapter, classifying each as **PASS** / **PARTIAL** (reached
the model, didn't finish) / **FAIL** (couldn't reach the model — a wiring issue
to fix in `adapters/`). It flushes out provider-flag problems before you spend
time on a full benchmark.

## The pipeline: start → ingest → evaluate → visualize

The four stages, each one script. Run them in order (or the one-liner at the end):

```bash
# 1. START — run the matrix (adapters x models x cases), grade, score.
bin/bench                              # everything: all adapters x all models.txt x all cases
bin/bench --tool hermes --trials 3     # one adapter, 3 trials → records the MEDIAN

# 2. INGEST — merge runs into the leaderboard.
bin/report --all                       # merge ALL runs (latest result per adapter+model+case)
bin/report --all --save                # same, and persist → LEADERBOARD.md (repo root)

# 3. EVALUATE — build the context bundle for the per-model / per-tool eval pages.
bin/gen-evals --all | claude --print   # or run /gen-evals --all interactively
                                       # → refreshes docs/models/*.md and docs/tools/*.md

# 4. VISUALIZE — rebuild the interactive HTML dashboard.
bin/viz                                # regenerate results/index.html from all run CSVs
```

One-liner for the common case:

```bash
bin/bench --tool hermes --trials 3 && bin/report --all --save && bin/viz
```

> **Context window — Hermes needs ≥64K.** `config.sh` sets `BENCH_CONTEXT=65536`.
> Hermes Agent **hard-refuses any model loaded with <64K context** and aborts on
> startup (`error(1)` in ~3s), which silently zeroes every hermes trial. Keep
> `BENCH_CONTEXT` at 65536 or higher; on a 128 GB machine the extra KV cache is
> cheap. (`bin/bench` applies this at model-load time automatically.)

Narrow a run while iterating:

```bash
bin/bench --tool aider,opencode --models qwen/qwen3-coder-30b --cases js-01-slugify-bug
bin/bench --trials 3 --cases js-01-slugify-bug   # repeat each triple 3x, record medians
bin/bench --list          # show what would run, without running
bin/bench -i              # fzf pickers for models and tools
```

Run-to-run variance is material (a triple can swing 4/4 → 0/4 between identical
runs), so `--trials N` repeats each `(tool, model, case)` and records the
**median** score and seconds; per-trial detail lands in `trials.csv`. See
[SCORING.md](docs/SCORING.md#trials-and-medians---trials-n).

Results land in `results/<timestamp>/`: a `results.csv` plus a per-run sandbox
with each tool's edits and logs (`.bench.log`) for inspection.

When a pass-rate alone can't explain a result, inspect the model's actual tool
calls: `bin/trace-edit <adapter> <model> [case]` runs one triple and dumps its
pi/caveman session transcript via `bin/trace-tool-calls` (which also reads any
stored session or `--latest`) — flagging e.g. the qwen3-coder edit-tool
mangling that a `write`-fallback hides from the score. See [docs/tools/pi.md](docs/tools/pi.md).

## Layout

```
config.sh            endpoint + defaults (edit to match your setup)
models.txt           models under test — one LM Studio id per line
adapters/<cli>.sh    how each CLI is driven non-interactively against LM Studio
cases/<id>/          task.md (prompt) + workdir/ (starter) + check/ (hidden grader)
lib/                 shared bash helpers + the node:test scorer
bin/doctor preflight  bin/smoke wiring check  bin/bench run matrix
bin/report leaderboard  bin/gen-evals eval-page bundle  bin/viz HTML dashboard
docs/                CASES.md (per-case spec), SCORING.md, SETUP.md, ADDING-CASES.md
```

## Adding things

- **A model**: download in LM Studio, add its id to `models.txt`. (`docs/SETUP.md`)
- **A test case**: copy a `cases/<id>/` folder. (`docs/ADDING-CASES.md`)
- **A CLI**: drop a `adapters/<name>.sh` following the adapter contract. (`docs/SETUP.md`)

## Further reading

### Runtime selection & benchmarks
- [Choosing an On-Device LLM Runtime on Apple Silicon: A Decision Framework Beyond Benchmarks](https://medium.com/@michael.hannecke/choosing-an-on-device-llm-runtime-on-apple-silicon-a-decision-framework-beyond-benchmarks-2449067b8b67) — goes beyond tok/s to cover context handling, API surface, and agentic fit
- [Local LLM on iPhone: MLX vs llama.cpp vs LiteRT-LM vs CoreML](https://rockyshikoku.medium.com/local-llm-on-iphone-which-runtime-is-actually-fastest-58096685481e) — cross-runtime speed comparison on Apple Silicon (May 2026)
- [Prefix caching: SGLang vs vLLM — token-level radix tree vs block-level hashing](https://medium.com/byte-sized-ai/prefix-caching-sglang-vs-vllm-token-level-radix-tree-vs-block-level-hashing-b99ece9977a1)

### Apple Silicon & MLX
- [WWDC26 session 232: Run local agentic AI on the Mac using MLX](https://developer.apple.com/videos/play/wwdc2026/232/) — Apple's official agentic stack: `mlx_lm.server`, continuous batching, M5 Neural Accelerators, distributed inference over Thunderbolt
- [WWDC26 session 233: Explore distributed inference and training with MLX](https://developer.apple.com/videos/play/wwdc2026/233/) — multi-Mac model sharding
- [Exploring LLMs with MLX and the Neural Accelerators in the M5 GPU](https://machinelearning.apple.com/research/exploring-llms-mlx-m5) — Apple ML Research on M5 kernel selection and throughput
- [LM Studio MLX Engine — agentic workloads (v1.8.5, June 2026)](https://lmstudio.ai/blog/mlx-engine-agentic-workloads) — disk-backed KV cache checkpointing at 256-token boundaries

### Model architectures relevant to local inference
- [Gemma 4 12B developer guide](https://developers.googleblog.com/gemma-4-12b-the-developer-guide/) — covers LiteRT-LM, MoE variants (E2B/E4B), and on-device deployment
- [Blazing fast on-device GenAI with LiteRT-LM](https://developers.googleblog.com/blazing-fast-on-device-genai-with-litert-lm/) — Google's edge runtime: MTP speculative decoding, session save/restore, constrained decoding
