# Onboarding: Step-by-Step Setup

Quick visual reference of the setup process, plus detailed guides for each path.

## Flow at a Glance

```
                     NEW MACHINE  ──  from nothing to a working agent
                     ═══════════════════════════════════════════════

  [0]  Get the code + a runtime
       git clone <repo> && cd local-model-evaluator-bench
       install LM Studio (`lms`)   ·or·   Ollama
                     │
                     ▼
  [1]  See what you have / need ........... bin/setup
  [2]  Start the model server ............. lms server start (or: ollama serve)
  [3]  Download a model ................... lms get qwen/qwen3.6-27b
  [4]  Install & WIRE agents .............. bin/setup --agent aider,hermes
  [5]  Check everything ................... bin/doctor
  [6]  Prove it end-to-end ................ bin/smoke --agent aider,hermes
  [7]  Use it in CLI/IDE .................. aider <file>   ·or·   cline in VS Code
```

**Full visual flowcharts:** See [docs/WORKFLOWS.md](WORKFLOWS.md) for ASCII diagrams with decision points and next-steps guidance at each stage.

---

## Pick Your Path

### Path A: Quick Setup (≈20 min)
**Goal:** Working local coding agent you can use right now.

1. Install a runtime (LM Studio, Ollama, or MLX) — see [SETUP.md](SETUP.md) for detailed instructions
2. Start the server: `lms server start` (or `ollama serve`)
3. Download a model: `lms get qwen/qwen3.6-27b`
4. Install agents: `bin/setup --agent aider,hermes`
5. Verify: `bin/doctor && bin/smoke --agent aider,hermes`
6. Use it: `aider <file>` or open VS Code + Cline

**More detailed:** [SETUP.md](SETUP.md) has step-by-step instructions for each runtime and agent configuration.

### Path B: Full Benchmarking (2–4 hours)
**Goal:** Measure which model × agent combo is best for your machine.

1. Detect hardware: `bin/hwprofile`
2. Apply tier config: `bin/bootstrap-machine --write`
3. Verify all adapters: `bin/smoke`
4. Run full benchmarks: `bin/bench --agent hermes --trials 3`
5. See results: `bin/report --all --save && bin/viz`

**More detailed:** [WORKFLOWS.md](WORKFLOWS.md) has full workflow diagrams. For technical reference, see [SETUP.md](SETUP.md), [WORKFLOW.md](WORKFLOW.md), and [HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md).

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "LM Studio not reachable" | Is the server running? `lms server start` |
| "Agent not on PATH" | `which aider` — reinstall if missing |
| "Model won't load" | `lms ls` to list, `lms load <id>` to load |
| "Smoke test fails" | Check `results/<timestamp>/sandbox/` for logs |
| "Benchmark too slow" | Try smaller models; see [HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md) for your RAM tier |

For more detailed troubleshooting, see [SETUP.md](SETUP.md) and run `bin/doctor` — it shows exactly what's missing.

---

## Key Commands

Every command prints "Next steps:" at completion. For full reference, see [TOOLS.md](TOOLS.md).

| Command | Purpose |
|---------|---------|
| `bin/setup` | Detect RAM tier, recommend models, install agents |
| `bin/doctor` | Preflight check: is server reachable? Are models loaded? |
| `bin/smoke --agent <name>` | Quick end-to-end test (5–10 sec per agent) |
| `bin/bench --agent <name> --trials 3` | Full benchmark suite (30 min–2 hours) |
| `bin/report --all --save` | Merge results into leaderboard |
| `bin/model status` | Show installed & loaded models |
| `bin/debug <adapter> <model> <case>` | Run one test case, inspect transcript |

---

## What's Next

- **First time?** Start with Path A above, or read [SETUP.md](SETUP.md) for technical details
- **Want flowcharts?** See [WORKFLOWS.md](WORKFLOWS.md) for visual command sequences
- **Need reference?** See [TOOLS.md](TOOLS.md) for all available commands
- **Want details?** See [FURTHER-READING.md](FURTHER-READING.md) for additional docs
