---
title: "gemma4:26b-mlx (Ollama)"
model_key: "gemma4:26b-mlx"
family: "Gemma 4"
params_total: "26B"
params_active: "4B"
quantization: "MLX (Ollama)"
disk_size: "~12-14 GB"
context: "4k default"
status: "keep"
recommended_for: ["64gb"]
tier: "64gb"
best_adapter: "hermes"
accuracy: "97.4%"
speed_avg: "~140s per case"
added: "2026-07-06"
last_run: "2026-07-06"
---

# gemma4:26b-mlx (Ollama)

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 97.4% (hermes) |
| **Speed (avg)** | ~140s per case |
| **Best adapter** | hermes (37/38 97.4%) ⭐ |
| **Recommended for** | multi-file/iterative coding tasks |
| **Status** | keep |

> **Key insight:** Hermes is slower (205s avg) but highly reliable on MoE models. Pi is faster (138s) with good results (82.4%).

## Metadata

| Field | Value |
|--------|-------|
| **Ollama model** | `gemma4:26b-mlx` |
| **Family / arch** | Gemma 4, MoE (26B total, 4B active) |
| **Parameter count** | 26B total, ~4B active |
| **Disk size** | ~12-14 GB (smaller than LMS/QAT variants) |
| **Context window** | 4k default |
| **Quantization** | MLX (by Ollama) |
| **Added** | 2026-07-06 (overnight gap-fill run) |
| **Last run** | 2026-07-06 (run `20260706-000910`) |
| **Doc updated** | 2026-07-06 |

## Results summary (2026-07-06 Overnight)

| Adapter | Tests | Pass % | Speed | Notes |
|---------|-------|--------|-------|-------|
| **hermes** | 37/38 | **97.4%** | 205s | 🌟 Highest accuracy, slow but reliable |
| **pi** | 28/34 | **82.4%** | 138s | Good balance, much faster than hermes |
| **aider** | 24/34 | **70.6%** | 99s | Decent, but aider struggles on large models |
| **codex** | 12/32 | 37.5% | 181s | Slow, not optimized for this model |
| **caveman** | 12/32 | 37.5% | 2s | Fast but low signal (fast default tool) |

**Overall:** 139/162 (85.8%)

## Key findings

1. **Hermes on MoE = gold standard** — Despite 205s average (slow), achieves 97.4% accuracy. Worth the wait for critical tasks.
2. **Pi provides fast middle ground** — 82.4% accuracy at 138s is 50% faster than hermes; good for less critical cases.
3. **Token-use adapters underperform** — aider (70.6%), codex (37.5%) don't leverage sparse MoE effectively.
4. **Caveman fast but unreliable** — 37.5% pass rate despite 2s speed (just returns default, not a real adapter).

## Cross-runtime comparison

| Adapter | Ollama (2026-07-06) | MLX 6-bit | LMS QAT |
|---------|:---:|:---:|:---:|
| hermes | 97.4% | 100% | 100% |
| pi | 82.4% | — | 100% |
| aider | 70.6% | — | 81% |

## Recommendation

**Use hermes + gemma4:26b-mlx for:** Multi-file edits, complex reasoning, code review where accuracy > speed.

**Use pi + gemma4:26b-mlx for:** Faster turnaround, real-time agents, when 82% is acceptable.

**Skip:** codex, caveman (low accuracy, not worth testing further).

## Status

**active** — 97.4% peak accuracy on Ollama. Slower than other MoE variants but highly reliable.
