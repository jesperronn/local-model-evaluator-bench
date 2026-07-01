# google/gemma-4-31b

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | measured pending |
| **Speed (avg)** | measured pending |
| **Best adapter** | measured pending |
| **Recommended for** | measured pending |
| **Status** | avoid |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-31b` |
| **Family / arch** | Gemma 4, measured pending, 31B (fp16) |
| **Parameter count** | 31B |
| **Quantization** | fp16 |
| **Disk size** | measured pending |
| **Context window** | measured pending |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |
| **Doc updated** | 2026-06-09 |


## Results summary

No usable benchmark data. All adapters score near-zero across all cases in 1–5s, with the exception of js-01-slugify-bug which consistently scores 2/4 (all adapters). All other cases score 0. This is not a capability assessment — the pattern is characteristic of a model that is connected but not generating meaningful code edits. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Cross-adapter near-zero (all cases except js-01):** every adapter, every case (except js-01) scores 0 in under 5 seconds. The js-01 score of 2/4 across all adapters suggests the model is responding — the first two sub-tests of js-01 may pass trivially (e.g. the model returns the function body which passes basic checks) while the edge cases fail. This pattern suggests the model is not in coding/instruction-following mode, possibly due to a missing or mismatched system prompt, or the model key pointing to a base (non-instruct) variant.

## Known issues

**Likely not an instruct variant:** the uniform 0 scores with fast response times and the 2/4 on js-01 suggest the model responds but doesn't follow the edit-file instructions. Check whether `google/gemma-4-31b` in LM Studio refers to a base model rather than the instruction-tuned variant.

## Timing observations

measured pending

## Better alternatives

measured pending

## Status

**avoid** — broken tool calling. Scores 2/28 (7.1%) across all adapters — the only passes are the trivial first two sub-checks of `js-01-slugify-bug` (basic text output). Zero real tool calls succeed. The near-identical failure pattern on both the fp16 and QAT 31b variants rules out a random infrastructure fault; the most likely cause is a non-instruct or misconfigured model variant. Do not use for agentic coding work.

**Cleanup:** remove `google/gemma-4-31b` from `models.txt` and unload from LM Studio. If you want a verified instruct variant, check the LM 

