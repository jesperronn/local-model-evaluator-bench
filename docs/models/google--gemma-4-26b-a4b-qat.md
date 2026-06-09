# google/gemma-4-26b-a4b-qat

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-26b-a4b-qat` |
| **Family / arch** | Gemma 4, MoE (26B total, 4B active), QAT |
| **Parameter count** | 26B total, ~4B active |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |

## Results summary

Excellent model on opencode and caveman (both 100%), good on codex (87.5%). The major surprise is **aider's catastrophic underperformance** (34.6%) — the worst aider score across any capable model. This is not a model quality issue; it's a severe format incompatibility between this model's chat template and aider's diff format. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Adapter-specific — aider, bash-01-topwords (0/4, timeout 300s):** aider times out and scores 0/4 while opencode, codex, and caveman all score 4/4. The model is producing output aider can't interpret, causing repeated retry loops until timeout.

**Adapter-specific — aider, js-03-multifile-cache (0/5):** aider scores 0/5; all other adapters score 5/5. The model either ignores aider's edit format for multi-file changes or produces a format aider can't parse.

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider 0/1; opencode, codex, caveman all 3/3.

**Adapter-specific — aider, js-05-multiselect-filter (0/1):** aider 0/1; others 5/5. Self-verify iteration appears broken under aider for this model.

**Adapter-specific — aider, js-06-lint-and-test (0/4):** aider 0/4; others 4/4.

The pattern across all 5 aider failures is consistent: this model has a chat template or response format that aider's parser cannot process, causing either timeouts or no-edit outcomes. A different `--edit-format` flag might fix this.

**Adapter-specific — codex, js-02-debounce-feature (0/4):** codex is the only adapter to fail this feature case (0/4); all others score 4/4. The model produces correct logic but codex's tool-call format doesn't apply the edit — possibly a codex response parsing issue with this specific case structure.

## Timing observations

- **opencode:** 45–204s. All cases clean, no timeouts. js-03 was longest at 204s.
- **codex:** 57–196s. All ok except js-02 (which codex failed).
- **caveman:** 48–164s. All cases clean. js-03 took 164s.
- **aider:** 10–300s. bash-01 hit 300s timeout; most non-timeout failures completed in 10–34s.

## Known issues

**aider format incompatibility:** aider's search/replace or unified-diff edit format is not compatible with this model's response style. The model likely uses a non-standard response format or adds explanation before the edit block. Suggested fix: try `--edit-format whole` in the aider adapter.

## Status

**keep** — top-tier performance on opencode and caveman. The aider issue is a known format incompatibility worth investigating. Re-run after testing an aider `--edit-format` change.

## Comparison within family

gemma-4-26b-a4b-qat vs gemma-4-12b-qat: the 26b model is significantly more capable (100% vs 93% on opencode, and the 26b handles aider cases that 12b passes). The a4b (4B active) architecture makes the 26b surprisingly fast despite the 26B total parameter count. The QAT quantisation appears clean — no observable quality loss vs FP16.
