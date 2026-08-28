# All Tools & Scripts Reference

Complete listing of all bin/ tools. Most common workflows are discoverable via **next-steps guidance** in each tool — run any command with `--help` to see what to do next, or read [WORKFLOWS.md](WORKFLOWS.md) for visual flowcharts.

See [WORKFLOW.md](WORKFLOW.md) for detailed usage patterns and best practices.

## Core Pipeline

**The happy path: setup → doctor → smoke → bench → report**

- `bin/setup` — Check and install required tools. Shows your RAM tier and recommended model.
- `bin/doctor` — Preflight verification: is the server reachable? Are models loaded? Are agent configs correct?
- `bin/smoke` — Quick end-to-end test: run 2 lightweight cases per agent to prove it can drive the model.
- `bin/bench` — Run the full benchmark matrix: every (adapter × model × case) combination.
- `bin/report [--all] [--save] [--viz] [--evals]` — Generate leaderboards, dashboards, and eval pages.

## Model & Runtime Management

**Unified model and runtime control**

- `bin/model` — Unified model management (consolidates lms_gc, lms_update, prune, outdated)
  - `bin/model status` — Show all installed + loaded models
  - `bin/model update <id>` — Re-download a model
  - `bin/model remove <id>` — Delete a model
  - `bin/model cleanup` — Unload idle models

- `bin/rt` — Unified runtime control (consolidates omlx, litellm-proxy, lmstudio-context)
  - `bin/rt [status]` — Show RAM, runtimes, running bench
  - `bin/rt omlx status` — Check oMLX server status
  - `bin/rt litellm proxy` — Start LiteLLM proxy
  - `bin/rt lms-context verify` — Check LM Studio context window

- `bin/hwprofile` — Detect RAM and report the nearest benchmarked hardware tier (phase-3 porting)

## Debugging & Investigation

**When things go wrong**

- `bin/debug <adapter> <model> [case]` — Run one triple, capture full transcript
  - `bin/debug --calls --latest` — Inspect tool calls, flag mangling
  - `bin/debug --failures <run-id>` — Triage all failures from a run
  - `bin/debug --compare <run1> <run2>` — Compare two runs

- `bin/test-ide` — Interactively test IDE extensions (Cline/VS Code, Continue/IntelliJ) on individual cases

- `bin/stale` — Emit worklist of (adapter, model, case) combos that need running

## Validation & Quality

**Keep the codebase clean**

- `bin/lint [--all] [--scripts] [--adapters] [--cards] [--fix]` — Unified validation tool (consolidates lint, lint-adapters, lint-cards)
  - Syntax checks, shellcheck, adapter validation, card linting

- `bin/card [lint|fix|eval|status]` — Card management (consolidates cards, fix-card, eval-agent)

## Cleanup & Monitoring

**Disk space and progress tracking**

- `bin/clean [status|results|cache|all]` — Reclaim disk space (consolidates cleanup, results, wait-for-download)
  - `--dry-run` — preview what would be deleted
  - `--yes` — skip confirmation

- `bin/watch` — Monitor benchmark progress (new tool)
  - `bin/watch` — Tail latest benchmark log
  - `bin/watch --all` — Show all runs with status
  - `bin/watch --history [N]` — Show last N runs

## Building & Distribution

**Generate standalone packages**

- `bin/build [llmrun|onboarding|all]` — Build distributable packages (consolidates build-llmrun, build-onboarding)
  - `bin/build llmrun` — Generate standalone launcher
  - `bin/build onboarding` — Generate setup kit for new machines

## Advanced & Specialized

These tools are typically discoverable via **next-steps guidance** from the main pipeline:

- `bin/agents-config [--verify|--write|--agent <name>|--patch <agent>]` — Reconcile agent configs to config.sh
- `bin/bench-overnight` — Benchmark low-footprint models overnight with Ollama
- `bin/nightly` — Prepare and run nightly benchmark  
- `bin/recover-lms` — Recover corrupted LM Studio installations (macOS issues)
- `bin/verify-model-availability` — Check if models exist on HuggingFace / OllamaHUB
- `bin/qualify` — L1 filter: output viable (adapter, model) pairs from smoke results
- `bin/sweep-cards` — Automated card maintenance via local agent
- `bin/run` — Execution wrapper for orchestrated workflows
- `bin/test` — Run colocated shell test files (`.test.sh`)

## Discovery & Help

**Every tool prints next-steps guidance on completion.** To see what to do next:

```bash
bin/setup --help              # See all flags and next steps
bin/smoke                      # Prints "Next steps:" after completion
bin/bench --agent aider        # Prints "Next steps:" after run
```

Or read the visual workflows: [WORKFLOWS.md](WORKFLOWS.md)

**Building your own tools?** See [CLI-DISCOVERY.md](CLI-DISCOVERY.md) — it documents the pattern that all `bin/*` tools follow (next-steps guidance, help text format, dry-run modes). Use this as a reference when creating new tools.

## Pattern: Unified Tools with Subcommands

Recent consolidations follow a pattern for discoverability:

- **Instead of**: `bin/lms_gc`, `bin/lms_update`, `bin/prune`, `bin/outdated`
  - **Use**: `bin/model status|update|remove|cleanup`

- **Instead of**: `bin/build-llmrun`, `bin/build-onboarding`, `bin/setup-ollama-modelfile`
  - **Use**: `bin/build llmrun|onboarding|ollama-modelfile`

- **Instead of**: `bin/cleanup`, `bin/results`, `bin/wait-for-download`
  - **Use**: `bin/clean status|results|cache`

- **Instead of**: `bin/trace-edit`, `bin/trace-tool-calls`, `bin/investigate`
  - **Use**: `bin/debug <adapter> <model> [case]|--calls|--failures`

Each unified tool shows "Next steps:" on completion, guiding you through the workflow without documentation hunting.
