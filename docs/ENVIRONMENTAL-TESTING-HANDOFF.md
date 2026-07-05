# Environmental Testing Handoff

**Purpose:** Explain how to test adapters in your specific environment, and what "environmental testing" means.

---

## What "Environmental Testing" Means

Your system has:
- LM Studio running at http://localhost:1234/v1 (via `lms server start`)
- Specific models loaded/available (liquid/lfm2-24b-a2b, phi4, qwen3.6-35b-a3b, etc.)
- Configuration in config.sh (SMOKE_MODEL, PREFERRED_MODEL_ID, etc.)
- Installed CLI tools (claude, mini-swe-agent, forge, etc.)

**"Environmental testing requires your environment"** means:
- I can't predict which models are loaded on YOUR machine
- I can't guarantee the Claude CLI works the same way on YOUR setup
- Tests need actual running adapters + models to diagnose real failures

**Translation:** Tests must run on your hardware, with your configuration, against your loaded models.

---

## How to Test an Adapter

### 1. Test with Your Models

```bash
# See what you have
lms ls

# Pick a fast, small model from the list
# Example: liquid/lfm2-24b-a2b

# Run smoke test
bin/smoke --agent <adapter> --model <your-model> --verbose
```

### 2. Read the Error Log

```bash
# If it fails, check the actual error:
cat results/<timestamp>/sandbox/<adapter>/<model>/smoke-00-hello/.bench.log

# Look for:
# - API errors (SDK incompatibility)
# - Missing dependencies (tool not installed)
# - Configuration errors (wrong env vars)
# - Timeout (tool too slow or hung)
```

### 3. Classify the Failure

**Unfixable:**
- SDK incompatibility (like Claude + Stainless SDK)
- Cloud-only dependencies (requires internet API)
- Hardware-specific issues

**Fixable:**
- Missing config files (can be pre-created)
- Environment variables (can be set in adapter script)
- Build issues (dependencies need rebuild)

**Maybe fixable:**
- Native binding compilation (may work on your hardware)
- Complex setup steps (may be automatable)

---

## Example: Testing Claude (What We Found)

```bash
# Step 1: Run test
bin/smoke --agent claude --model liquid/lfm2-24b-a2b --verbose

# Step 2: Check error
cat results/20260705-112308/sandbox/claude/liquid_lfm2-24b-a2b/smoke-00-hello/.bench.log

# Output:
# "I have created the file `/Users/jesper/...hello.txt` with the exact content: OK"
# [but file doesn't exist in sandbox]

# Step 3: Classify
# Root cause: Stainless SDK expects tool execution feedback from API
# LM Studio's OpenAI endpoint doesn't provide that feedback
# Result: UNFIXABLE — needs SDK or engine changes

# Step 4: Document
# Added to compat.json with verdict: "unfixable"
# Added to ADAPTER-SETUP.md: moved to ❌ incompatible section
```

---

## Testing Workflow for NEW Adapters

### Quick Test (5 minutes)

```bash
# 1. Run smoke
bin/smoke --agent <name> --model <small-model> --verbose

# 2. Check result
tail -20 results/latest/sandbox/<name>/*/smoke-00-hello/.bench.log

# 3. Decide
# - PASS → add to DEFAULT_ADAPTERS, move on
# - FAIL → read error, classify (fixable/unfixable)
```

### Deep Dive (if fails)

```bash
# 1. Read full error log
cat results/latest/sandbox/<name>/*/.bench.log

# 2. Search for root cause
# Look for: API error? Missing file? Timeout? Permission denied?

# 3. Try a fix if obvious
# Examples:
#   - Missing config → pre-create it
#   - Wrong env var → update adapter script
#   - Missing build tool → install it

# 4. Re-test
bin/smoke --agent <name> --model <small-model>

# 5. Document result
# Add to compat.json with verdict + first_seen date
```

---

## What I Did vs. What You'll Do

| Step | I Did | You Do |
|------|-------|--------|
| Diagnosed adapter issues | ✓ Read code, compat.json, git history | — |
| Designed test approach | ✓ Wrote test plan | — |
| **Actually run smoke tests** | ✓ (in my environment) | ✓ Run in YOUR environment |
| **Interpret failures** | ✓ (based on logs) | ✓ Read .bench.log, diagnose |
| **Decide fixable/unfixable** | ✓ (based on code analysis) | ✓ (you know your setup) |
| **Update compat.json** | ✓ (preliminary) | ✓ (final, with verdicts) |

---

## Why This Pattern?

**Adapters are environment-specific:**
- Some need native compilation (better-sqlite3, node-gyp)
- Some need installed tools (Claude CLI, forge CLI)
- Some need config files in user home (~/.config/*)
- Some have OS-specific issues (macOS vs. Linux)

**Only YOU can:**
- Know if build tools are installed
- Know if tools are in PATH
- Know if config files exist
- Know if hardware is capable
- Decide if fix effort is worth it

---

## Template for Next Adapter

If you need to test a new adapter:

1. **Run:** `bin/smoke --agent <name> --model <small> --verbose`
2. **Check:** `cat results/latest/sandbox/<name>/*/.bench.log`
3. **Classify:** Fixable? Unfixable? Maybe-fixable?
4. **Document:** Add to compat.json with:
   - `status: "open"`
   - `reason: "<root cause from error log>"`
   - `verdict: "fixable|unfixable|maybe-fixable"`
5. **Decide:** Fix it, deprecate it, or mark as experimental

---

## Related Documentation

- [ADAPTER-TEST-RESULTS.md](ADAPTER-TEST-RESULTS.md) — Specific test results (claude, mini-swe-agent, forge)
- [ADAPTER-SETUP.md](ADAPTER-SETUP.md) — Compatibility matrix
- [compat.json](../compat.json) — Full tracking of all incompatibilities + verdicts
