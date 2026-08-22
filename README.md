# Local Model Evaluator Bench

Get a **working local coding agent** on a new machine fast — and, when you want it,
a repeatable harness for **benchmarking local models** on agentic coding workflows
(the smallest, fastest model that reliably passes real test cases), across CLIs
([aider](docs/tools/aider.md), [hermes](docs/tools/hermes.md), [opencode](docs/tools/opencode.md), etc.)
and IDE extensions (VS Code + Cline/Continue, JetBrains).

---

## Getting Started

There are two ways to use this repo. Most people want Path A.

### Path A — Get a working local coding agent (≈20 min)

Detect your hardware, install a runtime + model + one or two agents, wire them to
your local server, and prove it works. Full walkthrough →
**[ONBOARDING.md](docs/ONBOARDING.md)** (step-by-step guide) or
**[WORKFLOWS.md](docs/WORKFLOWS.md)** (visual flowcharts with next-steps guidance).

```bash
lms server start                # start LM Studio's OpenAI-compatible server (or: ollama serve)
bin/setup                       # status: what's installed, your RAM tier, recommended model
bin/setup --agent aider,hermes  # install + WIRE agents (writes each agent's native config → config.sh)
bin/doctor                      # confirm server, model, AND agent configs are correct
bin/smoke --agent aider,hermes  # prove each agent can actually drive the model
```

Each step is idempotent — safe to re-run. See [SETUP.md](docs/SETUP.md) for agent configuration and IDE extension setup.

### Path B — Benchmark everything (advanced)

Measure which model × tool is the smallest/fastest that still passes on your
machine. Full guide → [ONBOARDING.md](docs/ONBOARDING.md) (Path B).

```bash
lms server start
bin/bench --agent hermes --trials 3 && bin/report --all --save && bin/viz
```

Results go to `results/<timestamp>/` (CSV + HTML dashboard at `results/index.html`).

---

## Why This Project

The best **local** model isn't the biggest — it's the smallest and fastest that passes. Score accuracy and speed as co-equal. See [PURPOSE.md](docs/PURPOSE.md) for full rationale.

Three phases: **Bench** (this machine) → **Run** (production) → **Port** (other machines). See [HARDWARE-RECOMMENDATIONS.md](docs/HARDWARE-RECOMMENDATIONS.md) for per-tier guidance.

## How It Works

Test cases → Run all adapters × models → Grade objectively → Measure speed → Leaderboard.

See [CASES.md](docs/CASES.md) for test specifications, [WORKFLOW.md](docs/WORKFLOW.md) for benchmarking process, and [SCORING.md](docs/SCORING.md) for accuracy/speed scoring.

---

## Documentation Hub

### Getting Started (Do This First)

- [**ONBOARDING.md**](docs/ONBOARDING.md) — step-by-step guide: detect hardware → configure → verify → benchmark
- [**WORKFLOWS.md**](docs/WORKFLOWS.md) — visual flowcharts for 6 main workflows (Quick Setup, Full Benchmarking, Maintenance Loop, Model Management, Debug Failure, Multi-Machine). Each command prints "Next steps:" so you don't need to read docs.
- [**TOOLS.md**](docs/TOOLS.md) — all available bin/* commands with subcommands and flags
- [**SETUP.md**](docs/SETUP.md) — LM Studio setup, per-tool config, IDE extensions, context window tuning
- [**WORKFLOW.md**](docs/WORKFLOW.md) — technical: how to add adapters, manage models, understand the benchmark harness (for developers)

### Core Concepts (Understanding the System)

- [**PURPOSE.md**](docs/PURPOSE.md) — why this harness exists, what it measures, what it doesn't
- [**CASES.md**](docs/CASES.md) — precise spec of every test case + the run procedure
- [**SCORING.md**](docs/SCORING.md) — how accuracy and speed are computed; trials and medians

### Running & Debugging (Iteration)

- [**TESTING-STRATEGY.md**](docs/TESTING-STRATEGY.md) — the gated funnel (L0 wiring → L1 qualify → L2 benchmark → L3 confidence)
- [**CLI-DISCOVERY.md**](docs/CLI-DISCOVERY.md) — the Command Boundary Pattern: every tool shows what to do next
- [**MODEL-RESEARCH.md**](docs/MODEL-RESEARCH.md) — dated candidates worth testing, with sources and re-runnable search queries
- [**Troubleshooting**](docs/troubleshooting-qwen-reasoning-loops.md) — common issues and fixes

### Further Reference

- [**FURTHER-READING.md**](docs/FURTHER-READING.md) — index of all additional reference materials (hardware, models, adapters, development, architecture, archived docs)
- [**archived/**](docs/archived/) — historical documents: decisions made, completed handoffs, prior planning

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

## The Pipeline

Run benchmarks, merge results, visualize:

```bash
bin/bench --agent hermes --trials 3        # Run benchmarks
bin/report --all --save && bin/viz         # Merge results, visualize
```

For detailed command options, workflow diagrams, and debugging, see:
- **All commands:** [TOOLS.md](docs/TOOLS.md)
- **Visual workflows:** [WORKFLOWS.md](docs/WORKFLOWS.md)
- **Variance & scoring:** [SCORING.md](docs/SCORING.md)
- **Debugging a run:** [TOOLS.md#debugging--investigation](docs/TOOLS.md#debugging--investigation)

## File Structure

```
config.sh                endpoint URL + defaults (BENCH_CONTEXT, BENCH_PARALLEL, etc.)
adapters/<name>.sh       how each CLI is driven non-interactively
cases/<id>/              task.md (prompt) + workdir/ (code) + check/ (hidden grader)
lib/                     shared bash helpers (common.sh, grader.sh, node-test-score.sh, etc.)
results/<ts>/            per-run output: results.csv, sandbox, logs
config-templates/        example Modelfiles, agent configs, snippets
docs/                    documentation hub (see above)
  models/                per-model cards
  tools/                 per-tool cards
  extensions/            IDE plugins
  runtimes/              LM Studio, Ollama, MLX (see also RUNTIME-OMLX.md for oMLX)
  templates/             card templates
```

---

## All Tools & Scripts

The complete reference of tools and scripts is available in **[TOOLS.md](docs/TOOLS.md)**.

Key tools are:
- **Setup & Verification**: `bin/setup`, `bin/doctor`, `bin/smoke`
- **Benchmarking**: `bin/bench`, `bin/stale`, `bin/bench-overnight`
- **Results**: `bin/report` (with `--all`, `--save`, `--viz`, `--evals` flags)
- **Debugging**: `bin/debug`, `bin/test-ide`
- **Management**: `bin/model`, `bin/clean`, `bin/watch`, `bin/rt`
- **Quality**: `bin/lint`, `bin/card`

For detailed usage and all available scripts, see [**docs/TOOLS.md**](docs/TOOLS.md).

---

## Adding & Contributing

- **Add a model** → download it (LM Studio/Ollama/etc. auto-discover it live), create a card in `docs/models/` (see [SETUP.md](docs/SETUP.md))
- **Add a test case** → copy a `cases/<id>/` folder, follow [ADDING-CASES.md](docs/ADDING-CASES.md)
- **Add a CLI tool** → drop `adapters/<name>.sh` following the contract, add a card in `docs/tools/` (see [SETUP.md](docs/SETUP.md))
- **Add an IDE extension** → test locally, add a card in `docs/extensions/` (see [docs/extensions/README.md](docs/extensions/README.md))

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
