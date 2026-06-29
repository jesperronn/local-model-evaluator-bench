# Hardware Recommendations for Agentic Coding

Based on 2026-06-29 benchmark results across 7 models × 11 adapters on Apple Silicon.

## TL;DR

| Machine | Best setup | Expected throughput |
|---------|-----------|-------------------|
| **M5 Max 128 GB** | qwen3.6-35b-a3b (MoE) + aider/cline | 100% accuracy, 10–90s/task |
| **M2 Max 32 GB** | qwen3.5-9b or gemma-4-26b-a4b-qat + aider/interpreter | 92–100% on most tasks, 10–170s/task |

---

## M5 Max 128 GB

### Model selection

With 128 GB unified memory, you can run any model in the benchmark. The decision is capability vs. speed:

| Model | Disk (GGUF) | Speed | Accuracy | Verdict |
|-------|------------|-------|----------|---------|
| **qwen3.6-35b-a3b** | ~20 GB | Fast (MoE, 3.6B active) | 100% all adapters | **Primary recommendation** |
| **qwen3-coder-30b** | ~18 GB | Fast (MoE, 3B active) | aider 100% avg 11s | **Strong alternative** |
| **gemma-4-26b-a4b-qat** | ~14 GB | Fast (MoE, 4B active) | 97–100% on best adapters | Good for variety |
| qwen3.6-27b | ~18 GB | Slow (dense 27B) | 93% on 6 adapters | Skip — MoE is better |
| glm-4.7-flash | ~24 GB | Very slow (dense 30B GGUF) | 41% (timeout-limited) | Skip — GGUF too slow |
| devstral-small-2-2512 | ~15 GB | Medium | 69% | Skip — opencode/openhands collapse |

**Primary:** `qwen/qwen3.6-35b-a3b`
- 100% accuracy across all 9 working adapters in the 2026-06-29 sweep
- MoE architecture: only 3.6B parameters active per token — fast despite 35B total
- Handles thinking mode correctly (no leakage into edits)
- BENCH_PARALLEL=3 is appropriate for multi-agent orchestration scenarios

**Secondary:** `qwen/qwen3-coder-30b`
- aider at 11s average — fastest model-adapter combo in the benchmark
- 100% on aider and interpreter; 92% on codex/hermes/openhands
- Fine-tuned for code; slightly weaker on prose/non-code tasks vs. 35b-a3b
- Use when raw speed is the priority

**Bonus — load multiple at once:** 128 GB lets you run two MoE models simultaneously (35b-a3b ~20 GB + coder-30b ~18 GB ≈ 38 GB, leaving 90 GB for other work). You can hot-swap between them or run A/B comparisons.

### Adapter selection

| Adapter | Speed on M5 Max | Notes |
|---------|----------------|-------|
| **aider** | 11–87s | Fastest; use for batch/CI |
| **interpreter** | 48–160s | 100% on qwen3.6-35b-a3b; good fallback |
| **cline** | 20–300s | 100% on qwen3.6-35b-a3b; complex tasks |
| **hermes** | 23–87s | 100%; needs one-time config |
| **goose** | 18–110s | 100%; good self-verify |
| **openhands** | 20–254s | 100% on main models; avoid devstral |

**Recommended stack:** aider (daily use) + cline (complex multi-file tasks) + interpreter (when you need shell execution)

### LM Studio config

```bash
# config.sh tuning for M5 Max 128 GB
BENCH_CONTEXT=131072    # full context; 128 GB can hold this
BENCH_PARALLEL=4        # 4 concurrent agents (orchestrator + 3 workers)
BENCH_TTL_MINUTES=30    # keep model warm longer between tasks
```

---

## M2 Max 32 GB

### Model selection

32 GB limits which models fit comfortably. Key constraint: with BENCH_CONTEXT=65536 and BENCH_PARALLEL=3, a dense 27B model may use 20–25 GB for KV cache alone.

| Model | Disk (GGUF) | Fits? | Speed | Accuracy | Verdict |
|-------|------------|-------|-------|----------|---------|
| **qwen3.5-9b** | ~6 GB | Easily | Fast | 93% excl broken adapters | **Primary recommendation** |
| **gemma-4-26b-a4b-qat** | ~14 GB | Yes | Fast (4B active) | 91% excl broken | **Strong alternative** |
| **qwen3.6-35b-a3b** | ~20 GB | Yes (tight with ctx) | Fast (3.6B active) | 100% | Best if it fits |
| qwen3.6-27b | ~18 GB | Marginal | Slow (dense) | 93% | Risky — KV cache contention |
| glm-4.7-flash | ~24 GB | Tight | Very slow | 41% | Skip |
| devstral-small-2-2512 | ~15 GB | Yes | Medium | 69% | Skip |

**Primary:** `qwen/qwen3.5-9b`
- ~6 GB on disk, tiny KV footprint — runs anywhere on 32 GB
- aider 100%, interpreter 100% in 2026-06-29 sweep
- Fast: aider cases complete in 12–29s
- Leaves plenty of RAM for IDE, browser, other tools running in parallel

**Secondary:** `google/gemma-4-26b-a4b-qat`
- 14 GB on disk; MoE (4B active) keeps KV cache small
- 97–100% on best adapters (goose/hermes/pi/opencode/interpreter)
- Noticeably better than qwen3.5-9b on multifile and complex edits
- Still leaves ~14 GB for other processes on a 32 GB machine

**If you need max accuracy:** `qwen/qwen3.6-35b-a3b` at ~20 GB can load on 32 GB but leaves only ~10 GB headroom. With BENCH_PARALLEL=1 and BENCH_CONTEXT=65536 this works. Reduce parallel to 1 and context to 32768 if you see pressure.

### Adapter selection for 32 GB

| Adapter | Notes on 32 GB |
|---------|---------------|
| **aider** | Excellent — 100% on both recommended models, very fast |
| **interpreter** | 100%; reasonable speed on qwen3.5-9b (~80s avg) |
| **hermes** | 94–100%; good option |
| **goose** | 89–100%; reliable |
| **cline** | 89%; slower but thorough |
| ❌ opencode | 37% on devstral — model-dependent; check per model |
| ❌ openhands | 37% on devstral; 83–86% on qwen/gemma — check per model |

**Recommended stack:** aider (default) + interpreter (fallback) + hermes (when you need 100% and have config)

### LM Studio config

```bash
# config.sh tuning for M2 Max 32 GB
BENCH_CONTEXT=65536     # 64K is safe; 128K risks OOM with dense models
BENCH_PARALLEL=2        # 2 concurrent; conserve RAM for other apps
BENCH_TTL_MINUTES=10    # default; unload promptly to free memory
```

If running qwen3.6-35b-a3b on 32 GB, reduce parallel to 1:
```bash
BENCH_PARALLEL=1
BENCH_CONTEXT=32768    # 32K if 64K causes pressure
```

---

## Key Insights from Benchmarks

### MoE vs Dense — the decisive factor

Every MoE model in the benchmark (3B–4B active params) outperforms dense models of similar total parameter count on BOTH speed and accuracy:

| Architecture | Example | Active params | Speed | Accuracy |
|-------------|---------|--------------|-------|----------|
| MoE | qwen3.6-35b-a3b | 3.6B | ~40–90s/task | 100% |
| Dense | qwen3.6-27b | 27B | ~100–300s/task | 76–100% |
| Dense | glm-4.7-flash | 30B (GGUF) | 300s+ (timeout) | 41% |

**Rule:** Always prefer MoE when available. The GGUF quantization of dense models compounds the slowness on Apple Silicon (no Metal-optimized GGUF path).

### Adapter speed vs accuracy tradeoff

On a 32 GB machine where you want to maximise work done per hour:
- **aider** wins: 11–30s per task, 93–100% accuracy on MoE models
- **interpreter** is the safe second choice: 48–160s, similar accuracy
- Avoid openhands/pi on 32 GB if throughput matters (100–300s/task)

### Multi-agent setups

For orchestrator + workers patterns (e.g. Claude Code orchestrating local agents):
- **M5 Max 128 GB:** 4 parallel agents on qwen3.6-35b-a3b is fine. Each agent needs ~4 GB KV cache at 65K context.
- **M2 Max 32 GB:** 2 parallel agents maximum. qwen3.5-9b is ideal — tiny KV cache leaves room for the orchestrator model.

---

## Quick Setup

### M5 Max 128 GB

```bash
# Download primary model
lms get qwen/qwen3.6-35b-a3b

# Optional: also grab the fast coder
lms get qwen/qwen3-coder-30b

# Add to models.txt
echo "qwen/qwen3.6-35b-a3b" >> models.txt
echo "qwen/qwen3-coder-30b" >> models.txt

# Run smoke test
bin/smoke --model qwen/qwen3.6-35b-a3b

# Run full bench
bin/bench-overnight --stale
```

### M2 Max 32 GB

```bash
# Download primary model
lms get qwen/qwen3.5-9b

# Or: smaller footprint + higher accuracy
lms get google/gemma-4-26b-a4b-qat

# Add to models.txt
echo "qwen/qwen3.5-9b" >> models.txt

# Tune config for 32 GB
# In config.sh: BENCH_PARALLEL=2, BENCH_CONTEXT=65536

# Run smoke test
bin/smoke --model qwen/qwen3.5-9b

# Run aider directly
MODEL_ID=qwen/qwen3.5-9b adapters/aider-lms.sh <<< "fix the off-by-one in utils.js"
```

---

*Benchmark data: 2026-06-29 overnight sweep, 7 models × 11 adapters × 11 cases, LM Studio runtime on Apple Silicon.*
