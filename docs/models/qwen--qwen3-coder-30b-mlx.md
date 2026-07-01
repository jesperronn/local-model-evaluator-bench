# Qwen3-Coder-30B-A3B-Instruct-MLX-4bit (mlx_lm.server)

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 88.2% across aider+pi |
| **Speed (avg)** | ~64s per case (aider) |
| **Best adapter** | aider — 97.1% accuracy |
| **Recommended for** | agentic coding with aider |
| **Status** | keep |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata


| Field | Value |
|-------|-------|
| **Model key** | `/Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit` |
| **Runtime** | `mlx` (mlx_lm.server at localhost:8080) |
| **Family / arch** | Qwen3-Coder, MoE (30B total, ~3B active) |
| **Quantization** | MLX 4-bit |
| **Added** | 2026-06-21 |
| **Last run** | 2026-06-21 |
| **Doc updated** | 2026-06-21 |

## Results summary

aider is the standout adapter — **97.1% (33/34)** — the best mlx result in the suite.
pi reaches **79.4% (27/34)** but has a structural hello/create-from-scratch failure.
Overall mlx runtime for this model: **88.2%** across aider+pi.

| Adapter | Score | Median s | Notes |
|---------|-------|----------|-------|
| aider | 33/34 **97.1%** | 64s | Only js-05-multiselect-filter failed |
| pi | 27/34 **79.4%** | 59s | hello + ts-01 fail (tool call format) |
| hermes | 31/38 81.6% | 200s | hello fails; edit cases pass |
| cline | 4/6 66.7% | 87s | smoke only; hello fails |
| opencode | 2/6 33.3% | 235s | smoke only; hello + numbers timeout |

Compare to the same weights via LMS (`lms` runtime): hermes achieves **100%** there,
because LMS normalises the model's tool call output. Via raw mlx_lm.server, hermes drops
to 81.6% — the difference is the tool call format issue below.

## Failure patterns

**Hermes-format text tool calls (structural):** When asked to create a file from scratch,
this model outputs `<function=write_file><parameter=path>...</parameter>...</function>`
as plain text instead of a proper OpenAI JSON tool call. The file is never created.

Affects: any adapter that relies on OpenAI tool-call protocol for file writes
(hermes, cline, opencode, pi). Aider is immune because it uses diff/patch format;
pi edit cases pass because they patch existing files.

Reproducer: `smoke-00-hello` (create hello.txt), `ts-01-groupby` (create new .ts file).

**js-05-multiselect-filter (all adapters):** Both aider and pi scored 0/1 — this case
appears to be genuinely hard for this model regardless of adapter.

**pi: fast 6s errors on hello and ts-01:** pi exits in 6–14s on create-from-scratch
cases; the model returns quickly but pi cannot execute the hermes text tool call,
so the original stub remains and all grader checks fail.

## Timing observations

- **aider:** 21–183s; very fast on simple tasks (js-01 slugify: 21s), slower on multi-file (js-03: 183s).
- **pi:** 17–183s; similar range, slightly faster on edit-only tasks.
- **mlx_lm.server throughput:** noticeably faster than Ollama for same weights —
  40–65s median vs 180–240s for comparable Ollama tasks.

## Known issues

**`mlx_lm.server --model` must match exactly:** Pass the full local path as MODEL_ID
in requests. A mismatched or short name causes HuggingFace fetch attempts (401).

**`/v1/models` endpoint crashes:** HF_HUB_CACHE path doesn't exist; the `/v1/models`
endpoint throws `CacheNotFound`. Health check (`GET /`) returns 200 and completions
work normally — only the models-list endpoint is broken.

**Startup:** Use `mlx_lm.server`, not `python -m mlx_lm.server` (python not in PATH).

## Status

**keep** — aider-mlx is a top-tier combination worth tracking. The tool call format
issue limits other adapters but is a model/server characteristic, not a bench bug.

## Better alternatives

vs `qwen/qwen3-coder-30b` via LMS (same weights, different server):
- aider: mlx 97.1% vs lms 100% — nearly identical quality
- hermes: mlx 81.6% vs lms 100% — lms normalises tool call format, mlx_lm.server does not
- Speed: mlx_lm.server ~64s median vs lms ~14s for aider (LMS is faster for single-adapter runs)

## Comparison
