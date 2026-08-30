# Workflows & Command Sequences

Visual guides for the 6 main use cases, with "next steps" guidance at each stage. Each workflow shows the sequence of commands and what to do if something doesn't work.

See also: [CLI-DISCOVERY.md](CLI-DISCOVERY.md) for the pattern design, [ONBOARDING.md](ONBOARDING.md) for quick start.

---

## Workflow 1: PATH A — Quick Setup (20 minutes)

Get one local agent running end-to-end.

```
┌──────────────────────────────────────────────────────────────┐
│ STEP 0: Clone & Start Runtime                                │
├──────────────────────────────────────────────────────────────┤
│ $ git clone <repo> && cd local-model-evaluator-bench          │
│ $ lms server start                (or: ollama serve)          │
│                                                               │
│ Next: Check what's installed & needed                        │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 1: Status Check (bin/setup)                             │
├──────────────────────────────────────────────────────────────┤
│ $ bin/setup                                                  │
│                                                               │
│ Detects: RAM tier, recommended model, missing tools          │
│                                                               │
│ Next steps (printed):                                        │
│  1. Download a model                                         │
│  2. Install & configure agents                               │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 2: Install & Configure Agents                           │
├──────────────────────────────────────────────────────────────┤
│ $ bin/setup --agent aider,hermes                            │
│                                                               │
│ Installs agents & writes config.sh                          │
│                                                               │
│ Next steps (printed):                                        │
│  1. Verify with: bin/doctor                                 │
│  2. Test with: bin/smoke --agent aider,hermes              │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 3: Verify Configuration                                 │
├──────────────────────────────────────────────────────────────┤
│ $ bin/doctor                                                 │
│                                                               │
│ Checks: Server reachable? Model loaded? Agent configs OK?   │
│                                                               │
│ Next steps (printed):                                        │
│  • If ✓: Run smoke tests                                     │
│  • If ✗: See troubleshooting in SETUP.md                    │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 4: Smoke Test                                           │
├──────────────────────────────────────────────────────────────┤
│ $ bin/smoke --agent aider,hermes                            │
│                                                               │
│ Tests 2 lightweight cases per agent: PASS / PARTIAL / FAIL  │
│                                                               │
│ Next steps (printed):                                        │
│  • If ✓: You're ready! Use in CLI or IDE                    │
│  • If ✗: debug aider qwen3.5-9b <case>                     │
└──────────────────────────────────────────────────────────────┘
                            ↓
                      ✅ Ready to Use
                   (aider, hermes, or both
                    in CLI or IDE extension)
```

### If Something Fails

At any step, the command prints "Next steps:" with actionable guidance. Common issues:

**Server not running:**
```
$ bin/doctor
✗ LM Studio not reachable
  
Next steps:
  1. Start the server: lms server start
  2. Re-run: bin/doctor
```

**Agent test fails:**
```
$ bin/smoke --agent aider
...
FAIL: aider × qwen3.5-9b × smoke-01-edit-file

Next steps:
  1. Debug this case: bin/debug aider qwen3.5-9b smoke-01-edit-file
  2. Check the transcript: bin/debug --calls --latest
  3. Reinstall agent: bin/setup --agent aider --force
```

---

## Workflow 2: PATH B — Full Benchmarking

Measure accuracy and speed across all adapters, models, and test cases.

```
[Complete PATH A first: setup → doctor → smoke → all passing]
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 5: Run Benchmarks                                       │
├──────────────────────────────────────────────────────────────┤
│ $ bin/bench --agent hermes --trials 3                       │
│ (or: bin/bench -i  for interactive model/agent pickers)     │
│                                                               │
│ Runs all cases 3 times; records MEDIAN score & speed        │
│ Results → results/<timestamp>/results.csv                   │
│                                                               │
│ Next steps (printed):                                        │
│  • See results: bin/report --all                            │
│  • Visualize: bin/report --viz                              │
│  • Debug failures: bin/debug --failures <run-id>            │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 6: Generate Leaderboard                                 │
├──────────────────────────────────────────────────────────────┤
│ $ bin/report --all --save                                   │
│                                                               │
│ Updates LEADERBOARD.md with rankings                        │
│ (tool, model, accuracy %, speed in seconds)                 │
│                                                               │
│ Next steps (printed):                                        │
│  • Visualize: bin/report --viz                              │
│  • Update model cards: bin/report --evals                   │
│  • Compare runs: bin/report --compare <run1> <run2>         │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 7: Build Interactive Dashboard                         │
├──────────────────────────────────────────────────────────────┤
│ $ bin/report --viz                                          │
│                                                               │
│ Generates results/index.html (interactive charts)           │
│                                                               │
│ Next steps (printed):                                        │
│  • View: results/index.html                                 │
│  • Commit: git add LEADERBOARD.md results/ && git commit   │
│  • Share: Open index.html in browser                        │
└──────────────────────────────────────────────────────────────┘
                            ↓
                   ✅ Analysis Complete
              (Leaderboard + visualizations ready)
```

### Variations

**Quick test (single adapter, one trial):**
```bash
bin/bench --agent aider --cases js-01-slugify-bug --trials 1
```

**Test multiple adapters:**
```bash
bin/bench --agent aider,hermes,cline --trials 3
```

**Narrow to specific models:**
```bash
bin/bench --models qwen/qwen3.5-9b,llama/3.1-8b --trials 2
```

**Interactive picker:**
```bash
bin/bench -i
# Prompts for adapters and models
```

---

## Workflow 3: Maintenance & Overnight Loop

Automate: find what needs running → run → investigate → validate.

```
┌──────────────────────────────────────────────────────────────┐
│ STEP 1: Find Work (bin/stale)                                │
├──────────────────────────────────────────────────────────────┤
│ $ bin/stale --runtime lms > results/stale.csv               │
│                                                               │
│ Emits: (adapter, model, case) combos needing a run          │
│ Categories: missing, failed, outdated (input changed)       │
│                                                               │
│ Next steps (printed):                                        │
│  • Run them: bin/bench-overnight --worklist results/stale.csv│
│  • Or: Re-run failures: bin/bench --resume <run-id>         │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 2: Run Overnight (bin/bench-overnight)                 │
├──────────────────────────────────────────────────────────────┤
│ $ bin/bench-overnight --stale                 │
│                                                               │
│ Scans stale items, groups by model, runs in sequence        │
│ Results → results/<timestamp>/                              │
│                                                               │
│ Next steps (printed):                                        │
│  • Investigate failures: bin/debug --failures <run-id>      │
│  • Update leaderboard: bin/report --all --save              │
│  • Commit results                                            │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 3: Triage Failures (bin/debug)                         │
├──────────────────────────────────────────────────────────────┤
│ $ bin/debug --failures <run-id>                             │
│                                                               │
│ Classifies each failure:                                     │
│  • signature (mangled tool calls — fixable)                 │
│  • clean (real model failure — document)                    │
│  • no-transcript (can't diagnose)                           │
│                                                               │
│ Next steps (printed):                                        │
│  • Fix signatures: bin/patch qwen3-edit-shim                │
│  • Then re-run: bin/bench --resume <run-id>                │
│  • Document clean failures in docs/tools/                   │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 4: Validate Everything (bin/lint)                      │
├──────────────────────────────────────────────────────────────┤
│ $ bin/lint --all                                            │
│                                                               │
│ Checks: script issues, adapter issues, card issues          │
│                                                               │
│ Next steps (printed):                                        │
│  • Auto-fix: bin/lint --fix                                 │
│  • Manual fixes: see error report                           │
│  • Commit: git add . && git commit                          │
└──────────────────────────────────────────────────────────────┘
                            ↓
                     ✅ Overnight Complete
                    (Results ready, issues triaged)
```

---

## Workflow 4: Model Management

Check, update, delete, or clean up models across all runtimes.

```
┌──────────────────────────────────────────────────────────────┐
│ See What's Installed (bin/model status)                      │
├──────────────────────────────────────────────────────────────┤
│ $ bin/model status                                           │
│                                                               │
│ Shows models across LM Studio, Ollama, MLX, oMLX           │
│ Which are loaded in memory?                                 │
│                                                               │
│ Next steps (printed):                                        │
│  • Update: bin/model update <model-id>                      │
│  • Delete: bin/model remove <model-id>                      │
│  • Clean: bin/model cleanup                                 │
└──────────────────────────────────────────────────────────────┘
                            ↓
                    [Choose an action]
                    ↙  ↓  ↓  ↓
        ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐
        │UPDATE│  │DELETE│  │CLEAN │  │USE  │
        └───┬──┘  └───┬──┘  └───┬──┘  └──┬──┘
            │         │         │       │
            ↓         ↓         ↓       ↓
   ┌─────────────────────────────────────┐
   │ bin/model update <id>               │
   │ bin/model remove <id>               │
   │ bin/model cleanup                   │
   │ bin/bench --agent aider             │
   └─────────────────────────────────────┘
            │         │         │       │
            ↓         ↓         ↓       ↓
   Verify: bin/smoke --agent aider,hermes
   (All flows → verify)
```

---

## Workflow 5: Debug a Failure

Single-case debugging when `bin/bench` shows failures.

```
┌──────────────────────────────────────────────────────────────┐
│ Run Benchmarks (some fail)                                   │
├──────────────────────────────────────────────────────────────┤
│ $ bin/bench --agent aider --models qwen/...                │
│                                                               │
│ Output: [FAIL] 1/4 cases passed                            │
│                                                               │
│ Next steps (printed):                                        │
│  • bin/debug aider qwen3.5-9b js-01-slugify                │
│  • bin/debug --failures <run-id>                            │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Run One Case with Transcript                                 │
├──────────────────────────────────────────────────────────────┤
│ $ bin/debug aider qwen/qwen3.5-9b js-01-slugify           │
│                                                               │
│ Saves full transcript showing:                              │
│  • Model input/output                                       │
│  • Tool calls made                                          │
│  • Why it failed                                            │
│                                                               │
│ Next steps (printed):                                        │
│  • View: less <transcript-path>                             │
│  • Analyze calls: bin/debug --calls --latest                │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Inspect Tool Calls                                           │
├──────────────────────────────────────────────────────────────┤
│ $ bin/debug --calls --latest                                │
│                                                               │
│ Shows:                                                       │
│  • Sample tool calls from transcript                        │
│  • Warnings if mangled (invalid XML/JSON)                   │
│  • Classification: signature (fixable) vs clean (real)      │
│                                                               │
│ Next steps (printed):                                        │
│  • If signature: bin/patch qwen3-edit-shim                  │
│  • If clean: document in docs/tools/<tool>.md               │
│  • Re-run: bin/debug aider qwen3.5-9b js-01                │
└──────────────────────────────────────────────────────────────┘
```

---

## Workflow 6: Multi-Machine Tier Portability

Benchmark on 128 GB, share learnings with 32 GB machine (phase 3).

```
┌──────────────────────────────────────────────────────────────┐
│ MACHINE 1 (128 GB): Full Benchmarking                        │
├──────────────────────────────────────────────────────────────┤
│ $ bin/bench --agent aider,hermes,cline --trials 3          │
│ $ bin/report --all --save                                   │
│                                                               │
│ Output: LEADERBOARD.md (winners identified)                 │
│         results/<timestamp>/results.csv                     │
│                                                               │
│ Next steps (printed):                                        │
│  • Generate profile: bin/qualify --emit-profile <128gb>     │
│  • Share profile.json to other machines                     │
└──────────────────────────────────────────────────────────────┘
                            ↓
                    [Share profile.json]
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ MACHINE 2 (32 GB): Bootstrap from Profile                    │
├──────────────────────────────────────────────────────────────┤
│ $ bin/hwprofile                                             │
│ Detected: 32 GB RAM                                         │
│                                                               │
│ $ bin/bootstrap-machine --profile <profile.json>            │
│                                                               │
│ Output: Suggested config.sh + recommended models for 32 GB  │
│         BENCH_PARALLEL=2 (not 3)                            │
│         Smaller models recommended                          │
│                                                               │
│ Next steps (printed):                                        │
│  • Review: cat config.sh                                    │
│  • Apply: bin/bootstrap-machine --write                     │
│  • Install agents: bin/setup --agent aider                  │
│  • Smoke test: bin/smoke --agent aider                      │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ MACHINE 2: Verify & Run                                      │
├──────────────────────────────────────────────────────────────┤
│ $ bin/smoke --agent aider                                   │
│ $ bin/bench --agent aider --trials 1                        │
│                                                               │
│ Output: Confirms profile works on this tier                │
│                                                               │
│ Next steps (printed):                                        │
│  • You're done! Results match 128 GB tier expectations     │
│  • No need to re-benchmark; use Machine 1 learnings        │
└──────────────────────────────────────────────────────────────┘
```

---

## Command Reference Quick Look

| Task | Command |
|------|---------|
| Check what's installed | `bin/setup` or `bin/model status` |
| Verify configuration | `bin/doctor` |
| Test adapters work | `bin/smoke --agent aider,hermes` |
| Run full benchmark | `bin/bench --agent aider --trials 3` |
| See results | `bin/report --all` |
| Visualize | `bin/report --viz` |
| Debug one case | `bin/debug aider qwen3.5-9b js-01` |
| Triage failures | `bin/debug --failures <run-id>` |
| Find work to do | `bin/stale` |
| Run overnight | `bin/bench-overnight --stale` |
| Update a model | `bin/model update qwen/...` |
| Clean up models | `bin/model cleanup` |
| Lint everything | `bin/lint --all` |
| Fix issues | `bin/lint --fix` |

---

## The Next Steps Pattern

Every command follows the **Command Boundary Pattern**: after it completes, it prints "Next steps:" with 2-4 most likely follow-up commands, copy-paste ready.

Example:
```bash
$ bin/smoke --agent aider
...
✓ aider smoke-01-edit-file: PASS
✓ aider smoke-02-numbers: PASS

Next steps:
  1. Run full benchmarks:
     bin/bench --agent aider --trials 3
     
  2. See detailed results:
     bin/report --all
     
  3. Visualize:
     bin/report --viz
```

This means **no documentation hunting** — each command tells you what to do next.

See [CLI-DISCOVERY.md](CLI-DISCOVERY.md) for the pattern rationale.
