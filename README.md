# Local Model Evaluator Bench

A repeatable harness for benchmarking **local models** on **agentic coding workflows** — measuring the smallest, fastest model that reliably passes real test cases, across CLIs ([aider](docs/tools/aider.md), [hermes](docs/tools/hermes.md), [opencode](docs/tools/opencode.md), etc.) and IDE extensions (VS Code + Cline/Continue, JetBrains).

---

## Quick Start

```bash
lms server start          # Start LM Studio's OpenAI-compatible server
bin/doctor                # Check server, CLIs, models, and test cases
bin/smoke                 # Verify every tool can reach the model
```

Then run a full benchmark:

```bash
bin/bench --agent hermes --trials 3 && bin/report --all --save && bin/viz
```

Results go to `results/<timestamp>/` (CSV + HTML dashboard at `results/index.html`).

---

## Why This Project

When you run models **locally**, the best model isn't the biggest — it's the **smallest and fastest one that still passes under realistic load**. Every extra GB is RAM you don't have; every extra second per task multiplies across all agents. So this harness scores two things as **co-equal**:

- **Accuracy** — does the produced code pass the hidden test suite?
- **Speed** — how many seconds did it take? (recorded per run, surfaced as `med s` in leaderboard)

The question: **what is the smallest / fastest local model that reliably passes at your target concurrency — and which tool gets the most out of it?**

See [docs/PURPOSE.md](docs/PURPOSE.md) for the full rationale and what this project explicitly does not measure.

### Three phases: Bench → Run → Port

This repo's work happens in three stages, each with a different scope:

1. **Bench (this machine)** — `bin/bench` exhaustively tests every (runtime ×
   model × adapter × case) combination on the machine you're developing on,
   scoring accuracy and speed for each. This is what most of this README
   documents.
2. **Run (any machine, once winners are known)** — once bench has identified
   the best runtime/model/adapter combos, use `llmrun` — a standalone
   dotfiles binary built from this repo (see
   [PLAN-CLI-UNIFICATION.md](docs/PLAN-CLI-UNIFICATION.md)) — to do real
   work with those combos, without needing this repo checked out.
   `bin/build-llmrun` generates it.
3. **Port (other machines, by RAM tier)** — carry what bench learned here to
   other machines (64 GB / 48 GB / 32 GB / 24 GB tiers) so they don't have to
   re-run the full matrix. See
   [HARDWARE-RECOMMENDATIONS.md](docs/HARDWARE-RECOMMENDATIONS.md) for
   per-tier guidance (currently 128 GB and 32 GB; more tiers in progress) and
   [PLAN-MULTI-MACHINE-PORTABILITY.md](docs/PLAN-MULTI-MACHINE-PORTABILITY.md)
   for the machine-readable bootstrap this is moving towards.

---

## How It Works (Simple → Detailed)

### The Basics

1. **Test cases** — lives in `cases/<id>/`: a prompt, starter code, and a hidden grader
2. **Run the matrix** — bin/bench runs every (adapter × model × case), grades each, records accuracy and time
3. **Merge results** — bin/report creates a leaderboard of (tool, model, score, speed)
4. **Visualize** — bin/viz builds an interactive HTML dashboard

### Realistic Concurrency

The target workload is multi-agent: an orchestrator directing 2–3 agents all running concurrently against the same local model. `config.sh` sets `BENCH_PARALLEL=3` (orchestrator + 2–3 agents); drop to `BENCH_PARALLEL=1` for single-request throughput, or bump to `BENCH_PARALLEL=4` to stress-test under realistic load. A model that scores well at `--parallel 1` but degrades at `--parallel 4` is not a good fit for agentic workloads.

### Design Criteria

- **Self-contained test cases** — each case in `cases/<id>/` has its own prompt, code, and grader
- **Objective verification + timing** — hidden test suites grade the model's edits; wall-clock time is recorded
- **One endpoint feeds everything** — LM Studio (OpenAI-compatible API) serves all tools. Adding a model = download + one line in `models.txt`
- **Modern-efficiency architectures preferred** — MLX (Apple Silicon), MoE/A3B (sparse), QAT (quantized), MTP (multi-token prediction) keep large models fast enough to benchmark locally

---

## Documentation Hub

### Getting Started (Do This First)

- [**WORKFLOW.md**](docs/WORKFLOW.md) — the complete workflow: adding adapters & models, running tests, interpreting results, managing incompatibilities
- [**SETUP.md**](docs/SETUP.md) — LM Studio setup, per-tool config, IDE extensions, context window tuning

### Core Concepts (Understanding the System)

- [**PURPOSE.md**](docs/PURPOSE.md) — why this harness exists, what it measures, what it doesn't
- [**CASES.md**](docs/CASES.md) — precise spec of every test case + the run procedure
- [**SCORING.md**](docs/SCORING.md) — how accuracy and speed are computed; trials and medians

### Running & Debugging (Iteration)

- [**TESTING-STRATEGY.md**](docs/TESTING-STRATEGY.md) — the gated funnel (L0 wiring → L1 qualify → L2 benchmark → L3 confidence)
- [**MODEL-RESEARCH.md**](docs/MODEL-RESEARCH.md) — dated candidates worth testing, with sources and re-runnable search queries
- [**Troubleshooting**](docs/troubleshooting-qwen-reasoning-loops.md) — common issues and fixes

### Adding & Extending (Contributing)

- [**ADDING-CASES.md**](docs/ADDING-CASES.md) — how to add a new test case
- [**CARD-SPEC.md**](docs/CARD-SPEC.md) — structure + validation rules for model/tool/runtime cards
- [**HARDWARE-RECOMMENDATIONS.md**](docs/HARDWARE-RECOMMENDATIONS.md) — choosing a machine for benchmarking

### Results & Leaderboards

- [**LEADERBOARD.md**](LEADERBOARD.md) — auto-generated rankings (tool × model, accuracy + speed)
- [**BENCHMARK-RESULTS.md**](BENCHMARK-RESULTS.md) — recorded results + per-tool findings
- [**REPORT-2026-06-30.md**](docs/REPORT-2026-06-30.md) — latest survey of tested models and tools

### Models, Tools & Runtimes (Reference)

- **Models** → [docs/models/](docs/models/) — per-model cards (Qwen, Gemma, Phi, Mistral, etc.)
- **Tools/CLIs** → [docs/tools/](docs/tools/) — per-tool cards (aider, hermes, opencode, caveman, Cline, Continue, etc.)
- **Extensions** → [docs/extensions/](docs/extensions/) — IDE integrations (VS Code, JetBrains plugins)
- **Runtimes** → [docs/runtimes/](docs/runtimes/) — LM Studio, Ollama, MLX

### Templates & Examples

- [**model-card-template.md**](docs/templates/model-card-template.md) — template for new model cards
- [**tool-card-template.md**](docs/templates/tool-card-template.md) — template for new tool cards
- [**runtime-card-template.md**](docs/templates/runtime-card-template.md) — template for new runtime cards

### Deep Dives & Decisions (Advanced)

- [**AGENT-EVAL-SUITE.md**](docs/AGENT-EVAL-SUITE.md) — 100-question suite for grading agentic capability
- [**MODEL-EVAL-REQUIREMENTS.md**](docs/MODEL-EVAL-REQUIREMENTS.md) — what makes a model suitable for benchmarking
- [**TOOL-EVAL-REQUIREMENTS.md**](docs/TOOL-EVAL-REQUIREMENTS.md) — what makes a tool suitable for inclusion
- [**AGENT-SELECTION.md**](docs/AGENT-SELECTION.md) — how to choose which agents to benchmark
- [**IMPLEMENTATION-SUMMARY.md**](docs/IMPLEMENTATION-SUMMARY.md) — architecture + trade-offs
- [**FUTURE-IDEAS.md**](docs/FUTURE-IDEAS.md) — planned work
- [**PLAN-MULTI-MACHINE-PORTABILITY.md**](docs/PLAN-MULTI-MACHINE-PORTABILITY.md) — bench → run → port: bootstrapping other machines by RAM tier from this machine's learnings
- **Decision logs** → [docs/DECISION-*.md](docs/) — rationale for major project decisions (cloud-only tools, proxy design, etc.)

## What's Tested

**CLIs/Adapters** → [docs/tools/](docs/tools/):
- Benchmarked: [aider](docs/tools/aider.md), [hermes](docs/tools/hermes.md), [opencode](docs/tools/opencode.md), [caveman](docs/tools/caveman.md), [codex](docs/tools/codex.md), [pi](docs/tools/pi.md)
- Also tested: [Cline](docs/tools/cline.md), [Continue](docs/tools/continue.md), [kilocode](docs/tools/kilocode.md), [goose](docs/tools/goose.md), and others

**Languages**: JavaScript, TypeScript, Bash/CLI. Test cases use Node's built-in test runner and shell assertions — **zero dependencies to install** (Node 24+ runs `.ts` directly).

**Case kinds** (full spec in [docs/CASES.md](docs/CASES.md)):
- One-shot bugfix / feature edits
- Multi-file edits
- Self-verifying tasks (ship a test suite; agent iterates until green)

---

## The Pipeline: Bench → Report → Evaluate → Visualize

Four stages, each a script. Run in order or use the one-liner:

### 1. **Bench** — Run the full matrix

```bash
bin/bench                              # All adapters × all models × all cases
bin/bench --agent hermes --trials 3    # One adapter, 3 trials (records MEDIAN)
bin/bench --agent aider,opencode --models qwen/qwen3-coder-30b --cases js-01-slugify-bug  # Narrow scope
bin/bench --list                       # Show what would run, without running
bin/bench -i                           # Interactive fzf pickers for models and tools
```

Results go to `results/<timestamp>/`: a `results.csv` plus per-run sandboxes with logs.

### 2. **Report** — Merge runs into the leaderboard

```bash
bin/report --all                       # Merge all runs (latest result per combo)
bin/report --all --save                # Same, persist to LEADERBOARD.md
```

### 3. **Evaluate** — Build per-model / per-tool pages

```bash
bin/gen-evals --all | claude --print   # (or run /gen-evals --all interactively)
                                       # → refreshes docs/models/*.md and docs/tools/*.md
```

### 4. **Visualize** — Rebuild the HTML dashboard

```bash
bin/viz                                # Regenerate results/index.html from all run CSVs
```

**One-liner for the common case:**

```bash
bin/bench --agent hermes --trials 3 && bin/report --all --save && bin/viz
```

### Understanding Variance and Medians

Run-to-run variance is material (a triple can swing 4/4 → 0/4 between identical runs). Use `--trials N` to repeat each (tool, model, case) N times and record the **median** score and seconds; per-trial details land in `trials.csv`. See [SCORING.md](docs/SCORING.md#trials-and-medians---trials-n).

### Debugging a Run

When accuracy alone doesn't explain a result, inspect the model's actual tool calls:

```bash
bin/trace-edit <adapter> <model> [case]       # Run one triple, dump session transcript
bin/trace-tool-calls [--latest]               # Read transcript, flag mangling (e.g. edit-tool issues)
```

### Important: Context Windows

**Hermes needs ≥64K context.** `config.sh` sets `BENCH_CONTEXT=65536`. Hermes **hard-refuses any model loaded with <64K context** and aborts on startup (~3s), silently zeroing every hermes trial. Keep `BENCH_CONTEXT` at 65536 or higher; on a 128 GB machine the extra KV cache is cheap.

## File Structure

```
config.sh                endpoint URL + defaults (BENCH_CONTEXT, BENCH_PARALLEL, etc.)
models.txt               models under test — one per line
adapters/<name>.sh       how each CLI is driven non-interactively
cases/<id>/              task.md (prompt) + workdir/ (code) + check/ (hidden grader)
lib/                     shared bash helpers (common.sh, grader.sh, node-test-score.sh, etc.)
results/<ts>/            per-run output: results.csv, sandbox, logs
config-templates/        example Modelfiles, agent configs, snippets
docs/                    documentation hub (see above)
  models/                per-model cards
  tools/                 per-tool cards
  extensions/            IDE plugins
  runtimes/              LM Studio, Ollama, MLX
  templates/             card templates
```

---

## All Scripts

See [WORKFLOW.md](docs/WORKFLOW.md) for detailed usage of each script.

### Core Pipeline
- `bin/setup` — check and install required tools
- `bin/doctor` — preflight check: server, CLIs, models, cases
- `bin/smoke` — verify every tool can reach the model
- `bin/bench` — run the matrix (adapters × models × cases)
- `bin/report` — merge runs into the leaderboard
- `bin/gen-evals` — build per-model / per-tool eval pages
- `bin/viz` — rebuild the HTML dashboard

### Iteration & Debugging
- `bin/bench --list` — show what would run, without running
- `bin/bench -i` — interactive fzf pickers
- `bin/bench --trials N` — repeat and record medians
- `bin/investigate` — triage failing combos
- `bin/stale` — emit worklist of outdated runs
- `bin/trace-edit <adapter> <model> [case]` — run one triple, dump transcript
- `bin/trace-tool-calls` — inspect tool calls, flag mangling

### Maintenance & Operations
- `bin/bench-overnight` — benchmark low-footprint models with Ollama
- `bin/nightly` — prepare and run nightly bench
- `bin/lms_gc` — unload idle models
- `bin/lms_update` — re-download outdated models
- `bin/prune` — list and remove downloaded models
- `bin/outdated` — check if local models are behind upstream
- `bin/rt` — runtime status and control
- `bin/hwprofile` — detect RAM and report the nearest benchmarked hardware tier (phase-3 porting)
- `bin/stale.test.sh` — tests for bin/stale

### Card & Quality Tools
- `bin/lint-cards` — validate model/tool cards against [CARD-SPEC.md](docs/CARD-SPEC.md)
- `bin/fix-card` — loop a model until it passes lint-cards
- `bin/eval-agent` — score an agent on the 100-question suite ([AGENT-EVAL-SUITE.md](docs/AGENT-EVAL-SUITE.md))

### Adapter & Model Tooling
- `bin/lint` — static checks for project scripts
- `bin/lint-adapters` — static checks for adapters
- `bin/setup-ollama-modelfile` — build custom Ollama model variants
- `bin/tool-call-proxy` — Ollama proxy for Qwen tool calls
- `bin/build-llmrun` — generate standalone llmrun launcher
- `bin/pi-patch-edit-shim` — reapply Qwen3-Coder edit-tool shim
- `bin/mlx-serve-qwen3-coder` — MLX server wrapper

---

## Adding & Contributing

- **Add a model** → download in LM Studio, add to `models.txt`, create a card in `docs/models/` (see [SETUP.md](docs/SETUP.md))
- **Add a test case** → copy a `cases/<id>/` folder, follow [ADDING-CASES.md](docs/ADDING-CASES.md)
- **Add a CLI tool** → drop `adapters/<name>.sh` following the contract, add a card in `docs/tools/` (see [SETUP.md](docs/SETUP.md))
- **Add an IDE extension** → test locally, add a card in `docs/extensions/` (see [docs/extensions/README.md](docs/extensions/README.md))

---

## Further Reading

### Runtime Selection & Benchmarks
- [Choosing an On-Device LLM Runtime on Apple Silicon: A Decision Framework Beyond Benchmarks](https://medium.com/@michael.hannecke/choosing-an-on-device-llm-runtime-on-apple-silicon-a-decision-framework-beyond-benchmarks-2449067b8b67) — context handling, API surface, agentic fit (beyond tok/s)
- [Local LLM on iPhone: MLX vs llama.cpp vs LiteRT-LM vs CoreML](https://rockyshikoku.medium.com/local-llm-on-iphone-which-runtime-is-actually-fastest-58096685481e) — cross-runtime speed on Apple Silicon (May 2026)
- [Prefix Caching: SGLang vs vLLM](https://medium.com/byte-sized-ai/prefix-caching-sglang-vs-vllm-token-level-radix-tree-vs-block-level-hashing-b99ece9977a1) — token-level radix tree vs block-level hashing

### Apple Silicon & MLX
- [WWDC26 #232: Run Local Agentic AI on Mac Using MLX](https://developer.apple.com/videos/play/wwdc2026/232/) — mlx_lm.server, continuous batching, M5 Neural Accelerators, distributed inference
- [WWDC26 #233: Distributed Inference & Training with MLX](https://developer.apple.com/videos/play/wwdc2026/233/) — multi-Mac model sharding
- [Exploring LLMs with MLX and M5 GPU Neural Accelerators](https://machinelearning.apple.com/research/exploring-llms-mlx-m5) — Apple ML Research on kernel selection and throughput
- [LM Studio MLX Engine — Agentic Workloads (v1.8.5, June 2026)](https://lmstudio.ai/blog/mlx-engine-agentic-workloads) — disk-backed KV cache checkpointing

### Model Architectures for Local Inference
- [Gemma 4 12B Developer Guide](https://developers.googleblog.com/gemma-4-12b-the-developer-guide/) — LiteRT-LM, MoE variants (E2B/E4B), on-device deployment
- [Blazing Fast On-Device GenAI with LiteRT-LM](https://developers.googleblog.com/blazing-fast-on-device-genai-with-litert-lm/) — MTP speculative decoding, session save/restore, constrained decoding

---

## Key Definitions

- **Accuracy** — fraction of hidden test cases passing after the model edits code
- **Speed** — wall-clock seconds per run (the `med s` column in leaderboard)
- **Concurrent agents** — multiple agents running in parallel against one model server (set via `BENCH_PARALLEL`)
- **Trials** — repeated runs of the same (tool, model, case); median score/speed is reported
- **Multi-file edits** — test cases requiring the agent to read/edit multiple files
- **Self-verifying** — test case that ships a test suite; agent must iterate until green
- **Adapter** — shell script that drives a CLI non-interactively against a local OpenAI-compatible endpoint
- **Card** — structured markdown file documenting a model, tool, or runtime

---

## Project Status

See [AGENTS.md](AGENTS.md) (ops automation), [TASKS.md](TASKS.md) (task tracking), and the latest [REPORT-2026-06-30.md](docs/REPORT-2026-06-30.md) for current activity and results.
