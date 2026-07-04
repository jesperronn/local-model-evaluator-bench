# Onboarding: From Fresh Clone to First Benchmark

**Start here.** This guide takes you from `git clone` through running your first benchmarks on a new machine.

The workflow is **4 phases**, each mapped to one command. Pick your path below:

---

## Quick Path (Copy-Paste)

If you know what you're doing, here are the 5 commands:

```bash
bin/hwprofile                        # Phase 1: Detect your machine specs
bin/bootstrap-machine --write         # Phase 2: Apply tier-specific config
bin/smoke                            # Phase 3: Verify tools work
bin/bench --agent hermes --trials 3  # Phase 4: Run benchmarks
bin/report --all --save && bin/viz   # Phase 4 (cont): Merge & visualize
```

Results go to `results/index.html` (interactive dashboard).

---

## Guided Path (Step-by-Step Walkthrough)

Read this if you want to understand what each phase does and why.

### Phase 1: Detect Your Hardware

```bash
$ bin/hwprofile
```

**What it does:**
- Detects your RAM (the main constraint for local models)
- Finds the nearest benchmarked tier (32 GB / 64 GB / 128 GB / etc.)
- Suggests models and settings optimized for your machine

**Why it matters:**
- Running a 70B model on a 32 GB machine = thrashing; benchmarks will be meaningless
- This step prevents you from downloading the wrong model size

**When to intervene:**
- If the detected tier seems wrong, override: `bin/hwprofile --tier 64`
- If you want to manually tune, note the tier and skip to Phase 2

**Next step:** Phase 2 (Setup)

---

### Phase 2: Apply Tier-Specific Configuration

```bash
$ bin/bootstrap-machine              # Preview (dry-run)
$ bin/bootstrap-machine --write       # Apply the changes
```

**What it does:**
- Reads your detected hardware tier (from Phase 1)
- Updates `models.txt` with recommended model sizes for that tier
- Configures `config.sh` with safe parallelism & context windows for your RAM
- Shows what *would* change first (dry-run mode)

**Why it matters:**
- Different RAM tiers need different models (can't fit 70B on 32 GB)
- Parallelism settings prevent OOM crashes (a 128 GB machine can run 4 agents; 32 GB can run 1)
- Context windows matter for multi-file edits; too high wastes RAM, too low hurts accuracy

**When to intervene:**
- Run the preview first: `bin/bootstrap-machine` (shows proposed changes)
- Review the changes before `--write`
- If you want to manually tune, edit `config.sh` and `models.txt` by hand instead

**What happens:**
```
Detected: 64 GB RAM

Proposed changes:
  models.txt    → qwen/qwen3.6-27b, qwen/qwen3.6-35b-a3b (2 models)
  config.sh     → BENCH_PARALLEL=2, BENCH_CONTEXT=65536

Apply? bin/bootstrap-machine --write
```

**After applying:**
- Models are *not* downloaded yet (Phase 3 handles that)
- Your `config.sh` now reflects your machine's limits

**Next step:** Phase 3 (Verify)

---

### Phase 3: Verify All Tools Work

```bash
$ bin/smoke
```

**What it does:**
- Checks that LM Studio is running (or Ollama / MLX if you configured those)
- Tries to reach the server at your configured endpoint (default: `http://localhost:1234/v1`)
- Runs a trivial test case (`cases/smoke-00-hello`) through every adapter (aider, hermes, opencode, cline, continue, etc.)
- Reports which adapters work and which fail

**Why it matters:**
- Catches common mistakes early:
  - "Did I start LM Studio?"
  - "Are the models actually downloaded?"
  - "Is the API endpoint correct?"
- Saves time: why start a 2-hour benchmark if 50% of tools won't work?

**When to intervene:**
- If you see red ✗ marks, check:
  1. Is LM Studio running? `lms server start` (or your runtime's equivalent)
  2. Do you have a model loaded? `lms ls` and `lms load <model-id>`
  3. Is the endpoint correct in `config.sh`? (`LMS_BASE_URL`, etc.)
  4. Do you have all CLI tools installed? Check `bin/doctor --cli` for which ones are missing
- If a specific adapter fails:
  - Check `results/<latest>/sandbox/.bench.log` for the actual error
  - Read `docs/tools/<adapter-name>.md` for tool-specific setup

**Output example:**
```
Smoke test on 3 cases, all adapters, lms runtime:

✓ aider (3/3 passed in 12s)
✓ hermes (3/3 passed in 14s)
✓ opencode (3/3 passed in 11s)
⊘ cline (SKIPPED — CLI not installed)
✗ caveman (1/3 passed; see results/20260704-abc/sandbox/ for details)

Next steps:
  Run full benchmark: bin/bench --agent aider,hermes,opencode
  Debug caveman: bin/debug --agent caveman
```

**Next step:** Phase 4 (Benchmark)

---

### Phase 4: Run Benchmarks & Visualize

```bash
$ bin/bench --agent hermes --trials 3
```

**What it does:**
- Runs every test case through your chosen adapter(s) and all models in `models.txt`
- Repeats each 3 times (records median time + accuracy)
- Grades the model's code edits against hidden test suites
- Saves results to `results/<timestamp>/results.csv` with detailed logs

**Why it matters:**
- This is the main experiment: which model gets the best accuracy + speed?
- Trials (3 runs) smooth out variance; run-to-run numbers can vary 4/4 → 2/4

**Common options:**
```bash
bin/bench --agent hermes                    # All cases, all models
bin/bench --agent hermes --models qwen/*    # Filter models by pattern
bin/bench --agent hermes --cases js-*       # Filter cases by pattern
bin/bench --agent hermes,aider --trials 5   # Multiple adapters, 5 trials
bin/bench --agent hermes -i                 # Interactive: pick via fzf
bin/bench --list                            # Show what *would* run (dry-run)
```

**When to intervene:**
- Benchmark takes a long time. First runs:
  - Start with one adapter: `bin/bench --agent hermes --cases smoke-* --trials 1` (quick validation)
  - Then expand: `bin/bench --agent hermes --trials 3` (full run, ~30 min–2 hours depending on models)
- If a model is too slow, you'll see it timeout (300s hard limit). This is intentional—it's disqualified by design.
- Ctrl+C to cancel mid-run; results so far are saved.

**After benchmarking, merge and visualize:**

```bash
$ bin/report --all --save           # Merge all run results into leaderboard
$ bin/viz                           # Build interactive dashboard
$ open results/index.html           # View in browser
```

**Output:**
```
results/index.html                  # Interactive dashboard
results/20260704-abc/results.csv    # Raw results table
results/20260704-abc/sandbox/       # Per-run logs & transcripts
```

---

## Reference: What Each File Does

| File | Purpose |
|------|---------|
| `config.sh` | Global settings: endpoint URL, parallelism, context window, timeouts. Edited by Phase 2. |
| `models.txt` | Which models to test. Edited by Phase 2. |
| `lib/common.sh` | Shared utilities (logging, API calls, path handling). |
| `adapters/<name>.sh` | How each CLI is driven non-interactively. 40+ adapters supported. |
| `cases/<id>/` | Test cases: prompt, starter code, hidden grader. 12 built-in cases. |
| `results/` | Benchmark output. Check here for detailed logs if something fails. |

---

## Troubleshooting by Phase

### Phase 1: hwprofile fails
```bash
$ bin/hwprofile
[ERROR] failed to detect RAM
```
- macOS / Linux should auto-detect. If it fails, manually specify: `bin/bootstrap-machine --tier 64`

### Phase 2: bootstrap-machine shows no changes
```bash
$ bin/bootstrap-machine
Proposed changes: (none)
```
- Likely your current `models.txt` already matches the tier. This is fine. Proceed to Phase 3.

### Phase 3: smoke test fails on all adapters
```bash
✗ aider [ConnectionError: failed to reach http://localhost:1234/v1]
```
- Is LM Studio running? Start it: `lms server start`
- Is a model loaded? Check: `lms ps` (should list something). If empty, load one: `lms load <id>`
- Is `config.sh` pointing to the right endpoint? Check: `grep LMS_BASE_URL config.sh`

### Phase 3: smoke test passes but one adapter fails
```bash
✗ caveman (timeout after 30s)
```
- This adapter has an issue. You can skip it in Phase 4: `bin/bench --agent aider,hermes` (skip caveman)
- Or debug it: see `docs/tools/caveman.md` for known issues and workarounds

### Phase 4: benchmark runs but all results are 0/X (failing)
```
aider,qwen/qwen3.5-9b,js-01-slugify-bug,0,45s
aider,qwen/qwen3.5-9b,js-02-debounce,0,48s
```
- The model may not be capable enough, or the prompt/context is too small
- Check logs: `cat results/<timestamp>/sandbox/aider-qwen*.log`
- Try a larger model: `bin/lms_update` (re-downloads latest versions)
- Or try a different adapter: `bin/bench --agent hermes` (different tool might extract better code from the model)

### Phase 4: benchmark timeout
```
[TIMEOUT] hermes × qwen/qwen3.5-70b took >300s
```
- This model is too slow for real-world use. It's disqualified by design.
- Choose a smaller model: `bin/prune` (list available), or `lms get qwen/qwen3.6-27b`

---

## Next: Understanding the Results

Once Phase 4 completes, you have data. Here's how to interpret it:

**Open `results/index.html`** — interactive dashboard showing:
- **Leaderboard**: sorted by accuracy + speed (co-equal)
- **Per-adapter breakdown**: which tool extracts the best code from each model
- **Speed vs accuracy tradeoff**: does a faster model lose accuracy?

**Read `LEADERBOARD.md`** — human-readable summary:
- Why certain models rank higher
- Known incompatibilities (tool × model combinations that don't work)
- Recommendations by hardware tier

**Dive deeper:**
- Check `docs/models/<model-name>.md` for tuning guides
- Check `docs/tools/<tool-name>.md` for tool-specific findings
- See [SCORING.md](SCORING.md) to understand how accuracy/speed are computed

---

## Further Reading

- [CLI-DISCOVERY.md](CLI-DISCOVERY.md) — how every command shows "Next steps"
- [SETUP.md](SETUP.md) — detailed LM Studio / Ollama / MLX setup
- [WORKFLOW.md](WORKFLOW.md) — how to add new models, adapters, or test cases
- [PURPOSE.md](PURPOSE.md) — what this project measures and why
- [HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md) — machine sizing by RAM tier

---

## The Four Phases at a Glance

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Detect (bin/hwprofile)                            │
│ → Measures your RAM, finds benchmarked tier               │
└────────────┬────────────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────────────┐
│ Phase 2: Setup (bin/bootstrap-machine --write)             │
│ → Configures models.txt & config.sh for your tier         │
└────────────┬────────────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────────────┐
│ Phase 3: Verify (bin/smoke)                                │
│ → Smoke-tests all adapters; catches setup mistakes        │
└────────────┬────────────────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────────────────┐
│ Phase 4: Benchmark (bin/bench + bin/report + bin/viz)      │
│ → Runs the full matrix, grades, visualizes                │
└─────────────────────────────────────────────────────────────┘
```

---

**Ready? Start with Phase 1:**

```bash
bin/hwprofile
```

Each command will tell you what to do next.
