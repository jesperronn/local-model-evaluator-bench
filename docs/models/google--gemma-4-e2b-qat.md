# google/gemma-4-e2b-qat

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-e2b-qat` |
| **Family / arch** | Gemma 4, MoE (effective 2B active), QAT |
| **Parameter count** | ~2B active (total MoE params <!-- TODO -->) |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |

## Results summary

Marginally stronger than the fp16 sibling on opencode (87.5% vs 90%) but similar overall. opencode leads at 87.5%, aider at 77%, caveman at 50%, codex at 46%. The 2B active parameter count caps capability — multi-file and self-verify cases are consistently weak. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Cross-adapter — js-04-multifile-rename (fail everywhere):** aider 0/1, opencode 0/1, codex 0/1, caveman 0/1. A true cross-adapter failure — no adapter scores a point on this case. The model cannot reliably track two files and produce consistent renames. The ESM import in one file is never updated to match the rename in the other.

**Cross-adapter — bash-01-topwords (fail/partial everywhere):** aider 0/4, opencode 1/4, codex 0/4, caveman 0/4. The model cannot construct the full `tr | sort | uniq -c | sort -rn | head -N` pipeline correctly. Likely a reasoning gap on multi-step shell pipes at this parameter scale.

**Cross-adapter — js-03-multifile-cache (fail on 3 of 4):** aider 0/1, opencode 5/5 (passes!), codex 0/5, caveman 0/1. Only opencode passes. This is a narrow capability — the model can handle multi-file edits under opencode's prompting but fails with all other adapters.

**Adapter-specific — caveman, js-02-debounce-feature (0/4):** caveman fails; aider, opencode score 4/4. The compact caveman prompt doesn't elicit a working debounce implementation.

**Adapter-specific — caveman, ts-01-groupby (0/3):** caveman fails; others score 3/3. Same compact-prompt issue for TypeScript generics.

**Adapter-specific — codex, js-05-multiselect-filter (0/1):** codex fails; others score 5/5. Codex's self-verify loop doesn't converge for this model on this case.

## Timing observations

- **aider:** 4–64s. Fast; js-05 at 64s.
- **opencode:** 15–88s. js-06 at 88s.
- **codex:** 4–123s. js-06 at 123s.
- **caveman:** 7–47s.

## Known issues

None beyond intrinsic 2B-active limitations.

## Status

**removed** (2026-06-10) — scored 65.5% overall, the lowest of any active model. This is lower than the fp16 sibling (72.1%), confirming QAT hurts at the 2B scale rather than helping. The failure pattern is identical across every adapter (bash-01, js-03, js-04 fail everywhere) — consistent with intrinsic parameter-scale limits, not a configuration gap. Removed from `models.txt` alongside gemma-4-e2b.

## Comparison within family

gemma-4-e2b-qat vs gemma-4-e2b: QAT shows marginal gains on some adapters and losses on others. At the 2B scale, QAT benefits are small. The key differentiator between e2b variants is RAM footprint — the QAT model uses less memory, making it preferable if the fp16 fits but is tight.
