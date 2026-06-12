# google/gemma-4-12b-qat

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-12b-qat` |
| **Family / arch** | Gemma 4, dense, 12B, QAT |
| **Parameter count** | 12B |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |
| **Removed** | 2026-06-10 |
| **Doc updated** | 2026-06-12 |

## Results summary

Mixed results with a strong opencode/caveman profile but significant timeout issues across all adapters. opencode and caveman lead at 93% and 96% respectively. aider is poor (34.6%) primarily due to a js-02 timeout and a string of multi-file/self-verify failures. codex is mediocre (53%) and produces many timeouts. The model is genuinely slow — median case time is 138s across adapters, the highest in the suite. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Cross-adapter — slowness causing timeouts:** nearly every adapter hits at least one 300s timeout. Cases completing correctly often do so at 200–300s. This is a model capability issue: the 12B dense model generates tokens more slowly than MoE models with similar active-parameter counts.

**Adapter-specific — aider, js-02-debounce-feature (0/4, timeout):** aider times out on js-02 while opencode, codex, and caveman all pass 4/4. The model is mid-generation when the 300s timer fires.

**Adapter-specific — aider, multiple failures:** aider fails js-03, js-04, js-05, js-06 — the same multi-file and self-verify pattern seen on other models, but here compounded by slowness. Several failures are likely timeouts rather than model incapability.

**Adapter-specific — codex, bash-01 (0/4, timeout) and js-01 (2/4, timeout):** codex times out on bash-01 and js-01. Both hit 300s but the model hasn't produced output. Codex's multi-turn conversation overhead may be too slow for this model's generation speed.

**Soft failure — opencode, js-06-lint-and-test (0/2, timeout):** opencode times out on the lint self-verify case. The model starts iterating but doesn't converge within 300s.

**Caveman lingering — js-03, js-05 (timeout, but passing):** caveman scores 0/1 on js-03 (genuine failure) and 5/5 on js-05 (correct result, lingered 300s). The js-05 timeout is a caveman exit issue, not a model failure.

## Timing observations

The model is uniformly slow: 70–300s per case on most adapters. The QAT quantisation doesn't appear to have compensated for the 12B dense architecture's token generation speed. Compared to gemma-4-26b-a4b-qat (4B active, similar quality), the 12b-qat is 2–4× slower.

## Known issues

**Consistent timeout pressure:** the 300s default timeout is too tight for this model on codex. Consider `--timeout 600` for codex+12b-qat runs, or accept that codex results will be unreliable.

## Status

**removed 2026-06-10** — dropped from `models.txt` because `qwen/qwen3.5-9b` is strictly better: 87% vs 75% accuracy, 81s vs 173s average time, and smaller (9B vs 12B). The GGUF backend running via llama.cpp on LM Studio is the likely cause of the slowness — a native MLX 12B Gemma would probably close the speed gap, but the accuracy gap is a genuine model-capability difference. No MLX variant is currently downloaded.

**Better alternative:** `qwen/qwen3.5-9b` (MLX-4bit) — faster, more accurate, smaller footprint.

## Comparison within family

gemma-4-12b-qat vs gemma-4-26b-a4b-qat: the 26b model has a 4B active MoE architecture that is faster and scores higher. The 12b-qat only makes sense if the 26b is unavailable or RAM is severely constrained (the 12b takes substantially less memory). If both fit in VRAM, prefer 26b-a4b-qat.
