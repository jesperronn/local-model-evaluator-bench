# google/gemma-4-26b-a4b (MLX 6-bit)

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `gemma4-26b-6bit` (alias, MLX only) |
| **Family / arch** | Gemma 4, MoE (26B total, 4B active) |
| **Parameter count** | 26B total, ~4B active |
| **Disk size** | <!-- TODO --> |
| **Quantization** | MLX 6-bit (non-QAT) |
| **Added** | 2026-06-13 |
| **Last run** | <!-- TODO --> |
| **Doc updated** | 2026-06-13 |

## Results summary

Not yet benchmarked. This is the non-QAT 6-bit MLX quantization of gemma-4-26B-A4B-it.
Compare against gemma4-26b-qat (QAT MLX 4-bit) and gemma4:26b-mlx (Ollama nvfp4) to
evaluate quantization impact. 6-bit non-QAT should offer the highest output quality
at the cost of slightly more RAM vs 4-bit QAT.

## Failure patterns

<!-- TODO: populate after first bench run -->

## Timing observations

<!-- TODO: populate after first bench run -->

## Known issues

MLX only — no LMS or Ollama variant. Run with:

```
bin/bench --runtime mlx --model gemma4-26b-6bit --tool hermes --timeout 450
```

## Status

**pending** — not yet benchmarked. In MLX test queue.

## Comparison within family

- `gemma4-26b-qat` (QAT MLX 4-bit): same arch, lower bit depth but QAT-calibrated
- `gemma4:26b-mlx` (Ollama nvfp4): same arch, Ollama runtime
- `google/gemma-4-26b-a4b-qat` (LMS): same weights as QAT variant, LM Studio runtime
