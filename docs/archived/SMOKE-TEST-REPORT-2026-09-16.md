# Smoke Test Report: All Agent Harnesses
**Date:** September 16, 2026  
**Model:** Ornith-1.5-35B-A3B-MLX-4bit  
**Runtime:** oMLX  
**Test Cases:** smoke-00-hello, smoke-01-edit-file, smoke-02-numbers

---

## Executive Summary

✅ **6 adapters fully passing** (36/36 tests, 100%)  
⚠️ **15 adapters not tested** (timed out, config issues, not available)  
🔧 **Issues identified and documented** for future fixes

### Passing Adapters (All 100%, Ready for Full Benchmark)

| Adapter | Cases | Avg Speed | Verdict |
|---------|:-----:|:---------:|---------|
| **cn** | 6/6 | 8.7s | ✅ Fastest, all pass |
| **hermes** | 6/6 | 12.0s | ✅ Robust tool calling |
| **aider** | 6/6 | 13.3s | ✅ All tool calls succeed |
| **caveman** | 6/6 | 13.7s | ✅ Consistent performance |
| **cline** | 6/6 | 26.7s | ✅ All pass, slower |
| **openhands** | 6/6 | 44.7s | ✅ All pass, slowest |

---

## Detailed Results

### Passing Adapters (Per Test Case)

```
→ cn (Ornith-1.5-35B-A3B-MLX-4bit)
  [PASS] smoke-00-hello       2/2 ✅  (6s)   write file
  [PASS] smoke-01-edit-file   2/2 ✅  (10s)  insert line via tool call
  [PASS] smoke-02-numbers     2/2 ✅  (10s)  edit via tool call

→ hermes (Ornith-1.5-35B-A3B-MLX-4bit)
  [PASS] smoke-00-hello       2/2 ✅  (12s)  write file
  [PASS] smoke-01-edit-file   2/2 ✅  (10s)  insert line via tool call
  [PASS] smoke-02-numbers     2/2 ✅  (14s)  edit via tool call

→ aider (Ornith-1.5-35B-A3B-MLX-4bit)
  [PASS] smoke-00-hello       2/2 ✅  (24s)  write file
  [PASS] smoke-01-edit-file   2/2 ✅  (8s)   insert line via tool call
  [PASS] smoke-02-numbers     2/2 ✅  (8s)   edit via tool call

→ caveman (Ornith-1.5-35B-A3B-MLX-4bit)
  [PASS] smoke-00-hello       2/2 ✅  (10s)  write file
  [PASS] smoke-01-edit-file   2/2 ✅  (17s)  insert line via tool call
  [PASS] smoke-02-numbers     2/2 ✅  (14s)  edit via tool call

→ cline (Ornith-1.5-35B-A3B-MLX-4bit)
  [PASS] smoke-00-hello       2/2 ✅  (31s)  write file
  [PASS] smoke-01-edit-file   2/2 ✅  (27s)  insert line via tool call
  [PASS] smoke-02-numbers     2/2 ✅  (22s)  edit via tool call

→ openhands (Ornith-1.5-35B-A3B-MLX-4bit)
  [PASS] smoke-00-hello       2/2 ✅  (47s)  write file
  [PASS] smoke-01-edit-file   2/2 ✅  (43s)  insert line via tool call
  [PASS] smoke-02-numbers     2/2 ✅  (44s)  edit via tool call
```

---

## Not Tested / Failed to Complete (15 adapters)

These adapters were requested but did not produce results in this test run:

| Adapter | Issue | Blocker | Priority |
|---------|-------|---------|----------|
| **claude** | Tool-call failures | Model or adapter incompatibility | 🔴 High |
| **codex** | Model metadata not found | Config issue | 🔴 High |
| **copilot** | Not reaching model | Auth or config | 🔴 High |
| **forge** | Not reaching model | Native binding missing | 🟡 Medium |
| **goose** | Not reaching model | Unknown | 🟡 Medium |
| **gptme** | LLM naming error (400) | Configuration | 🔴 High |
| **interpreter** | Connection error | Reconnect loop | 🔴 High |
| **mini-swe-agent** | Not reaching model | stdin incompatibility | 🟡 Medium |
| **nanocoder** | Authentication failed | API key config | 🔴 High |
| **omp** | Tool-call failures | Model or adapter incompatibility | 🔴 High |
| **opencode** | JSON parse error | Malformed tool call | 🔴 High |
| **opencode-orch** | Session error | Configuration | 🔴 High |
| **pi** | Model not found (litellm 401) | Auth/routing | 🔴 High |
| **qwen** | Not reaching model | Unknown | 🟡 Medium |
| **vibe** | API error (invalid key) | Auth | 🔴 High |

---

## Known Issues & Fixes

### 1. **litellm Auth Issues** (pi, codex, gptme, nanocoder, vibe)

**Problem:**  
- Adapters route through litellm proxy and fail on 401 auth
- Message: "LiteLLM Virtual Key expected. Received=****, expected to start with 'sk-'"

**Root Cause:**  
- Adapters sending empty or invalid auth token to litellm
- Proxy expecting `sk-` prefixed key (OpenAI format)

**Fix Options:**
1. Set `LITELLM_MASTER_KEY` in adapters (preferred, one-time)
2. Disable proxy auth for localhost (security trade-off)
3. Update adapter config to send correct key format

**Recommended Fix:**
```bash
# In each failing adapter, add:
export LITELLM_MASTER_KEY="sk-1234567890abcdef"

# Or in config.sh, set once:
export LITELLM_MASTER_KEY="${LITELLM_MASTER_KEY:-sk-bench-key-12345}"
```

---

### 2. **Tool-Call Corruption** (claude, omp, opencode)

**Problem:**  
- Model emits malformed JSON (literal newlines, unescaped quotes)
- Adapter's strict parser rejects the call silently

**Root Cause:**  
- Small models (4-13B) commonly mangle JSON in large tool calls
- Adapters don't have recovery logic

**Fix Options:**
1. **mlxserve repair layer** (recommended) — catches malformed JSON at API level
2. **Extend tool-call-proxy** — implement repair logic for all runtimes
3. **Fix adapters individually** — add lenient parsing (high effort)

**Next Step:**
- Run same adapters with mlxserve to measure tool-call repair impact
- Expected improvement: +10–20% for codex/opencode, +5–10% for claude

---

### 3. **Native Binding Missing** (forge)

**Problem:**  
- Error: `Could not locate the bindings file (better-sqlite3)`

**Root Cause:**  
- forge depends on native bindings (better-sqlite3) not compilable on arm64

**Fix:**
- This is a known issue (documented in compat.json as deprecated)
- Requires fork to fix native dependencies or wait for upstream support

**Status:** Low priority — forge is marked deprecated; other adapters available

---

### 4. **Stdin/Interactive Issues** (mini-swe-agent)

**Problem:**  
- Agent prompts for setup regardless of config, requires interactive stdin

**Root Cause:**  
- mini-swe-agent v2 non-interactive stdin handling broken

**Fix:**
- Documented as deprecated (compat.json) — v2 incompatible with benchmarking
- Requires v1 or major upstream fix

**Status:** Low priority — marked deprecated

---

### 5. **Connection/Network Issues** (interpreter, openhands timeout)

**Problem:**  
- interpreter: "ERROR: Reconnecting... 1/5"
- openhands: Long timeouts (44s/case)

**Root Cause:**  
- interpreter: Network or connection pool exhaustion
- openhands: Slow inference, not an error (passing all tests)

**Fix for interpreter:**
- Check network connectivity
- Verify interpreter server is reachable
- May need process restart or resource limits

**Status for openhands:**  
- Already passing; slow but functional; acceptable for this model

---

## Recommendations

### Immediate (This Sprint)

1. **Fix litellm auth for 5 adapters** (pi, codex, gptme, nanocoder, vibe)
   - Set `LITELLM_MASTER_KEY` in adapters
   - Test: `bin/smoke -a pi,codex,gptme,nanocoder,vibe`
   - Expected gain: +5 adapters → 11/21 passing

2. **Test mlxserve impact on tool-call corruption** (claude, omp, opencode)
   - Run same adapters with mlxserve tool-calling repair
   - Measure: +10–20% expected on opencode/codex
   - Decision: integrate or extend tool-call-proxy?

### Medium-term (Next Week)

3. **Fix interpreter reconnection issue**
   - Debug why it fails (network pool, timeout, etc.)
   - Test: `bin/smoke -a interpreter --verbose`
   - Expected gain: +1 adapter → 12/21 passing

4. **Document deprecated adapters** (forge, mini-swe-agent)
   - Mark clearly in compat.json
   - Remove from default test suite
   - Keep documented for reference

### Long-term (Backlog)

5. **Extend tool-call-proxy** to implement mlxserve repair logic
   - Apply to all runtimes (oMLX, llama.cpp, Ollama)
   - Make tool-call repair the default, not optional

6. **Watch for upstream fixes**
   - better-sqlite3 arm64 support (forge)
   - mini-swe-agent v3 or migration
   - interpreter connection pool improvements

---

## Test Artifacts

- **Results CSV:** `results/20260916-065809/results.csv`
- **Full Log:** `/tmp/smoke-all-agents.log`
- **Run ID:** `20260916-065809`
- **Next Steps from Log:**
  ```bash
  # Run full benchmark with confirmed passing adapters
  bin/bench --agent aider,caveman,cline,cn,hermes,openhands \
    --models Ornith-1.5-35B-A3B-MLX-4bit --trials 1
  
  # Or pick interactively
  bin/bench --interactive
  ```

---

## Next Actions

**For user to decide:**

Option A (Conservative): Fix litellm auth, keep 6 passing adapters  
→ Gain +5 adapters, stable baseline  
→ Action: `# See fix above`

Option B (Aggressive): Also test mlxserve, extend tool-call-proxy  
→ Potential +8–10 adapters  
→ Action: `mlxserve --model ~/.omlx/models/ornith-ai/Ornith-1.5-35B-A3B-MLX-4bit --port 8081`

Option C (Hybrid): Fix auth + debug interpreter  
→ Gain +6 adapters (11/21)  
→ Action: Auth fix + `bin/debug interpreter Ornith-1.5-35B-A3B-MLX-4bit smoke-00-hello`
