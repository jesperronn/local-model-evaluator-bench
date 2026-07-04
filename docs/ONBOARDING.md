# Onboarding: Two Paths

Pick your path based on what you want:

- **Path A: Quick Setup** — "I want a working local agent (1-2 to compare)"
  - Time: ~20 min
  - Scope: 1-2 agents + 1 model + your platform
  - Goal: Integrate into IDE/CLI and start using it
  
- **Path B: Full Benchmarking** — "I want to measure all agents × all models"
  - Time: hours
  - Scope: all adapters × all models × all test cases
  - Goal: Determine which combo is best for your machine

---

# Path A: Quick Setup (Get a Working Agent)

**Goal:** Download a model, configure 1-2 agents, verify they work, integrate into your IDE.

## Step 1: Check Prerequisites with `bin/doctor`

```bash
$ bin/doctor
```

This scans your environment and reports what's installed and what's missing. Output will look like:

```
ℹ LM Studio server: http://localhost:1234/v1
✗ not reachable. Start it with: lms server start

ℹ Model management CLIs:
✓ hf → /opt/homebrew/bin/hf

ℹ Coding CLIs (adapters):
✗ aider not on PATH
✗ cline not on PATH (VS Code extension, install via GUI)
✓ hermes → /opt/homebrew/bin/hermes

ℹ Models under test (models.txt):
    qwen/qwen3.6-27b
    llama/llama-3.1-8b-instruct

ℹ Test cases:
    smoke-00-hello [bash]
    js-01-slugify-bug [javascript]
    ...
```

**What to do next:** Fix each ✗ (red cross) before moving on.

---

## Step 2: Start Your Runtime

Choose **one** runtime (LM Studio, Ollama, or MLX) and start it:

### Option A: LM Studio (macOS / Linux / Windows)

```bash
lms server start
```

Verify it's running:
```bash
lms ps                    # Shows loaded models (should be empty)
curl http://localhost:1234/v1/models  # Should return JSON
```

### Option B: Ollama (macOS / Linux)

```bash
brew install ollama       # If not installed
ollama serve              # Start the server (runs on :11434)
```

### Option C: MLX (Apple Silicon only)

```bash
pip install mlx-lm
mlx_lm.server --host 0.0.0.0 --port 8080
```

(Requires Python setup; see [docs/runtimes/mlx.md](runtimes/mlx.md) for details.)

**After starting:** Verify it's reachable by running `bin/doctor` again — should show "✓ reachable".

---

## Step 3: Download a Model

Based on your machine's RAM:

### 32 GB or less
Pick a small model (7B–13B parameters):
```bash
lms get mistralai/mistral-7b-instruct-v0.3
lms load mistralai/mistral-7b-instruct-v0.3 --context-length 8192
```

### 64 GB
Pick a medium model (27B–35B):
```bash
lms get qwen/qwen3.6-27b
lms load qwen/qwen3.6-27b --context-length 65536
```

### 128 GB+
Pick a larger model (70B):
```bash
lms get qwen/qwen3.6-35b-a3b
lms load qwen/qwen3.6-35b-a3b --context-length 65536
```

**Verify the model is loaded:**
```bash
lms ps                 # Should list your loaded model
curl http://localhost:1234/v1/models  # Should show it
```

> **Note on context windows:** Higher context (65536) helps with multi-file edits but costs RAM. On 32 GB, use 8192–16384. On 64 GB+, use 65536.

---

## Step 4: Pick 1-2 Agents to Try

Choose one or two agents from the list below. Pick based on how you'll use it:

| Agent | Best for | Install |
|-------|----------|---------|
| **aider** | CLI tool in terminal | `brew install aider` or `pip install aider` |
| **hermes** | Agentic CLI (more autonomous) | `brew install hermes` or `pip install hermes-ai` |
| **cline** | VS Code extension | Install via VS Code extension marketplace |
| **continue** | VS Code extension | Install via VS Code extension marketplace |
| **caveman** | Simple, batteries-included | `pip install caveman-code` |
| **opencode** | Node.js-based | `npm install -g opencode` |

**Install 1-2 of these.** Example (aider + cline):

```bash
brew install aider    # Or: pip install aider

# For cline: open VS Code → Extensions → search "Cline" → Install
# Then configure: VS Code Settings → search "cline" → set model to match your LM Studio model
```

After installing, run `bin/doctor` again to verify they're on PATH (or installed as extensions).

---

## Step 5: Configure Your Agent(s) to Reach the Model

Each agent needs to know where your LM Studio/Ollama/MLX server is and which model to use.

### For CLI agents (aider, hermes, caveman, opencode):

**aider:**
```bash
aider --openai-api-base http://localhost:1234/v1 \
      --model openai/qwen/qwen3.6-27b \
      --no-auto-commits
```

Or add to `~/.aider.conf.yaml`:
```yaml
openai-api-base: http://localhost:1234/v1
model: openai/qwen/qwen3.6-27b
no-auto-commits: true
```

**hermes:**
```bash
# Edit ~/.hermes/config.yaml
# Under 'models:' add:
  - id: qwen3.6-27b
    provider: lmstudio
    model: qwen/qwen3.6-27b
# Then run:
hermes -m qwen3.6-27b
```

**caveman:**
Edit `~/.pi/agent/models.json` to add your model, then:
```bash
caveman --provider lmstudio --model qwen/qwen3.6-27b
```

### For IDE extensions (cline, continue):

Open VS Code settings (Cmd+, or Ctrl+,):

**Cline:**
- Search "cline"
- Set "API Base URL" → `http://localhost:1234/v1`
- Set "Model" → `qwen/qwen3.6-27b` (must match your loaded model)

**Continue:**
- Search "continue"
- Set "Model" → LM Studio
- Set "API Base URL" → `http://localhost:1234/v1`

---

## Step 6: Quick Verify — Test Your Setup

Run a smoke test on your chosen agent(s):

```bash
bin/smoke --agents aider,hermes
```

(Or whichever agents you installed.)

This runs a trivial test case (`smoke-00-hello`) through each agent to confirm:
- ✅ The agent can reach the model
- ✅ The agent can make edits
- ✅ The edits are correct

**Example output:**
```
✓ aider: PASS (12s)
✓ hermes: PASS (14s)

Next steps:
  Use your agent in the IDE or CLI:
    aider <file>
    cline (in VS Code)
    hermes --model qwen3.6-27b
```

**If a test fails:**
- Check the logs: `cat results/<timestamp>/sandbox/aider.bench.log`
- Verify the model is still loaded: `lms ps`
- Check agent config (see Step 5)

---

## Step 7: You're Done — Use It!

Now integrate into your workflow:

**For aider:**
```bash
cd your-project
aider src/file.js  # Start an interactive session
```

**For hermes:**
```bash
hermes -m qwen3.6-27b your-project/
```

**For cline (VS Code):**
- Open a file in VS Code
- Cmd+K (or Ctrl+K) to open Cline
- Ask it to edit code

**For continue (VS Code):**
- Same as Cline

---

## Troubleshooting Path A

### "LM Studio not reachable"
- Is the server running? `lms server start`
- Is `config.sh` pointing to the right URL? Check: `grep LMS_BASE_URL config.sh`
- On different machine / custom port? Update `config.sh:LMS_BASE_URL`

### "Agent not on PATH"
After installing (e.g., `brew install aider`), verify:
```bash
which aider  # Should show the path
aider --version  # Should work
```

If not, restart your shell or reinstall.

### "Model not loading"
```bash
lms ls                    # List available models
lms load <model-id>       # Load it
lms ps                    # Verify it's loaded
```

### "Smoke test: agent timeout"
- Model is too slow. Try a smaller one: `lms get mistralai/mistral-7b-instruct-v0.3`
- Or your machine doesn't have enough RAM. Check with `bin/hwprofile`

### "Smoke test: agent produces wrong output"
- Model isn't good at code generation. Try a different one (see [docs/REPORT-2026-06-30.md](../REPORT-2026-06-30.md) for ranked models)
- Context window too small. Increase in Step 3: `lms load <id> --context-length 16384`

---

# Path B: Full Benchmarking (Measure All Combos)

For when you want to **rigorously compare all agents × all models** on your machine.

## Phase 1: Detect Your Hardware

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

## Phase 2: Apply Tier-Specific Configuration

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

## Phase 3: Verify All Tools Work

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

## Phase 4: Run Benchmarks & Visualize

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

## Understanding the Results

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
