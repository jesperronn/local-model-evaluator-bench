# google/gemma-4-31b-qat

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 7.1% (all adapters) |
| **Speed (avg)** | measured pending |
| **Best adapter** | measured pending |
| **Recommended for** | smoke test only |
| **Status** | avoid |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Status** | AVOID — broken tool calling (7.1%, smoke test only) |
| **Model key** | `google/gemma-4-31b-qat` |
| **Family / arch** | Gemma 4, 31B, QAT |
| **Parameter count** | 31B |
| **Disk size** | measured pending |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |
| **Doc updated** | 2026-06-09 |

## Results summary

Identical failure pattern to google/gemma-4-31b. No usable benchmark data. All adapters score near-zero in 1–5s, with js-01-slugify-bug consistently scoring 2/4 across all adapters. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Timing observations

measured pending

## Failure patterns

Same as google/gemma-4-31b: the 2/4 on js-01 across all adapters is the only non-zero result. The pattern is consistent with a model that responds but does not follow coding-agent instructions. The QAT model exhibits the same failure mode as the fp16 31b, which further suggests a model-key or variant mismatch rather than a quality issue.

## Known issues

**Likely not an instruct variant (same as fp16 31b):** both the fp16 and QAT 31b models exhibit identical near-zero patterns. This is very unlikely to be a coincidence — both model keys probably resolve to non-instruct or incorrectly configured variants.

## Better alternatives

None identified (model is likely non-instruct)

## Status

**avoid** — broken tool calling. Identical pattern to `google/gemma-4-31b`: 2/28 (7.1%) on all adapters, zero real tool calls succeed. The fact that both the fp16 and QAT 31b variants show exactly the same failure pattern makes a model-key/variant mismatch extremely likely — both probably point to non-instruct checkpoints.

**Cleanup:** remove `google/gemma-4-31b-qat` from `models.txt` alongside `google/gemma-4-31b`. Only re-add after verifying the key resolves to an instruction-tuned QAT variant and `bin/smoke` confirms all adapters can reach it.

See also: [Models to Avoid in LEADERBOARD.md](../../LEADERBOARD.md#models-to-avoid)
