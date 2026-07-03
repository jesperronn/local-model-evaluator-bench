# Qwen2.5-Coder 7B Testing Guide

**Date**: 2026-07-02  
**Status**: Preparation Complete  
**Models**: qwen/qwen2.5-coder-7b (LM Studio) + qwen2.5-coder-7b (Ollama)

## Overview

This document outlines the testing procedure for Qwen2.5-Coder 7B across LM Studio and Ollama runtimes using the local evaluator bench.

## Preparation Status ✓

### Ollama Setup
- **Model pulled**: `ollama list` shows both `qwen2.5-coder:7b` (raw, 4.7 GB) and custom variant
- **Custom Modelfile**: `qwen2.5-coder-7b` (created with 64K context + tool-call template fixes)
- **Tool-Call Proxy**: Running on port 11435 (handles raw JSON text → structured API conversion)
- **Modelfile location**: `config-templates/qwen2.5-coder-7b.Modelfile`

### LM Studio Setup
- **Model downloaded**: `/Users/jesper/.lmstudio/models/lmstudio-community/Qwen2.5-Coder-7B-Instruct-MLX-4bit`
- **Model key**: `qwen/qwen2.5-coder-7b` (confirmed via file system)
- **Status**: Ready to load and test
- **Note**: If `lms ls` fails with authentication error, restart LM Studio from GUI or use `lms server start`

### Configuration Updates
- **models-aliases.conf**: Added entry for cross-runtime aliasing
  ```
  qwen2.5-coder-7b	qwen/qwen2.5-coder-7b	-	qwen2.5-coder-7b
  ```

## Known Adapter Limitations

### Ollama (qwen2.5-coder-7b modelfile)
**Working adapters**:
- `aider` — uses raw model (compatible)
- `opencode-proxy` — uses tool-call proxy for text→JSON conversion
- `copilot` — uses tool-call proxy

**Blocked/Disabled**:
- `codex` — Model generates `apply_patch` but Ollama with `--local-provider ollama` only provides `exec_command` (training bias, not proxy limitation)
- `hermes` — Requires hard 64K context floor; qwen2.5 cannot meet this reliably
- `interpreter` — No test adapter for this runtime
- `openhands` — No test adapter for this runtime

### LM Studio
All standard adapters should work once model is loaded in LM Studio:
- `aider`, `cline`, `codex`, `caveman`, `hermes`, `opencode`, `pi`, `goose`, `copilot`, etc.

## Running the Tests

### Prerequisites
1. Verify Ollama has the model:
   ```bash
   ollama list | grep qwen2.5
   ```
   Should show:
   - `qwen2.5-coder:7b` (raw model)
   - `qwen2.5-coder-7b:latest` (custom modelfile)

2. Verify tool-call proxy is running:
   ```bash
   curl http://localhost:11435/api/tags | jq '.models | length'
   ```
   If not running: `bin/tool-call-proxy &`

3. Verify LM Studio model is available:
   ```bash
   ls -la /Users/jesper/.lmstudio/models/lmstudio-community/ | grep -i "qwen2.5"
   ```

### Phase 1: Ollama Smoke Test

Run the 3 lightweight smoke test cases (smoke-00-hello, smoke-01-edit-file, smoke-02-numbers) on Ollama:

```bash
bin/smoke --runtime ollama --model qwen2.5-coder-7b --verbose
```

**Expected output**:
- `aider`: PASS or PARTIAL (should reach model)
- `opencode-proxy`: PASS (preferred for Ollama with this model)
- `copilot`: PASS (via proxy)
- Other adapters: skipped or failed (expected due to limitations above)

**Time estimate**: 2-5 minutes depending on machine load

### Phase 2: Load Model in LM Studio

Once the Ollama smoke test completes, load the model in LM Studio:

```bash
# If lms ls works:
lms load qwen/qwen2.5-coder-7b --context 65536

# If lms authentication is broken:
# Restart LM Studio from the GUI, then:
lms load qwen/qwen2.5-coder-7b --context 65536
```

**Verify load**:
```bash
lms ps | grep qwen2.5
```

Should show model with context >= 65536.

### Phase 3: LM Studio Smoke Test

Once the model is loaded in LM Studio:

```bash
bin/smoke --runtime lms --model qwen2.5-coder-7b --verbose
```

**Expected output**:
- Most adapters: PASS
- Hermes: PASS (with 65K context available)
- Codex: PASS (LM Studio backend supports apply_patch)

**Time estimate**: 5-10 minutes (includes model warmup + inference)

### Phase 4: Nightly Full Benchmark (if all smoke tests pass)

If both smoke test suites pass, run the full nightly benchmark:

```bash
bin/nightly --model qwen2.5-coder-7b
```

This runs:
- **Adapters**: aider, cline, codex, copilot, goose, opencode, pi (hardcoded in bin/nightly)
- **Difficulty tiers**: easy, medium
- **Timeout**: 300s per task
- **Warmup**: 180s
- **Stall detection**: 120s

**Time estimate**: 30-60 minutes (varies by adapter count and model responsiveness)

**Output location**: `results/TIMESTAMP/results.csv`

### Phase 4 (Alternative): Custom Benchmark with All Adapters

For more comprehensive testing with specific adapters:

```bash
bin/bench \
  --agent aider,cline,codex,copilot,opencode,hermes \
  --model qwen2.5-coder-7b \
  --runtime lms \
  --difficulty easy,medium \
  --timeout 300 \
  --warmup 180 \
  --stall 120
```

## Troubleshooting

### LM Studio Authentication Error
```
Error: Invalid client passkey for client "lms-cli"
```

**Solution**:
1. Restart LM Studio from the GUI (Cmd+Q, then reopen)
2. Wait 10 seconds for the server to fully start
3. Try `lms ls` again

**If still broken**:
- Kill all llmster processes: `pkill -f llmster`
- Reopen LM Studio

### Model Not Loading in LM Studio
```
lms load qwen/qwen2.5-coder-7b
# Error: model not found
```

**Solution**:
- Verify download completed: `ls -lh /Users/jesper/.lmstudio/models/lmstudio-community/Qwen2.5-Coder-7B-Instruct-MLX-4bit`
- Check exact model key: `lms ls --json | jq -r '.[] | .modelKey' | grep -i qwen2.5`
- If not listed, restart LM Studio GUI

### Proxy Connection Errors (Ollama)
```
OLLAMA_BASE_URL mismatch with proxy port
```

**Solution**:
- Start proxy: `bin/tool-call-proxy &`
- Verify it's listening: `curl http://localhost:11435/api/tags`
- Check OLLAMA_BASE_URL: `echo $OLLAMA_BASE_URL`

## Monitoring Progress

### Watch smoke test progress:
```bash
# In another terminal:
tail -f results/*/sandbox/aider/*/.bench.log
```

### Check loaded models in LM Studio:
```bash
lms ps
```

### Check currently running benchmarks:
```bash
ps aux | grep bench
```

### View latest results CSV:
```bash
ls -lt results/*/results.csv | head -1
```

## Expected Results Summary

### Ollama (qwen2.5-coder-7b)
| Adapter | Smoke | Notes |
|---------|-------|-------|
| aider | ✓ PASS | Raw model, no proxy needed |
| opencode-proxy | ✓ PASS | Recommended for this model |
| copilot | ✓ PASS | Via proxy |
| codex | ✗ BLOCKED | Tool mismatch (apply_patch vs exec_command) |
| hermes | ✗ DISABLED | Context requirement conflict |

### LM Studio (qwen/qwen2.5-coder-7b)
| Adapter | Smoke | Notes |
|---------|-------|-------|
| aider | ✓ PASS | Primary adapter |
| cline | ✓ PASS | Tool-call support |
| codex | ✓ PASS | Backend supports apply_patch |
| hermes | ✓ PASS | 65K context available |
| others | ✓ PASS | Standard support |

## Cleanup (Optional)

To free up space after testing:

```bash
# Unload model from LM Studio:
lms unload qwen/qwen2.5-coder-7b

# Remove Ollama model (if needed):
ollama rm qwen2.5-coder:7b
ollama rm qwen2.5-coder-7b:latest
```

## Next Steps After Testing

1. Review `results/TIMESTAMP/results.csv` for metrics
2. Check `compat.json` for updated status (auto-updated by bin/smoke and bin/bench)
3. Create model documentation card in `docs/models/`
4. Update `BENCHMARK-RESULTS.md` with findings

## References

- **Models config**: `models-aliases.conf` (line ~50)
- **Ollama modelfile**: `config-templates/qwen2.5-coder-7b.Modelfile`
- **Tool proxy**: `bin/tool-call-proxy`
- **Smoke test docs**: `bin/smoke` (with `--help` flag)
- **Bench docs**: `bin/bench` (with `--help` flag)
