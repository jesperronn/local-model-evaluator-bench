# Nightly Bench Run — Prep & Findings

**Date:** 2026-06-27  
**Status:** Ready to run  

## ⚠️ Model Clarification Needed

You requested: `qwen3.6-30b-a3b` — this model doesn't exist in the suite.

**Available qwen3.6 models:**
- `qwen/qwen3.6-35b-a3b` (35B MoE, 3B active) — strongest general model, currently GENERATING (another agent using it)
- `qwen/qwen3.6-27b` (removed 2026-06-12, strictly dominated)

**Available 30B model:**
- `qwen/qwen3-coder-30b` (30B dense, code-specialized)

**Recommendation:** Use `qwen3.6-35b-a3b` unless you specifically need the code-tuned variant.

---

## Adapter Status

### ✓ Functional (LMS backend)
These adapters work and are ready for nightly runs:
```
aider, caveman, claude, cline, codex, copilot, goose, opencode, pi
```
(hermes requires config in `~/.hermes/config.yaml` — see [DEFAULT_ADAPTERS](config.sh) comment)

**Total:** 9 functional adapters

### ✗ Non-functional (missing external tools)
These adapters were added but the required CLI tools are **NOT installed**:

| Adapter | Requires | Status | To install |
|---------|----------|--------|------------|
| **forge-lms.sh** | `forge` CLI | ✗ NOT INSTALLED | `cargo install forge-cli` |
| **gptme-lms.sh** | `gptme` Python pkg | ✗ NOT INSTALLED | `pip install gptme` |
| **mini-swe-agent-lms.sh** | `mini-swe-agent` | ✗ NOT INSTALLED | `pip install mini-swe-agent` |
| **swe-agent-lms.sh** | `swe-agent` | ✗ NOT INSTALLED | `pip install sweagent` |

**Action taken:** These adapters are excluded from nightly runs until the tools are installed.

---

## Nightly Run Configuration

### Primary Run: qwen3.6-35b-a3b
```bash
bin/nightly
```

**What it does:**
- Uses 9 functional LMS adapters (aider, caveman, claude, cline, codex, copilot, goose, opencode, pi)
- Runs all 11 test cases
- Filters to easy + medium difficulty (skips hard/multi-file cases for faster feedback)
- Timeout: 300s per trial
- Watchdogs: warmup=180s (first output), stall=120s (no progress)

**Expected duration:** ~2–3 hours (9 adapters × 11 cases × avg ~20–30s per case)

⚠️ **Warning:** qwen3.6-35b-a3b is currently GENERATING (another agent using it). This run will slow that agent but won't kill the model.

### Secondary Run: devstral-small-2-2512 (if time permits)
```bash
bin/nightly --devstral
```

Add this to the command to run devstral2-small after the primary finishes.

### Include Hard Cases (optional)
```bash
bin/nightly --all-cases
```

Adds multi-file and self-verify cases (js-03, js-04, js-06, etc). ~+30% duration.

---

## Model Cards to Update

After nightly run completes, update:

1. **docs/models/qwen--qwen3.6-35b-a3b.md**
   - Update `Last run` date
   - Add new adapter results if running hermes
   - Update failure pattern notes if any changes

2. **docs/models/mistralai--devstral-small-2-2512.md** (if running --devstral)
   - Update `Last run` date
   - Replace `<!-- TODO -->` sections
   - Document Workarounds needed
   - Add Results summary

3. Create new adapter cards as needed (if testing external tools):
   - docs/tools/forge.md
   - docs/tools/gptme.md
   - docs/tools/mini-swe-agent.md
   - docs/tools/swe-agent.md

---

## Pre-run Checklist

- [x] Adapters verified (9 functional, 4 skipped due to missing tools)
- [x] Cases verified (11 total, all with difficulty field)
- [x] Models verified (qwen3.6-35b-a3b loaded, devstral-small available)
- [x] Test cases with difficulty field verified (11/11)
- [x] bin/nightly script created and tested
- [x] Model cards prepared for updates
- [ ] **TODO: Clarify which model for primary run** (assumed qwen3.6-35b-a3b)

---

## Run Commands

### Quick smoke test (verify setup)
```bash
bin/smoke --runtime lms
```

### Primary nightly run
```bash
bin/nightly
# or with all cases:
bin/nightly --all-cases
# or with alternate model:
bin/nightly --model qwen/qwen3-coder-30b
```

### With devstral secondary
```bash
bin/nightly --devstral
```

### Run in background with logging
```bash
nohup bin/nightly > nightly.log 2>&1 &
tail -f nightly.log
```

---

## Results & Findings

After the run:
1. Check `results/results.csv` for scores
2. Update model cards with findings
3. Identify any adapter-specific failures
4. Log in TASKS.md

**Output locations:**
- Bench results: `results/results.csv` (scored and timed)
- Individual run logs: `cases/*/bench/` (per-adapter, per-trial)
- Model load history: `lms ps` (view all recent loads)

---

## Notes

- **qwen3.6-35b-a3b actively in use:** Won't unload it; bench will queue behind other work
- **External adapters eliminated:** 4 adapters (forge, gptme, mini-swe-agent, swe-agent) documented as non-functional; can revisit if tools are installed later
- **Watchdog tuning:** warmup=180s (generous for cold load on 35B), stall=120s (tighter once model is hot) — adjust if needed
- **Difficulty gating:** Filtering to easy+medium by default; add `--all-cases` to include hard multi-file tasks
