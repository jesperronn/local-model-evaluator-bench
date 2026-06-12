# google/gemma-4-e4b-qat

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-e4b-qat` |
| **Family / arch** | Gemma 4, MoE (effective 4B active), QAT |
| **Parameter count** | ~4B active (total MoE params <!-- TODO -->) |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |
| **Doc updated** | 2026-06-10 |

## Results summary

The better of the two e4b variants. caveman leads at 76.9%, opencode at 74.1%, aider at 61.5%, codex at 54.5%. The QAT quantisation gives a measurable improvement over the fp16 model, particularly on caveman. codex remains weak due to multi-file and self-verify failures. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Cross-adapter — bash-01-topwords (partial everywhere):** aider 1/4, opencode 1/4, codex 1/4, caveman 0/4. No adapter gets more than 1/4 on the bash pipeline case. The model has a genuine weakness with multi-step shell pipelines — likely struggles with the `sort | uniq -c | sort -rn | head` pattern or locale-sensitive word splitting.

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider fails; opencode, codex, caveman all pass 3/3. Standard aider multi-file format issue.

**Adapter-specific — opencode, ts-01-groupby (0/1):** opencode fails the TypeScript groupBy case (0/1) while aider, codex, caveman all score 3/3. The model's response format for TypeScript generics may not match opencode's expected output.

**Adapter-specific — caveman, ts-01-groupby (0/1):** caveman also fails ts-01 alongside opencode. aider and codex both pass. The compact caveman prompt may under-specify the TypeScript generic constraint for this model.

**Cross-adapter — js-03-multifile-cache (fail on 3 of 4):** aider 0/5, opencode 5/5 (only opencode passes), codex 0/1, caveman 0/1. The model can handle this case (opencode proves it) but only under opencode's prompting style.

**Adapter-specific — codex, js-05 (0/1) and js-02 (0/4):** codex fails both the self-verify filter and the debounce feature. The model's output under codex's prompting doesn't match the expected format for these cases.

## Timing observations

- **aider:** 8–36s. Fast for a 4B-active model.
- **opencode:** 21–110s. js-03 took 110s (the one case opencode solved).
- **codex:** 11–283s. js-05 took 283s (failed). Overall slow for the effort.
- **caveman:** 12–100s. js-06 took 100s.

## Known issues

None beyond intrinsic model limitations.

## Status

**removed** (2026-06-10) — scored 71.1% overall. Despite being the stronger of the two e4b variants, 71% is below the utility threshold for agentic workloads when 30B+ MoE models fit in comparable memory. The bash-01 cross-adapter failure (≤1/4 on every adapter) and js-03 failures confirm this is a parameter-scale ceiling, not a configuration issue — the fp16 sibling has identical failure cases. Removed from `models.txt` alongside gemma-4-e4b.

**Alternative:** `qwen/qwen3.5-9b` (6.0 GB, **0.1 GB smaller** than this model's 6.1 GB) scores **87.0%** vs 71.1% here — a 16 pp gain at virtually identical disk footprint. It runs slower (80 s avg vs 64 s avg), but the accuracy jump for the same RAM budget makes this a clear swap with no trade-off.

## Comparison within family

gemma-4-e4b-qat vs gemma-4-e4b: QAT variant is consistently better — higher scores on caveman and opencode, same quality on aider. The QAT is the preferred variant. For the e4b size class, prefer this model over the fp16.
