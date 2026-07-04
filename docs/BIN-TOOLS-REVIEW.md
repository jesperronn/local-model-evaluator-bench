# Review: bin/* Tools and "Next Steps" Discovery Pattern

**Date:** 2026-07-04  
**Status:** Command Boundary Pattern is formalized but inconsistently applied.

## Summary

Every `bin/*` command should show "Next steps:" at its natural stopping points, so users know what to do without reading documentation. This review identifies which tools follow the pattern and which need updates.

## ✅ Tools with Good Discovery

### 1. bin/doctor (Best-in-class)
- ✓ Lists missing models + actionable download commands
- ✓ Shows CLI setup instructions (brew install hf)
- ✓ Proposes exact coverage-gap fill commands
- ✓ Shows what to do for hermes readiness

**Example:**
```bash
$ bin/doctor
...
Models not found in LM Studio:
  mistral-8b
Download:
  lms get mistral-8b

Coverage gaps (missing adapter × model × case):
  bin/bench --runtime lms --agent aider --model qwen --cases smoke-00-hello
```

### 2. bin/bench
- ✓ Pre-flight model check with "lms get" commands (lines 290–340)
- ✓ Warnings about slow/weak agents with docs reference
- ⚠️ **Gap:** Doesn't list available agents when `--agent` is invalid

**Example:**
```bash
$ bin/bench --agent aider --models nonexistent
[WARN] models not found in LM Studio (lms ls):
    nonexistent
Download:
    lms get nonexistent
[FAIL] no available models for runtime lms — nothing to run
```

### 3. bin/bootstrap-machine
- ✓ Documents the Command Boundary Pattern explicitly in its header
- ✓ Shows "Next steps:" after proposing changes
- ✓ Uses lib/help.sh for structured output

## ⚠️ Tools WITHOUT Good Discovery

| Tool | Current | Should Add |
|------|---------|-----------|
| **bin/eval-agent** | Ends with file path only | Next steps: CSV location, how to analyze, how to re-run |
| **bin/gen-evals** | Shows help examples | Next steps: "Pipe to: gen-evals \| claude --print" |
| **bin/smoke** | Silent on completion | Next steps: "Run full bench: bin/bench --agent aider,hermes ..." |
| **bin/report** | No action guidance | Next steps: "Visualize: bin/viz" |
| **bin/results stale** | Lists stale runs only | Next steps: "Clean: bin/results clean --empty" |
| **bin/lms_update** | No summary | Next steps: "Updated X models. To benchmark: bin/bench ..." |

## 🔴 Critical Gap: Agent Discovery

**Problem:** When a user passes `--agent nonexistent`, tools don't list available agents.

**Current behavior:**
```bash
$ bin/bench --agent x --models qwen/qwen3.5-9b
[FAIL] no adapter x
```

**Desired behavior:**
```bash
$ bin/bench --agent x --models qwen/qwen3.5-9b
[FAIL] unknown adapter: x

Available adapters (lms):
  aider         — code editor CLI
  caveman       — pi-based agent
  cline         — VS Code extension
  [more...]

Examples:
  bin/bench --agent aider --models qwen/qwen3.5-9b
  bin/bench --agent hermes --interactive
```

## What Was Done in This Review

### 1. Created docs/CLI-DISCOVERY.md
A comprehensive guide explaining:
- Why the pattern matters (user workflows, onboarding)
- The three phases: dry-run, mutation, errors
- Implementation patterns with code examples
- Before/after examples
- User flow examples (hwprofile → bootstrap → smoke → bench)
- Checklist for new commands

### 2. Enhanced bin/lib/help.sh
Added `help_next_steps_section()` helper for consistent formatting:

```bash
help_next_steps_section \
  "Download models|lms get qwen/qwen3.5-9b" \
  "Verify setup|bin/smoke --runtime lms" \
  "Run benchmark|bin/bench --agent aider"
```

Output:
```
NEXT STEPS
  1. Download models
     $ lms get qwen/qwen3.5-9b
  2. Verify setup
     $ bin/smoke --runtime lms
  3. Run benchmark
     $ bin/bench --agent aider
```

### 3. Updated README.md
Added link to CLI-DISCOVERY.md in the "Running & Debugging" section.

### 4. Updated Memory
Formalized the pattern in `/memory/command_boundary_pattern.md` with:
- Current status and gaps
- Reference to CLI-DISCOVERY.md
- Helper function details

## Recommended Next Actions

### HIGH Priority (15 min)
Implement agent discovery in bin/bench (line ~200):
```bash
if ! [ -f "$ADAPTERS_DIR/$adapter.sh" ]; then
  die "unknown adapter: $adapter"
  echo ""
  echo "Available adapters for $RUNTIME:"
  # ... list adapters ...
fi
```

### HIGH Priority (45 min)
Add next steps to these 3 post-run tools:
- bin/smoke: "Run full bench: bin/bench --agent aider,hermes ..."
- bin/gen-evals: "Pipe to Claude: gen-evals | claude --print"
- bin/eval-agent: "Results saved to X. View: column -t -s, < X"

### MEDIUM Priority (30 min)
Add next steps to remaining 3 tools:
- bin/report: "Visualize: bin/viz"
- bin/results stale: "Clean: bin/results clean --empty"
- bin/lms_update: "Updated X. To benchmark: bin/bench ..."

## Testing

After implementing, verify with:
```bash
# Agent discovery
bin/bench --agent nonexistent --models qwen/qwen3.5-9b
# Should list available agents

# Model discovery
bin/bench --agent aider --models nonexistent
# Should suggest: lms get nonexistent

# Smoke completion
bin/smoke --agent hermes
# Should show: bin/bench --agent hermes ...

# Gen-evals completion
bin/gen-evals
# Should suggest: gen-evals | claude --print
```

## Related Documents

- [CLI-DISCOVERY.md](CLI-DISCOVERY.md) — comprehensive guide (new)
- [WORKFLOW.md](WORKFLOW.md) — user workflows that depend on good discovery
- [TESTING-STRATEGY.md](TESTING-STRATEGY.md) — bench design + strategy
- [bin/lib/help.sh](../bin/lib/help.sh) — structured help helpers (updated)

## Example Implementations

**Best example (model + CLI discovery):**
- `bin/doctor` (lines 27–152)

**Next steps pattern:**
- `bin/bootstrap-machine` (explicitly documents the pattern)

**Pre-flight checks:**
- `bin/bench` (lines 290–340, model availability)

## Key Insight

The **Command Boundary Pattern** is not just UX polish — it's critical infrastructure. When commands in a workflow don't show what's next, users get stuck and repeat work. Examples:

```
hwprofile → bootstrap-machine → smoke → bench
doctor    → [next command?]              (currently silent)
eval-agent → [next command?]             (currently silent)
```

The pattern ensures workflows are **learnable from the CLI itself**, not hidden behind docs.
