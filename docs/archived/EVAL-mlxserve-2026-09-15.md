# mlxserve Evaluation — September 15, 2026

## What was tested

**Smoke tests with current baseline (oMLX):**
- Model: Ornith-1.5-35B-A3B-MLX-4bit
- Adapters: hermes, pi
- Cases: hello (write), edit-file (tool call), numbers (edit)
- Runtime: oMLX (multi-model server on :8000)

## Baseline results

```
hermes:  6/6  100% ✅ PASS
  - smoke-00-hello:     2/2 ✅ (write file)
  - smoke-01-edit-file: 2/2 ✅ (insert line via tool call)
  - smoke-02-numbers:   2/2 ✅ (edit via tool call)
  - avg: 18s/case

pi:      2/6   33% ❌ FAIL
  - smoke-00-hello:     2/2 ✅ (write file)
  - smoke-01-edit-file: 0/2 ❌ (litellm 401 auth, unrelated to tool-call repair)
  - smoke-02-numbers:   0/2 ❌ (same auth issue)
  - avg: 2s/case (tests abort immediately)
```

## Key findings

### 1. hermes is already robust
- 100% pass rate on oMLX
- Tool-call handling is permissive enough to tolerate minor JSON malformation
- **mlxserve repair layer**: minimal additional benefit (already at ceiling)

### 2. pi fails on tool calls, but auth is the blocker
- The 33% pass rate is NOT a tool-calling issue
- Root cause: litellm proxy returning 401 when pi tries to route through it
- Fix needed: separate from mlxserve (config or litellm routing)
- **mlxserve impact**: once auth is fixed, repair layer would add margin for edge cases

### 3. aider, codex, opencode not yet tested in this eval
- These adapters have known tool-call failures in compat.json
- Most affected by malformed JSON (strict parsing)
- **Expected mlxserve impact**: +10–20% pass rate
- **Blocker for comparison**: need to run smoke tests with aider/codex/opencode to quantify

## Recommendation

### Immediate (this sprint)
1. **Run full smoke test suite** with mlxserve for all adapters
   ```bash
   mlxserve --model ~/.omlx/models/ornith-ai/Ornith-1.5-35B-A3B-MLX-4bit --port 8081
   bin/smoke -m mlx/Ornith-1.5-35B-A3B-MLX-4bit -a aider,codex,opencode,hermes,pi --verbose
   ```
2. **Measure tool-call repair impact**: diff baseline (oMLX) vs mlxserve
3. **Fix pi auth issue**: separate task (litellm routing or adapter config)

### Medium-term (if repair impact is >5%)
1. Add mlxserve to docs/SETUP.md as "optional tool-calling stress test"
2. Create `bin/mlxserve-launch` wrapper (like bin/omlx)
3. Wire into GitHub CI: test mlxserve release on every new bench run
4. Document when to use: "For aider/codex/opencode, mlxserve is recommended"

### Long-term (if repair impact is >15% or becomes bottleneck)
1. Extend `bin/tool-call-proxy` to implement mlxserve's repair logic
2. Apply to all runtimes (oMLX, llama.cpp, Ollama)
3. Make tool-call repair the default (no separate runtime needed)

## Next steps

```bash
# Run this to compare mlxserve vs oMLX
cd /Users/jesper/src/local-model-evaluator-bench

# Start mlxserve
mlxserve --model ~/.omlx/models/ornith-ai/Ornith-1.5-35B-A3B-MLX-4bit --port 8081 &

# Smoke test aider, codex, opencode (the ones most affected by tool-call corruption)
bin/smoke -m mlx/Ornith-1.5-35B-A3B-MLX-4bit -a aider,codex,opencode --verbose 2>&1 | tee /tmp/mlxserve-eval.log

# Compare against baseline (already captured in results/20260915-222413/)
# Look for: aider JSON parse errors, codex timeouts, opencode malformed tool calls
```

## References

- Evaluation card: `docs/runtimes/mlxserve.md`
- Baseline results: `results/20260915-222413/results.csv`
- Tool-calling details: `bin/trace-tool-calls <session>`
- mlxserve project: https://github.com/ddalcu/mlx-serve
