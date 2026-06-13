# google/gemma-4-26b-a4b-qat

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-26b-a4b-qat` |
| **Family / arch** | Gemma 4, MoE (26B total, 4B active), QAT |
| **Parameter count** | 26B total, ~4B active |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-13 (Ollama) |
| **Doc updated** | 2026-06-13 |

## Results summary

Strong across all runtimes. LMS: hermes 100%, caveman 100%, codex 100%. Ollama: opencode 100%, codex 94.1%, caveman 92.9%, aider 53.6% (multifile cases fail — known format incompatibility). hermes on Ollama is broken (Gemma doesn't recognize terminal tool in Ollama's schema format; LMS hermes works fine). MLX hermes 100%. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

| Adapter | LMS | Ollama | MLX |
|---------|-----|--------|-----|
| hermes | 34/34 100% | broken (tool schema) | 34/34 100% |
| opencode | — | 34/34 100% | — |
| codex | 34/34 100% | 32/34 94.1% | — |
| caveman | 34/34 100% | 26/28 92.9% | — |
| aider | ~50% (timeout on bash-01) | 15/28 53.6% | — |

## Failure patterns

**Adapter-specific — aider, bash-01-topwords (0/4, timeout 300s):** aider times out and scores 0/4 while opencode, codex, and caveman all score 4/4. The model is producing output aider can't interpret, causing repeated retry loops until timeout.

**Adapter-specific — aider, js-03-multifile-cache (0/5):** aider scores 0/5; all other adapters score 5/5. The model either ignores aider's edit format for multi-file changes or produces a format aider can't parse.

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider 0/1; opencode, codex, caveman all 3/3.

**Adapter-specific — aider, js-05-multiselect-filter (0/1):** aider 0/1; others 5/5. Self-verify iteration appears broken under aider for this model.

**Adapter-specific — aider, js-06-lint-and-test (0/4):** aider 0/4; others 4/4.

The pattern across all 5 aider failures is consistent: this model has a chat template or response format that aider's parser cannot process, causing either timeouts or no-edit outcomes. A different `--edit-format` flag might fix this.

**Adapter-specific — codex, js-02-debounce-feature (0/4):** codex is the only adapter to fail this feature case (0/4); all others score 4/4. The model produces correct logic but codex's tool-call format doesn't apply the edit — possibly a codex response parsing issue with this specific case structure.

## Timing observations

- **hermes (LMS):** ~56s avg. Clean on all 9 cases.
- **hermes (MLX 4-bit QAT):** 13–253s, avg 132s. 34/34 100%. No cold-start JIT (4B active MoE). 2 transient tool-call truncation warnings (both self-recovered).
- **opencode (Ollama):** 45–237s, avg 125s. All 9 cases clean, 34/34.
- **codex (LMS):** 57–196s. 34/34 100%.
- **codex (Ollama):** 72–167s, avg 116s. 32/34 94.1%. smoke-00-hello 0/2 (3s fast fail).
- **caveman (LMS):** 48–164s. 34/34 100%.
- **caveman (Ollama):** 46–242s, avg 106s. 26/28 92.9%. js-04/js-05 fail (import error collapses tests to 1).
- **aider (Ollama):** 12–879s, avg 166s. 15/28 53.6%. bash-01 passes (4/4, 177s). All 4 multifile cases (js-03–js-06) fail.

## Known issues

**aider multifile incompatibility:** aider fails all 4 multifile cases (js-03–js-06) on both LMS and Ollama. Single-file cases mostly pass. Suggested fix: try `--edit-format whole` in the aider adapter.

**hermes on Ollama is broken:** the model says "terminal tool appears to be unavailable in this session" and produces no edits. This is a Gemma-specific behavior with the Ollama tool schema format — LMS hermes works fine (100%). Do not use `hermes` adapter for this model on Ollama runtime.

## Status

**keep** — top-tier performance on opencode and caveman. The aider issue is a known format incompatibility worth investigating. Re-run after testing an aider `--edit-format` change.

## Comparison within family

gemma-4-26b-a4b-qat vs gemma-4-12b-qat: the 26b model is significantly more capable (100% vs 93% on opencode, and the 26b handles aider cases that 12b passes). The a4b (4B active) architecture makes the 26b surprisingly fast despite the 26B total parameter count. The QAT quantisation appears clean — no observable quality loss vs FP16.
