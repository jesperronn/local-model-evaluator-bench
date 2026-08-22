# CLI Discovery: The Command Boundary Pattern

When a user finishes running a command, they should know what to do next **without reading documentation**. This is the **Command Boundary Pattern** — every `bin/*` tool should show "Next steps:" at its natural stopping points.

## Why This Matters

Users follow workflows like:
```
bin/hwprofile → bin/bootstrap-machine → bin/smoke → bin/bench
```

If each command is silent about what's next, users get stuck. Example:

```bash
$ bin/bootstrap-machine --write
✓ Applied config changes
# Then what? User has to read docs or guess.
```

vs.

```bash
$ bin/bootstrap-machine --write
✓ Applied config changes to config.sh

Next steps:
  1. Download the recommended models for your tier:
     lms get qwen/qwen3.6-27b
  2. Verify the config: bin/smoke --runtime lms
  3. Start benchmarking: bin/bench --agent aider
```

## The Pattern

Every `bin/*` tool has three phases:

### 1. Dry-run / Preview Mode
Show what *would* happen + next steps, so the user can learn the flow before mutating state.

```bash
$ bin/bootstrap-machine
✓ Detected: 64 GB RAM

Proposed changes:
  - config.sh:  BENCH_PARALLEL=2 (max safe concurrency)
  - Recommended models for this tier: qwen/qwen3.6-27b, ...

Next steps:
  1. Review above and run with --write if happy
  2. Then: bin/smoke to verify all adapters work
```

### 2. State-mutation Mode (--write, --yes, etc)
Apply changes, report what was done, **then show next steps**.

```bash
$ bin/bootstrap-machine --write
✓ Updated config.sh (BENCH_PARALLEL=2)
✓ Recommended models for 64 GB tier printed above — download them, no file to update

Next steps:
  Download the recommended models: lms get qwen/qwen3.6-27b
  Verify adapters: bin/smoke --runtime lms
  Start benchmarking: bin/bench --agent aider
```

### 3. Error States
When something fails, show **what went wrong AND how to fix it**.

```bash
$ bin/bench --agent x --models llama-3.1-8b
[FAIL] unknown adapter: x

Available adapters (lms):
  aider         - code editor CLI
  cline         - VS Code extension
  hermes        - agentic IDE
  [more...]

Examples:
  bin/bench --agent aider --models llama-3.1-8b
  bin/bench --agent hermes --interactive
  bin/bench --help
```

## Implementation Guide

### Use bin/lib/help.sh Functions

```bash
# At the end of your script:
help_section "NEXT STEPS"
help_line "  1. Download missing models: lms get qwen/qwen3.5-9b"
help_line "  2. Verify: bin/smoke --runtime lms"
help_line "  3. Benchmark: bin/bench --agent aider"
```

### Or Add help_next_steps() Helper

```bash
# In lib/help.sh:
help_next_steps() {
  local step="$1" cmd="$2"
  printf '  %s\n' "${C_DIM}${step}: ${C_GRN}${cmd}${C_RST}"
}

# Usage:
help_section "NEXT STEPS"
help_next_steps "1. Download models" "lms get qwen/qwen3.6-27b"
help_next_steps "2. Verify" "bin/smoke --runtime lms"
help_next_steps "3. Benchmark" "bin/bench --agent aider"
```

### For Missing/Invalid Input

Always show the list of valid choices:

```bash
# When user passes --agent nonexistent:
if ! [ -f "$ADAPTERS_DIR/$adapter.sh" ]; then
  echo "${C_RED}✗${C_RST} adapter not found: $adapter" >&2
  echo ""
  echo "Available adapters for $RUNTIME:"
  ls "$ADAPTERS_DIR"/*.sh | xargs -I{} basename {} .sh \
    | sed "s/-${RUNTIME}$//" | sort -u | sed 's/^/  /'
  echo ""
  echo "Examples:"
  echo "  bin/bench --agent aider --models qwen/qwen3.5-9b"
  echo "  bin/bench --agent hermes --interactive"
  exit 1
fi
```

## Examples from the Codebase

### ✅ Best Practice: bin/doctor

```bash
# Shows available models, CLIs, adapters:
echo "Models under test:"
read_list "$MODELS_FILE" | sed 's/^/  /'

# Shows missing adapters + how to install:
warn "hf not found — bin/lms_update needs it: brew install hf"

# Shows coverage gaps + exact commands to fill them:
echo "  bin/bench --runtime $runtime --agent $adapter --model $model --cases ..."
```

### ✅ Good: bin/bench (model discovery)

```bash
# Lines 290–340: Pre-flight check with actionable next steps
warn "models not found in LM Studio (lms ls):"
for m in "${missing[@]}"; do echo "    lms get $m"; done
```

### ❌ Gap: bin/eval-agent

Currently ends with:
```bash
echo "→ $OUT"  # Just shows file path
```

Should be:
```bash
help_section "NEXT STEPS"
help_line "  Results saved to: $OUT"
help_line "  View as table: column -t -s, < $OUT"
help_line "  Re-run with different model: bin/eval-agent --via lms --model <id>"
help_line "  See all results: ls eval/runs/"
```

### ❌ Gap: bin/smoke

Currently ends silently. Should add:
```bash
help_section "NEXT STEPS"
if [ "$PASS_COUNT" -gt 0 ]; then
  help_line "  Full benchmark with passing adapters:"
  help_line "    bin/bench --agent aider,hermes --models qwen/qwen3.5-9b"
fi
help_line "  See adapter logs: cat results/<timestamp>/sandbox/.bench.log"
```

## User Flow Examples

### Flow 1: New User (Hardware → Setup → Benchmark)
```bash
$ bin/hwprofile
  ✓ 64 GB RAM detected

Next steps:
  Run: bin/bootstrap-machine  (show recommendations)
  Then: bin/bootstrap-machine --write  (apply them)

$ bin/bootstrap-machine
  [shows recommended tier + models]

Next steps:
  Apply: bin/bootstrap-machine --write
  Verify: bin/smoke

$ bin/bootstrap-machine --write
  ✓ Updated for 64 GB tier

Next steps:
  Download models: lms get qwen/qwen3.6-27b
  Verify adapters: bin/smoke
  Run benchmark: bin/bench --agent aider

$ bin/smoke
  ✓ aider: PASS
  ✓ hermes: PASS
  ✗ opencode: FAIL (model too small)

Next steps:
  Run full benchmark with passing adapters:
    bin/bench --agent aider,hermes --models qwen/qwen3.5-9b
  Debug opencode: see bin/debug --help

$ bin/bench --agent aider --models qwen/qwen3.5-9b
  [... run completes ...]

Next steps:
  View results: bin/report --all --save
  Visualize: bin/viz
  See details: ls results/<timestamp>/
```

### Flow 2: User Has Bad Adapter Name
```bash
$ bin/bench --agent copilot
[FAIL] adapter not found: copilot (not installed on PATH)

Available adapters (lms):
  aider         — code editor CLI (https://aider.chat)
  caveman       — pi-based agent  (pip install caveman)
  cline         — VS Code ext    (code --install-extension saoudrizwan.claude-dev)
  codex         — OpenAI Codex   (npm install -g openai-api)
  continue      — IDE ext        (https://continue.dev)
  hermes        — agentic IDE    (https://github.com/hermes-ai/hermes)
  opencode      — OpenCode CLI   (npm install -g opencode)
  pi            — aider variant  (pip install pi-agent)

To install and benchmark:
  1. Install: brew install aider  (or pip install, npm install -g, etc.)
  2. Verify: bin/doctor  (checks all CLIs)
  3. Benchmark: bin/bench --agent aider --models qwen/qwen3.5-9b

See docs/tools/ for per-tool setup instructions.
```

## Checklist for New Commands

When adding a new `bin/*` tool:

- [ ] **Help text** — clear description + usage examples (see `bin/lib/help.sh`)
- [ ] **Error states** — show available choices (adapters, models, cases, etc.)
- [ ] **Dry-run mode** — preview changes + next steps
- [ ] **Mutation mode** — after changes, show next steps
- [ ] **Success message** — what was accomplished
- [ ] **Next steps section** — concrete, copy-paste-ready commands
- [ ] **Examples** — show 2–3 common workflows

## Related Files

- [WORKFLOW.md](WORKFLOW.md) — the complete user workflow
- [TESTING-STRATEGY.md](TESTING-STRATEGY.md) — bench matrix design
- [bin/lib/help.sh](../bin/lib/help.sh) — structured help formatting
- [bin/doctor](../bin/doctor) — best-in-class example (model + CLI discovery)
- [bin/bootstrap-machine](../bin/bootstrap-machine) — tier-based setup example

## Future: Interactive Help

Long-term, these could be scripted:
```bash
bin/bench --agent aider --models bad_id
# Could offer: "Run 'lms ls' to see available models?"
# Or: "Run 'bin/bench --interactive' to pick models?"
```

This depends on richer error context, but the pattern is: **show the error + the way out**.

## See also

- [WORKFLOW.md](WORKFLOW.md) — the complete user workflow
- [bin/doctor](../bin/doctor) — best-in-class example (model + CLI discovery)
- [bin/bootstrap-machine](../bin/bootstrap-machine) — tier-based setup example
- [bin/bench](../bin/bench) — full benchmark suite with next steps
- [bin/smoke](../bin/smoke) — smoke test with dry-run and mutation modes
