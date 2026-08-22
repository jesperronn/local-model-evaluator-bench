# Adapter & Model Evaluation Workflow

This document describes the complete workflow for managing adapters and models in the benchmark suite, from initial setup through ongoing maintenance.

## Overview

The benchmark supports multiple **adapters** (CLI code-generation tools like aider, cline, hermes) running against multiple **models** (LLMs) across multiple **runtimes** (LM Studio, Ollama, MLX).

Key files:
- **`compat.json`**: Tracks which adapter+model+runtime combinations work ("resolved") or are broken ("open")
- **`bin/smoke`**: Fast smoke test to verify each adapter can reach a model (also updates compat.json)
- **`bin/bench`**: Full benchmark suite; automatically skips broken adapters for efficiency
- **`adapters/*.sh`**: Individual adapter implementations
- **Model discovery**: no static list — `bin/bench` and friends query each runtime's live `/v1/models` endpoint (or `lms ls`/`ollama list`) for what's available

---

## Conventions

These policies apply across all adapters and benchmark runs:

- **No auto-approve flags.** Adapters must not pass `--yolo`, `--auto-approve`,
  or equivalent blanket-approval flags. Approval prompts are a safety signal —
  they reveal how much the model hesitates, which actions it thinks are risky,
  and whether its confidence matches task difficulty. Auto-approval hides that
  signal even though it makes runs "look cleaner." For headless/CI runs this
  means an adapter must either gate through something reviewable (e.g. hermes's
  `approvals.mode: smart` guardian — see [SETUP.md §3](SETUP.md#3-the-cli-adapters))
  or accept that some runs need human input. This is intentional: it preserves
  behavioral signal integrity.

- **Document adapter tool versions.** Every adapter should record the version
  of the underlying CLI/tool it was built and last verified against (e.g. in a
  header comment: `# caveman-code v1.2.3, npm`) and the date tested. Adapters
  break silently when their underlying tool updates — a version marker lets
  you spot an incompatibility at a glance instead of debugging a cryptic
  failure weeks later. When a test fails due to a version mismatch, update the
  header with the breaking version and a note on what would fix it.

- **Baseline for "first full bench result."** The canonical, comparable
  benchmark configuration is **LM Studio + `qwen/qwen3.6-30b-a3b`** (fall back
  to `qwen/qwen3.6-35b-a3b` if unavailable). Use this whenever running all
  adapters for the first time, establishing a new leaderboard/scoring
  baseline, or validating a new adapter against a known-good reference. You
  can deviate for model-specific investigations or quick single-adapter
  smoke tests — just label the deviation clearly (commit message, run
  metadata) so it isn't mistaken for the canonical baseline.

- **Build analysis into existing tools, not ad-hoc scripts.** Don't reach for
  a one-off `awk`/`grep` chain or a throwaway script to answer a recurring
  question. Add it as a flag/option on the relevant tool instead (e.g.
  `bin/report --speed`, `bin/report --all`) so it composes with existing
  filters, gets documented, and is version-tracked. Ad-hoc scripts are hard to
  find, can't be composed with other filters, and never get committed.

- **Inspect results via the result commands, not raw logs.** To check a run's
  outcome use `bin/bench-status` (`--cases` for the full per-case
  PASS/WARN/FAIL table, `--run <id>`, `--history N`, `--compare`, `--watch`),
  `bin/report` (leaderboards + `--agent`/`--model`/`--speed`/`--all` filters),
  and `bin/investigate --failures <run-id>` (triage). Don't grep the raw
  `results/*/…` output or a background task log — if a command lacks the view
  you need, add a flag to it (this is how `bench-status --cases` was added).

- **Commit directly on `main`.** Make commits on `main`; don't create
  feature/topic branches for changes in this repo. Keep separate commits when
  asked, but keep them on `main`. (Pushing/PRs remain a separate explicit
  action — see AGENTS.md.)

---

## 1. Adding a New Adapter

### Step 1a: Create the adapter script

Create a new file `adapters/TOOL_NAME.sh` (or `adapters/TOOL_NAME-RUNTIME.sh` for runtime-specific implementations):

```bash
#!/usr/bin/env bash
# adapters/my-adapter.sh — integration for MyTool CLI
# Receives task on stdin, exits 0 on success.

set -uo pipefail
[ -n "${MODEL_ID:-}" ] || { echo "MODEL_ID not set" >&2; exit 1; }

# Your adapter implementation here
# Tool should:
#   1. Read task.md from stdin
#   2. Interact with the model at $LMS_BASE_URL (or configured runtime endpoint)
#   3. Save deliverables to current directory
#   4. Exit 0 on completion, exit 1 on failure

my_tool \
  --model "$MODEL_ID" \
  --api-key "$LMS_API_KEY" \
  --api-base "$LMS_BASE_URL"
```

See [`adapters/`](../adapters/) for examples.

### Step 1b: Update config.sh

Add the adapter name to [`config.sh:DEFAULT_ADAPTERS`](../config.sh):

```bash
DEFAULT_ADAPTERS="${DEFAULT_ADAPTERS:-aider,cline,my-adapter,...}"
```

### Step 1c: Smoke test the adapter (all models)

```bash
bin/smoke --adapter my-adapter
```

This runs the adapter against the default smoke model on the default runtime. Results are logged to:
- `results/TIMESTAMP/results.csv` — summary results
- `results/TIMESTAMP/sandbox/my-adapter/.../.bench.log` — detailed per-case logs

### Step 1d: Check compat.json

After the smoke test, `compat.json` is automatically updated with the results:

```bash
jq '.["my-adapter:MODEL:RUNTIME"]' compat.json
```

Output will be one of:
- **Status: "resolved"** — all tests passed, adapter works with this model+runtime
- **Status: "open"** — tests failed, adapter is broken with this model+runtime
  - Includes `symptom`: the first error from the logs
  - Includes `first_seen`: date/run_id when the incompatibility was discovered

---

## 2. Adding a New Model

### Step 2a: Download it

Download the model on whichever runtime(s) it should be available for (`lms
get <id>`, `ollama pull <id>`, drop it in the MLX/oMLX/MTPLX model dir, etc.).
There's no file to register it in — `bin/bench` (and `bin/stale`,
`bin/scout`, ...) discover what's available by querying each runtime's live
`/v1/models` endpoint, so a downloaded model is in scope immediately. Run
`bin/bench --runtime <rt> --models <id>` to test one specific model, or omit
`--models` to sweep everything that runtime currently has installed/loaded.

### Step 2b: (Optional) Add a model alias

If the same logical model has different IDs across runtimes, add it to `models-aliases.conf`:

```
qwen35-coder	qwen/qwen3.6-35b-a3b	qwen3.6-35b-a3b	qwen3.6-35b
```

Format: `ALIAS<TAB>LMS_ID<TAB>MLX_ID<TAB>OLLAMA_ID` (use `-` for unavailable on a runtime)

Then you can refer to the alias in commands:
```bash
bin/smoke --model qwen35-coder  # resolved to runtime-specific ID
```

### Step 2c: Smoke test the model (all adapters)

```bash
bin/smoke --model qwen/qwen3.6-35b-a3b
```

This tests every adapter in `DEFAULT_ADAPTERS` against the new model. The results populate compat.json with entries like:

```json
{
  "aider:qwen/qwen3.6-35b-a3b:lms": { "status": "resolved", ... },
  "cline:qwen/qwen3.6-35b-a3b:lms": { "status": "open", "symptom": "..." }
}
```

---

## 3. Running Smoke Tests

The smoke test is a **quick compatibility check** — runs two lightweight cases per adapter to verify wiring, not accuracy.

### 3a: Smoke test all adapters (default model + runtime)

```bash
bin/smoke
```

- Model: `$SMOKE_MODEL` (from config.sh; default: google/gemma-4-e2b)
- Runtime: lms (default)
- Cases: smoke-00-hello, smoke-01-edit-file, smoke-02-numbers

### 3b: Smoke test a single adapter

```bash
bin/smoke --adapter cline
```

### 3c: Smoke test with a different model

```bash
bin/smoke --model meta-llama/llama-3.1-70b
```

### 3d: Smoke test with a different runtime

```bash
bin/smoke --runtime ollama --model neural-chat
```

### 3e: Dry-run (no actual execution)

```bash
bin/smoke --dry-run
# Prints the plan (runtime, model, adapters, files) without running
```

### 3f: Skip compat.json updates

```bash
bin/smoke --skip-compat-update
# Run tests but don't record results in compat.json
```

Use this when testing adapter changes that you don't want to commit to compatibility tracking yet.

---

## 4. Understanding Smoke Test Results

### 4a: Live output

```
[PASS] aider            google/gemma-4-e2b    smoke-00-hello  —  PASS    (12s)
[WARN] cline            google/gemma-4-e2b    smoke-01-edit-file  —  PARTIAL — 0/3 (5s)
       | RESULT: pass=0 total=3 reason=model_refusal
       | log: results/20240115-120000/sandbox/cline/google__gemma-4-e2b/smoke-01-edit-file/.bench.log
[FAIL] copilot          google/gemma-4-e2b    smoke-02-numbers  —  FAIL    — error(127)
       | copilot: command not found
       | log: results/20240115-120000/sandbox/copilot/.../.bench.log
```

Legend:
- **PASS** — all checks passed
- **PARTIAL** — reached model but task incomplete
- **FAIL** — couldn't reach the model (wiring problem, missing tool, etc.)

### 4b: compat.json updates

After each smoke test, incompatibilities are logged:

```bash
jq . compat.json | head -50
```

Example:
```json
{
  "copilot:google/gemma-4-e2b:lms": {
    "adapter": "copilot",
    "model": "google/gemma-4-e2b",
    "runtime": "lms",
    "status": "open",
    "first_seen": "2024-01-15",
    "first_run_id": "20240115-120000",
    "agent_version": "copilot-cli/1.0.3",
    "symptom": "copilot: command not found",
    "last_seen": "2024-01-20",
    "last_run_id": "20240120-153000"
  },
  "cline:google/gemma-4-e2b:lms": {
    "adapter": "cline",
    "model": "google/gemma-4-e2b",
    "runtime": "lms",
    "status": "resolved",
    "resolved_date": "2024-01-18",
    "resolved_run_id": "20240118-100000",
    "resolved_agent_version": "cline/1.2.0"
  }
}
```

---

## 5. Managing Broken/Incompatible Adapters

### 5a: Identifying broken adapters

Run a smoke test and check the summary:

```bash
bin/smoke --model qwen/qwen3.6-35b-a3b 2>&1 | grep FAIL
```

Or query compat.json:

```bash
jq '.[] | select(.status == "open")' compat.json
```

### 5b: How bench uses compat.json

When you run `bin/bench`, it **automatically filters out adapters marked as broken** for the current model+runtime:

```bash
bin/bench --model qwen/qwen3.6-35b-a3b
# Skips any adapters with status="open" for qwen/qwen3.6-35b-a3b:lms
```

Output:
```
[WARN] skipping 3 adapter(s) with known incompatibilities for qwen/qwen3.6-35b-a3b on lms:
      copilot: copilot: command not found
      hermes: failed to connect to control plane
      interpreter: connection timeout
```

This prevents wasting hours on adapters that won't work.

### 5c: Manually mark an adapter as abandoned

If an adapter is broken and you don't intend to fix it, you can set its status explicitly:

```bash
jq '.["copilot:MODEL:RUNTIME"].status = "abandoned"' compat.json > compat.json.tmp
mv compat.json.tmp compat.json
```

Then `bin/bench` will also skip it (only "resolved" status runs).

### 5d: Remove broken entries (cleanup)

After pruning non-viable adapters from your workflow, clean up old compat entries:

```bash
jq 'map_values(select(.status != "open"))' compat.json > compat.json.tmp
mv compat.json.tmp compat.json
```

---

## 6. Re-evaluating Abandoned/Fixed Adapters

### 6a: After fixing an adapter

Suppose you fixed `copilot` by installing the missing tool or updating its version. Re-evaluate:

```bash
bin/smoke --adapter copilot --model google/gemma-4-e2b
```

If tests now pass, compat.json is updated:
```json
{
  "copilot:google/gemma-4-e2b:lms": {
    "status": "resolved",
    "resolved_date": "2024-01-25",
    "resolved_run_id": "20240125-140000",
    "resolved_agent_version": "copilot-cli/2.0.0"
  }
}
```

### 6b: After upgrading a tool version

If a new adapter version shipped, run a fresh smoke test to check for regressions:

```bash
bin/smoke --adapter copilot  # all models
```

If a previously resolved adapter now fails, compat.json marks it as regressed:
```json
{
  "copilot:google/gemma-4-e2b:lms": {
    "status": "open",
    "regressed_date": "2024-01-26",
    "regressed_run_id": "20240126-100000",
    "symptom": "breaking API change in copilot-cli v2.1"
  }
}
```

### 6c: Full re-evaluation sweep

After a major change (new runtime setup, updated LM Studio version, etc.), re-evaluate everything:

```bash
bin/smoke  # defaults to all adapters, default model, lms
bin/smoke --runtime ollama --model neural-chat  # new runtime
# ... repeat for other model+runtime combos
```

Results accumulate in compat.json, building a complete compatibility matrix.

---

## Full Workflow Example

### Scenario: Add Hermes adapter, then run full benchmarks on two models

```bash
# 1. Create adapter
cat > adapters/hermes.sh << 'EOF'
#!/usr/bin/env bash
...
EOF
chmod +x adapters/hermes.sh

# 2. Add to default list
sed -i 's/DEFAULT_ADAPTERS="/DEFAULT_ADAPTERS="hermes,/' config.sh

# 3. Quick smoke test
bin/smoke --adapter hermes  # → compat.json now has hermes entries

# 4. Download a new model (discovered live — no file to register it in)
lms get meta-llama/llama-3.1-70b

# 5. Smoke test new model with all adapters (to populate compat.json)
bin/smoke --model meta-llama/llama-3.1-70b

# 6. Run full benchmarks on both models
#    (automatically skips broken adapters)
bin/bench --model google/gemma-4-e2b,meta-llama/llama-3.1-70b \
          --timeout 600 --trials 3

# 7. Check results
cat results/TIMESTAMP/results.csv
jq '.[] | select(.status != "resolved")' compat.json  # any new issues?
```

---

## Maintenance Commands

```bash
# List all incompatibilities
jq '.[] | select(.status == "open") | "\(.adapter):\(.model):\(.runtime)"' compat.json

# Count resolved vs open
jq '[.[] | .status] | group_by(.) | map({status: .[0], count: length})' compat.json

# Show adapters to re-evaluate (regressed recently)
jq '.[] | select(.status == "open" and (.regressed_date > "2024-01-20")) | "\(.adapter) — \(.symptom)"' compat.json

# Archive old entries (older than 30 days)
jq 'map_values(select(.last_seen > "2024-01-15" or .status == "resolved"))' compat.json > compat.json.tmp
mv compat.json.tmp compat.json
```

---

## See Also

- [`AGENT-SELECTION.md`](./AGENT-SELECTION.md) — performance & capability guidance per adapter
- [`TESTING-STRATEGY.md`](./TESTING-STRATEGY.md) — case difficulty tiers, how to interpret results
- [`config.sh`](../config.sh) — runtime endpoints, model defaults, adapter list
- [`bin/doctor`](../bin/doctor) — diagnose adapter/runtime setup issues
- [Agent Sessions](https://jazzyalex.github.io/agent-sessions/) — browser-based
  viewer for agent session transcripts. Useful for post-mortem debugging of a
  surprising eval result (wrong answer, unexpected refusal, tool misuse):
  load the session JSON/JSONL and browse the full turn-by-turn conversation.

## Run versioning

Every `bin/bench` run captures full provenance in `run.json`, not just results:

- **Run date & time** (from the run id, `YYYYMMDD-HHMMSS`)
- **Runtime version** — LM Studio / Ollama / MLX version + how it was detected
- **Adapter versions** — each tool's version (aider, cline, mini-swe-agent,
  etc.), resolved via pip/npm/pnpm
- **Bench config** — parallel slots, context window, timeouts, trial count
- **System snapshot** — CPU, RAM, swap at run time (for reproducibility)

This is implemented in [`lib/versions.sh`](../lib/versions.sh)
(`get_version_info <adapter>`, `get_runtime_version <runtime>`), called from
`bin/bench`'s `write_run_meta()`. Version extraction returns `"unknown"` if a
tool isn't installed globally. System info collection is macOS-specific.

Example `run.json` shape:

```json
{
  "run_id": "20260627-102030",
  "run_date": "2026-06-27",
  "run_time": "10:20:30",
  "runtime": "lms",
  "versions": {
    "runtime": { "name": "lms", "version": "CLI commit: efce996", "source": "lms" },
    "agents": {
      "mini-swe-agent": { "version": "2.4.2", "source": "pip" },
      "aider": { "version": "...", "source": "pip" }
    }
  },
  "bench": {...},
  "axes": {...},
  "system": {...}
}
```
