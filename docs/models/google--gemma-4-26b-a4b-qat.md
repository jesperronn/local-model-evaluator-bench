# google/gemma-4-26b-a4b-qat

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `google/gemma-4-26b-a4b-qat` |
| **Family / arch** | Gemma 4, MoE (26B total, 4B active), QAT |
| **Parameter count** | 26B total, ~4B active |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-29 LMS (run `20260629-103716`); 2026-06-13 Ollama |
| **Doc updated** | 2026-06-30 |

## Results summary

Strong across all runtimes. On the 2026-06-29 LMS overnight run: goose, hermes, and pi all scored **38/38 (100%)**; interpreter 37/38 (97%); opencode 37/38 (97%); cline 34/38 (89%); openhands 30/36 (83%); aider 31/38 (81%). codex SKIPPED (in compat.json). Overall 313/366 (85%); **91% excluding LMS-broken adapters**. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

| Adapter | 2026-06-29 (LMS) | Ollama (2026-06-13) | MLX |
|---------|-----------------|---------------------|-----|
| goose | 38/38 (100%) | — | — |
| hermes | 38/38 (100%) | broken (tool schema) | 34/34 (100%) |
| pi | 38/38 (100%) | — | — |
| interpreter | 37/38 (97%) | — | — |
| opencode | 37/38 (97%) | 34/34 (100%) | — |
| cline | 34/38 (89%) | — | — |
| openhands | 30/36 (83%) | — | — |
| aider | 31/38 (81%) | 15/28 (53.6%) | — |
| caveman | 12/32 (37%) | 26/28 (92.9%) | — |
| copilot | 18/32 (56%) | — | — |
| codex | SKIPPED | 32/34 (94.1%) | — |

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

## Observations across runs

### 2026-06-29 — LMS overnight (run `20260629-103716`)

Full 11-adapter LMS sweep. goose/hermes/pi: 100%. interpreter/opencode: 97%. Significant improvement vs 2026-06-13 Ollama results on aider (81% LMS vs 53.6% Ollama) — the LMS runtime and/or adapter updates appear to have fixed the multifile cases that previously failed. caveman remains LMS-incompatible (12/32). copilot scored 18/32 (56%) — slightly above the 37% baseline, suggesting a few cases partially succeed. codex remains skipped per compat.json.

## Status

**keep** — top-tier performance across all tested LMS adapters. goose/hermes/pi at 100% on LMS, interpreter/opencode at 97%. The aider multifile issue that plagued the Ollama run appears resolved on LMS. codex excluded by compat.json.

## Comparison within family

gemma-4-26b-a4b-qat vs gemma-4-12b-qat: the 26b model is significantly more capable (100% vs 93% on opencode, and the 26b handles aider cases that 12b passes). The a4b (4B active) architecture makes the 26b surprisingly fast despite the 26B total parameter count. The QAT quantisation appears clean — no observable quality loss vs FP16.
