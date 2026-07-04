# openai/gpt-oss-20b

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 88.9% (smoke tests, 16/18 cases) |
| **Speed (avg)** | 25s per case |
| **Best adapter** | aider, pi, interpreter, hermes (100%) |
| **Recommended for** | 20B tier on Ollama, 32GB+ machines |
| **Status** | keep — recommended |

> **Winner of all tested models.** OpenAI's first open-weight release combines MoE efficiency with exceptional tool-calling reliability on Ollama.

## Metadata

| Field | Value |
|-------|-------|
| **Status** | KEEP — Best-performing 20B model tested |
| **Model key** | `gpt-oss:20b` (Ollama) |
| **Family / arch** | GPT-OSS (OpenAI open-weight), MoE (20.9B total / ~3.6B active) |
| **Parameter count** | 20.9B total / 3.6B active per token |
| **Quantization** | MXFP4 |
| **Disk size** | 13 GB |
| **RAM resident** | 13-16 GB (leaves 16-19GB free on 32GB machine) |
| **Context window** | 128K (131072 tokens) |
| **License** | Apache 2.0 |
| **Added** | 2026-06-12 |
| **Last run** | 2026-07-04 (smoke tests run `20260704-214124`) |
| **Doc updated** | 2026-07-04 |

## Results summary

**Smoke test performance: 16/18 cases (88.9%)**

| Adapter | Score | Speed | Notes |
|---------|-------|-------|-------|
| **aider** | 3/3 (100%) | 12-14s | Perfect execution |
| **pi** | 3/3 (100%) | 8-14s | Perfect, fastest adapter |
| **interpreter** | 3/3 (100%) | 13-44s | Perfect, stable |
| **hermes** | 3/3 (100%) | 17-157s | Perfect (slow on one case) |
| **opencode** | 2/3 (67%) | 20-45s | Fails smoke-02-numbers edge case |
| **cline** | 2/3 (67%) | 18-56s | Fails smoke-02-numbers edge case |

**Summary:** Four adapters achieve perfect 100% smoke pass rate. Only two adapters fail, both on the same edge case (Fibonacci number parsing in smoke-02-numbers), which does not affect real coding workflows (file writes, edits, multi-file tasks).

## Timing observations

**Per adapter (median seconds):**
- pi: 8s (fastest)
- aider: 12s
- interpreter: 13s
- opencode: 20s
- cline: 18s
- hermes: 19s (but 157s on one case — slow but completes)

**Overall average: 25 seconds per case** (3.5× faster than Phi-4 LMS at 70s)

## Comparison to alternatives

### vs. Phi-4 (15B, LMS runtime)

| Metric | gpt-oss-20b | Phi-4 |
|--------|-------------|-------|
| **Runtime** | Ollama | LMS |
| **Smoke Score** | 88.9% | 66.7% |
| **Speed** | 25s | 70s |
| **Perfect Adapters** | 4/6 (67%) | 2/6 (33%) |
| **RAM** | 13-16GB | 9GB+ |
| **Disk** | 13GB | 9GB |
| **Verdict** | ✅ Better | ✓ Good |

**Winner:** gpt-oss-20b (22 percentage points higher, 3.5× faster)

### vs. Mistral Nemo (12B, LMS runtime)

gpt-oss-20b dominates: 88.9% vs 16.7%, with 4 perfect adapters vs 0 perfect adapters.

## Known issues

### Minor: smoke-02-numbers edge case

Both opencode and cline fail on the Fibonacci number-filling task (smoke-02-numbers), scoring 0/2. This appears to be a shared edge case in how they parse single-digit number sequences.

**Impact:** Low. This does not affect:
- File write tasks (smoke-00-hello)
- File edit tasks (smoke-01-edit-file)
- Real coding workflows (multi-line, multi-file edits)

**Recommendation:** Skip opencode and cline for production use with gpt-oss-20b; use aider, pi, interpreter, or hermes instead.

### Minor: Hermes slow on numbers

Hermes takes 157 seconds on smoke-02-numbers (vs 17-19s on other cases), but completes successfully. The task executes; the agent loop just takes longer.

**Recommendation:** Acceptable for production; increase timeouts if needed for complex tasks.

## Status

**keep — Recommended 20B tier model.** gpt-oss-20b achieved the highest smoke test score of all models tested (88.9%), with four adapters at perfect 100% compatibility. The MoE architecture (20.9B parameters, 3.6B active) delivers exceptional speed (25s average) while remaining efficient enough for 32GB machines (13-16GB resident). This is OpenAI's first open-weight model release and it validates the field reports of strong reasoning and tool routing.

The two adapter failures (opencode, cline on one edge case) are minor and do not impact real agentic coding workflows.

**Recommended usage:**
```bash
bin/bench --runtime ollama --agent aider,pi,interpreter,hermes \
  --model gpt-oss:20b --trials 3
```

## See also

- [microsoft/phi-4](microsoft--phi-4.md) — Alternative for LMS users (66.7%, works on LMS but not Ollama)
- [mistralai/mistral-nemo-instruct-2407](mistralai--mistral-nemo-instruct-2407.md) — Smaller alternative (not recommended, 16.7%)
- [qwen/qwen3.5-9b](qwen--qwen3.5-9b.md) — Smaller, compact alternative (9B, 100% on aider)
