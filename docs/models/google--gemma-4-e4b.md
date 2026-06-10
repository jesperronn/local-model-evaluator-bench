# google/gemma-4-e4b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-e4b` |
| **Family / arch** | Gemma 4, MoE (effective 4B active) |
| **Parameter count** | ~4B active (total MoE params <!-- TODO -->) |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |

## Results summary

Mid-tier model with an uneven adapter profile. opencode and caveman score 72–74%, aider scores 77%, while codex is the weakest at 46%. The model struggles with multi-file cases (js-03, js-04) across all adapters, and codex specifically fails several self-verify and feature cases. Notably weaker than its QAT sibling (gemma-4-e4b-qat) on codex and caveman. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Cross-adapter — js-03-multifile-cache (partial/fail everywhere):** aider 0/1, opencode 2/5, codex 0/5, caveman 2/5. No adapter passes this case cleanly. The model has a genuine multi-file context tracking weakness — it either misses one file or produces inconsistent edits.

**Adapter-specific — codex, js-02-debounce-feature (0/4):** codex fails while aider and opencode score 4/4 and caveman scores 0/4. The model's output format doesn't parse correctly for codex and caveman on this feature case.

**Adapter-specific — codex, js-05-multiselect-filter (0/1):** codex fails the self-verify filter case; aider, opencode, caveman all score 5/5. Codex's test-and-iterate loop is less effective with this model.

**Adapter-specific — codex, ts-01-groupby (0/3):** codex fails the TypeScript groupBy case; all other adapters score 3/3. This is a codex-specific failure — the model produces valid TypeScript but codex doesn't apply or run it correctly.

**Adapter-specific — caveman, js-02-debounce-feature (0/4):** caveman fails js-02 alongside codex while aider and opencode pass. The feature's prompt may require a style of response that caveman's compact format doesn't elicit well for this model.

**Soft failures — bash-01 across all adapters:** aider 0/4, opencode 1/4, codex 3/4, caveman 1/4. The model partially handles the bash pipeline case but misses edge cases (likely word boundary or locale sort differences).

## Timing observations

- **aider:** 16–108s. js-05 (self-verify) took longest at 108s.
- **opencode:** 24–149s. js-05 took 149s.
- **codex:** 36–263s. js-05 at 263s (though it failed).
- **caveman:** 37–122s.

## Known issues

None beyond the multi-file weakness which appears to be intrinsic to the fp16 model.

## Status

**removed** (2026-06-10) — scored 70.1% overall. Multi-file failures (js-03, js-04) are cross-adapter and match the QAT sibling's pattern, so this reflects genuine 4B-active capacity rather than misconfiguration. The fp16 model is also marginally worse than the QAT variant on most adapters, giving it no advantage. Removed from `models.txt` alongside gemma-4-e4b-qat.

## Comparison within family

gemma-4-e4b vs gemma-4-e4b-qat: the QAT variant outperforms the fp16 on caveman (76.9% vs 68.8%) and opencode. The e4b-qat is generally preferable. If QAT produces visible artefacts on specific outputs, keep e4b as a fallback.
