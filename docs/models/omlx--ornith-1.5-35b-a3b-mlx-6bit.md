---
title: "Ornith-1.5-35B-A3B-MLX-6bit"
model_key: "Ornith-1.5-35B-A3B-MLX-6bit"
family: "Ornith 1.5"
params_total: "35B"
params_active: "3B (A3B MoE)"
quantization: "MLX 6-bit"
disk_size: "24 GiB"
context: "256k native (BENCH_CONTEXT applies for bench runs)"
status: "keep"
recommended_for: ["bench", "smoke"]
tier: "64gb"
best_adapter: "omp (with --thinking=low), nanocoder, pi, cn, caveman"
accuracy: "85.7% overall adapter compatibility (18/21 adapters) — identical to 4-bit variant"
speed_avg: "14.0s median (omp with --thinking=low optimization), 21s (nanocoder), 29s (pi), 44s (cn), 54s (caveman)"
added: "2026-09-11"
last_run: "2026-09-11"
last_update: "2026-09-12"
---

# Ornith-1.5-35B-A3B-MLX-6bit

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 85.7% overall adapter compatibility (18/21 adapters — identical to 4-bit variant) |
| **Speed (avg)** | 14.0s median with omp + --thinking=low optimization |
| **Best adapter** | omp (with --thinking=low) — 41% faster than baseline, 100% pass rate |
| **Recommended for** | production benchmarking, full suite runs |
| **Status** | keep |

> Note: 6-bit variant identical performance to 4-bit in 2026-09-11 sequential testing. Both are production-ready.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `Ornith-1.5-35B-A3B-MLX-6bit` (served via oMLX, no `omlx/` prefix — see `bin/omlx models`) |
| **Family / arch** | Ornith 1.5, MoE (35B total, ~3B active — A3B) |
| **Parameter count** | 35B total, 3B active |
| **Quantization** | MLX 6-bit |
| **Disk size** | 24 GB (`~/.omlx/models/ornith-ai/Ornith-1.5-35B-A3B-MLX-6bit`) |
| **Context window** | 262144 (256K) native (`max_position_embeddings`, model `config.json`); bench runs use `BENCH_CONTEXT` |
| **Added** | 2026-09-11 |
| **Last run** | 2026-09-11 (sequential smoketest: all 21 adapters × 2 models) |
| **Doc updated** | 2026-09-12 |

## Latest results (2026-09-11 sequential smoketest)

**Test methodology:** All 21 adapters tested sequentially (one at a time, no parallelization) on both 4-bit and 6-bit variants. Clean resource isolation — each adapter run in isolation to eliminate contention artifacts.

**Summary:**
| Metric | Value |
|--------|-------|
| **Adapters tested** | 21 |
| **Pass rate** | 85.7% (18/21 fully working) |
| **4-bit variant** | 18/21 PASS (85.7%) |
| **6-bit variant** | 18/21 PASS (85.7%) — **identical to 4-bit** |
| **Broken adapters** | 3: copilot, forge, hermes (adapter-specific issues, not model problems) |

**Fully working adapters (18/21):**
- ✅ aider, caveman, claude, cline, cn, codex
- ✅ goose, gptme, interpreter, mini-swe-agent
- ✅ nanocoder, omp, opencode, opencode-orch
- ✅ openhands, pi, qwen, vibe

**Key findings:**
- **Variant parity:** 6-bit and 4-bit have identical pass rates and timing profiles
- **OMP optimization:** `--thinking=low` flag applied to OMP adapter reduces overthinking
  - **41% speedup achieved** (baseline 23.7s → 14.0s median)
  - Zero compatibility impact — maintains 100% pass rate on working adapters
- **Sequential vs. parallel:** Sequential testing eliminates resource contention, revealing true adapter compatibility (85.7% vs. ~40-50% in contended parallelized runs)

## Comparison: 4-bit vs 6-bit

Both variants tested in parallel 2026-09-11 sequential run. Results:

| Aspect | 4-bit | 6-bit |
|--------|-------|-------|
| **Pass rate** | 85.7% (18/21) | 85.7% (18/21) |
| **Broken adapters** | copilot, forge, hermes | copilot, forge, hermes |
| **Median speed (omp)** | 14.0s | 14.0s |
| **Disk size** | 18 GB | 24 GB |
| **Recommendation** | Preferred for storage-constrained systems | Preferred for speed/quality tradeoff |

**Verdict:** No meaningful difference detected. Either variant is suitable for production use. Choose 4-bit for disk space savings (18 GB vs 24 GB), or 6-bit for marginally improved output quality if disk is not a constraint.

## Status

**keep** — production-ready as of 2026-09-11 sequential smoketest. 85.7% adapter compatibility (18/21), with only adapter-specific issues in the 3 broken ones (not model problems). Both 4-bit and 6-bit variants equally recommended.
