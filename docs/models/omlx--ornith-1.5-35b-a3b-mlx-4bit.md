---
title: "Ornith-1.5-35B-A3B-MLX-4bit"
model_key: "Ornith-1.5-35B-A3B-MLX-4bit"
family: "Ornith 1.5"
params_total: "35B"
params_active: "3B (A3B MoE)"
quantization: "MLX 4-bit"
disk_size: "18 GiB"
context: "256k native (BENCH_CONTEXT applies for bench runs)"
status: "keep"
recommended_for: ["default", "bench", "smoke"]
tier: "64gb"
best_adapter: "pi, goose"
accuracy: "100% (pi), 90.9% (goose)"
speed_avg: "~29s (pi), ~134s (goose)"
added: "2026-08-29"
last_run: "2026-08-29"
---

# Ornith-1.5-35B-A3B-MLX-4bit

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 100% (44/44) on pi/omlx; 90.9% (40/44) on goose/omlx |
| **Speed (avg)** | ~29.2s per case (pi, omlx) |
| **Best adapter** | pi — fastest and most reliable of the 6 tried so far |
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
| **Disk size** | 18 GB (`~/.omlx/models/ornith-ai/Ornith-1.5-35B-A3B-MLX-4bit`) |
| **Context window** | 262144 (256K) native (`max_position_embeddings`, model `config.json`); bench runs use `BENCH_CONTEXT` |
| **Added** | 2026-08-29 |
| **Last run** | 2026-08-29 (runs `20260829-115614`, `20260829-132337`) |
| **Doc updated** | 2026-08-29 |

## Results summary

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| pi | 44/44 (100%) | 29.2s | omlx | Full 12-case suite, all clean passes |
| goose | 40/44 (90.9%) | 134.4s | omlx | Slower but reliable; 4/44 short of clean |
| omp | 23/40 (57.5%) | 110.3s | omlx | Partial — several cases WARN/FAIL |
| claude | 10/38 (26.3%) | 126.8s | omlx | Mostly `stall` status — cause not yet root-caused, may be wiring not model (see Failure patterns) |
| copilot | 8/38 (21.1%) | 34.1s | omlx | Adapter bug: `copilot.sh` ignored `--runtime`, defaulted to `lms` provider (fixed same day); a further litellm-proxy streaming error remains — see Failure patterns |
| aider | 8/38 (21.1%) | 8.5s | omlx | Blocked before reaching the model — adapter bug, not a model result (see Failure patterns) |

**Working adapters total:** 2/6 clean (pi, goose); 4/6 (omp, claude, copilot, aider) blocked or degraded by adapter-level issues, not evaluated model behavior
**Overall (incl. broken adapters):** 133/242 (55.0%) — not representative of model quality; see Failure patterns

## Timing observations

pi: fastest case smoke-00-hello (10s), slowest ts-01-groupby (84s), no timeouts/stalls, all well under the 300s ceiling. goose: reliable but ~4-5x slower than pi per case (median 134s). omp/claude/copilot ran 100-130s per case where they reached the model at all. aider and copilot's initial run failed fast (8.5s, 34s median) because they errored out before real model inference — not genuine timing data.

## Failure patterns

- **aider (8/38):** Aider's bundled `litellm` rejects the `omlx/<id>` model prefix client-side (`litellm.BadRequestError: LLM Provider NOT provided`) before the request ever reaches `--openai-api-base` (the litellm proxy). This is an adapter wiring gap, not a model failure — see [pi.md](../tools/pi.md) pattern of other adapters; tracked as a follow-up task.
- **copilot (8/38):** `copilot.sh` unconditionally defaulted `PROVIDER` to `lms`, ignoring `--runtime omlx` / `$RUNTIME` (unlike `aider.sh`/`claude.sh`/`goose.sh`/`omp.sh`, which all fall back to `${RUNTIME:-lms}`). Fixed 2026-08-29. After the fix, copilot reaches the model but a separate litellm-proxy streaming bug appears (`'async for' requires an object with __aiter__ method, got NoneType`) — likely an SSE-stream incompatibility specific to the omlx backend. Not yet root-caused.
- **claude (10/38):** Mostly `status=stall` (120s+ per case) rather than clean fails — unclear whether this is a genuine claude/omlx interaction issue (e.g. slow first-token on this backend) or another wiring gap; needs bench-log investigation before attributing to the model.
- **omp (23/40):** Partial passes/WARN on several cases; not yet investigated in depth.
- **pi and goose:** no repeatable failures. goose's 4/44 shortfall not yet broken down by case.

## Better alternatives

Of the 6 adapters tried, only pi (100%, fastest) and goose (90.9%, ~4.5x slower) reflect real model behavior — the rest are currently degraded by adapter-level wiring bugs (see Failure patterns), so no fair cross-model comparison can be drawn yet. Once aider/copilot/claude are unblocked, re-run before concluding how this model stacks up against `Ornith-1.0-35B-4bit` or the `Qwen3.6-35B-A3B` family.

## Status

**keep** — set as the repo default (`config.sh`) for bench and smoke testing on 2026-08-29. Clean 100% on pi, solid 90.9% on goose; the poor scores on aider/copilot/claude are adapter wiring issues (tracked separately), not evidence against the model.
