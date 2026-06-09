# google/gemma-4-e2b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-e2b` |
| **Family / arch** | Gemma 4, MoE (effective 2B active) |
| **Parameter count** | ~2B active (total MoE params <!-- TODO -->) |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |

## Results summary

The weakest reliably-working model in the suite — though it still achieves 90% on opencode, making it usable for code tasks if memory is very constrained. aider (68%) and caveman (78%) are functional. codex scores only 37% due to systematic failures on feature/multi-file cases. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Cross-adapter — js-03-multifile-cache (fail everywhere):** aider 0/1, opencode 0/1, codex 0/5, caveman 0/1. The 2B active parameter count is too small to reliably track two files in context. The model applies one edit and loses the other.

**Adapter-specific — opencode, js-04-multifile-rename (0/1):** opencode fails; caveman passes (3/3), as does aider... wait, aider 0/1 — actually aider also fails. Let me correct: aider 0/1, opencode 3/3, codex 0/1, caveman 0/1. opencode is the only adapter that passes js-04-multifile-rename. This is an opencode-strength case where its multi-file prompting outperforms other adapters for this model.

**Adapter-specific — codex, js-02-debounce-feature (0/4):** codex fails (0/4) while aider scores 4/4 and opencode 3/4. The model produces valid debounce logic but codex's parsing fails.

**Adapter-specific — codex, ts-01-groupby (0/3):** codex fails while aider, opencode, caveman all score 3/3.

**Adapter-specific — caveman, js-02-debounce-feature (0/1):** caveman fails (0/1) while aider scores 4/4 and opencode 3/4. The model's response to caveman's compact prompt style doesn't produce a working debounce implementation.

**Soft failure — bash-01 across adapters:** aider 0/4, opencode 3/4, codex 0/4, caveman 3/4. The model partially handles the bash pipeline but misses edge cases. Only opencode and caveman get 3/4.

**Adapter-specific — aider, js-05-multiselect-filter (0/1):** aider fails the self-verify case (0/1) while opencode, codex, caveman score 5/5. The model doesn't iterate under aider.

## Timing observations

- **aider:** 5–57s. Fastest adapter; js-05 at 57s.
- **opencode:** 10–80s. js-03 at 80s.
- **codex:** 5–65s.
- **caveman:** 4–96s. js-03 at 96s (though it failed).

## Known issues

None beyond the intrinsic 2B-active parameter constraint.

## Status

**keep** — useful as a baseline for the minimum-capability tier. The fp16 variant; compare against gemma-4-e2b-qat to evaluate QAT impact.

## Comparison within family

gemma-4-e2b vs gemma-4-e2b-qat: both sit at similar overall scores. The QAT variant shows marginally better results on opencode (87.5% vs 90%) but slightly worse on caveman. At the 2B scale, the two variants are close enough that the choice should be based on RAM fit and desired inference precision. See gemma-4-e2b-qat page for details.
