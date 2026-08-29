---
title: "Ornith-1.5-35B-A3B-MLX-4bit"
model_key: "Ornith-1.5-35B-A3B-MLX-4bit"
family: "Ornith 1.5"
params_total: "35B"
params_active: "3B (A3B MoE)"
quantization: "MLX 4-bit"
disk_size: "<!-- TODO -->"
context: "<!-- TODO -->"
status: "keep"
recommended_for: ["default", "bench", "smoke"]
tier: "64gb"
best_adapter: "pi"
accuracy: "100%"
speed_avg: "~29s (omlx)"
added: "2026-08-29"
last_run: "2026-08-29"
---

# Ornith-1.5-35B-A3B-MLX-4bit

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 100% (44/44) on pi/omlx |
| **Speed (avg)** | ~29.2s per case (omlx, pi) |
| **Best adapter** | pi — only adapter run so far |
| **Recommended for** | default bench/smoke model |
| **Status** | keep |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `Ornith-1.5-35B-A3B-MLX-4bit` (served via oMLX, no `omlx/` prefix — see `bin/omlx models`) |
| **Family / arch** | Ornith 1.5, MoE (35B total, ~3B active — A3B) |
| **Parameter count** | 35B total, 3B active |
| **Quantization** | MLX 4-bit |
| **Disk size** | <!-- TODO --> |
| **Context window** | <!-- TODO --> |
| **Added** | 2026-08-29 |
| **Last run** | 2026-08-29 (run `20260829-115614`) |
| **Doc updated** | 2026-08-29 |

## Results summary

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| pi | 44/44 (100%) | 29.2s | omlx | Full 12-case suite, all clean passes |

**Working adapters total:** 1/1 (only pi run so far)
**Overall (incl. broken adapters):** 44/44 (100%)

## Timing observations

Fastest case: smoke-00-hello (10s). Slowest: ts-01-groupby (84s). No timeouts or stalls observed; all 12 cases (bash, deleg, js×6, smoke×3, ts) completed within the default 300s ceiling, most well under 30s. No runtime-specific slowness noted for omlx on this model.

## Failure patterns

None — 44/44 across every case on the only adapter run (pi). Superseded `Ornith-1.0-35B-4bit` as the configured default (`config.sh` `PREFERRED_MODEL_ID`) on 2026-08-29; no regressions observed vs. the prior default in this initial pass.

## Better alternatives

Only one adapter (pi) has been run against this model so far — no cross-adapter or cross-model comparison data yet. Re-run with additional adapters (aider, cline, opencode, hermes, etc.) before drawing conclusions about relative standing vs. `Ornith-1.0-35B-4bit` or the `Qwen3.6-35B-A3B` family.

## Status

**keep** — set as the repo default (`config.sh`) for bench and smoke testing on 2026-08-29. Clean 100% first pass; needs broader adapter coverage to confirm beyond pi.
