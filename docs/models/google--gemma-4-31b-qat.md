# google/gemma-4-31b-qat

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-31b-qat` |
| **Family / arch** | Gemma 4, <!-- TODO: dense or MoE? -->, 31B, QAT |
| **Parameter count** | 31B |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |
| **Doc updated** | 2026-06-09 |

## Results summary

Identical failure pattern to google/gemma-4-31b. No usable benchmark data. All adapters score near-zero in 1–5s, with js-01-slugify-bug consistently scoring 2/4 across all adapters. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

Same as google/gemma-4-31b: the 2/4 on js-01 across all adapters is the only non-zero result. The pattern is consistent with a model that responds but does not follow coding-agent instructions. The QAT model exhibits the same failure mode as the fp16 31b, which further suggests a model-key or variant mismatch rather than a quality issue.

## Known issues

**Likely not an instruct variant (same as fp16 31b):** both the fp16 and QAT 31b models exhibit identical near-zero patterns. This is very unlikely to be a coincidence — both model keys probably resolve to non-instruct or incorrectly configured variants.

## Status

**rerun** — same status as gemma-4-31b. Verify the model key resolves to an instruct-tuned QAT variant and re-run after `bin/smoke` confirmation. If the 31b key issue is resolved for the fp16 variant, rerun both.
