# qwen3.6:35b-mlx

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | measured pending |
| **Speed (avg)** | measured pending |
| **Best adapter** | measured pending |
| **Recommended for** | measured pending |
| **Status** | watch |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen3.6:35b-mlx` (Ollama tag) |
| **Alias** | `qwen3.6-35b-mlx` |
| **Family / arch** | Qwen3.6, MoE (35B total, 3B active) |
| **Parameter count** | 35B total, 3B active |
| **Disk size** | measured pending |
| **Added** | 2026-06-18 |
| **Last run** | measured pending |
| **Doc updated** | 2026-06-30 |

## Context
...

MLX-quantized Ollama variant of the Qwen3.6 35B-A3B model. **Prefer this over
`qwen3.6:35b-a3b-coding-mxfp8` for Ollama runs** — smoke tests show it is ~3.3×
faster (24s avg vs 81s avg) with identical pass rates. The MLX quantization runs
natively on Apple Silicon GPU; the coding-mxfp8 variant does not benefit from the
same hardware path.

See [qwen--qwen3.6-35b-a3b.md](qwen--qwen3.6-35b-a3b.md) for results on the
lmstudio runtime (where both variants are equivalent).

## Results summary

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| measured pending | measured pending | measured pending | measured pending | measured pending |

**Working adapters total:** measured pending
**Overall (incl. broken adapters):** measured pending

## Timing observations

| Adapter | Speed (avg) | Case |
|---------|--------------|------|
| measured pending | measured pending | measured pending |

measured pending

## Better alternatives

none

## Failure patterns

none

## Status

**pending first run**
