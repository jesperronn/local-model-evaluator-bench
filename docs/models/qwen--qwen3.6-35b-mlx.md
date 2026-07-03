# qwen3.6:35b-mlx

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 85–100% across working adapters (interpreter 100%, opencode 95%, pi 92%, aider 91%, codex/hermes 89%, openhands 85%) |
| **Speed (avg)** | 45–129s/case depending on adapter (see Timing observations) |
| **Best adapter** | interpreter — only adapter to hit 100%; pi — fastest at 95.4s/case among 80%+ scorers |
| **Recommended for** | general agentic coding via Ollama when you want a model to stay resident across many trials |
| **Status** | keep |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen3.6:35b-mlx` (Ollama tag) |
| **Alias** | `qwen3.6-35b-mlx` |
| **Family / arch** | Qwen3.6, MoE (35B total, 3B active) |
| **Parameter count** | 35B total, 3B active |
| **Disk size** | measured pending |
| **Added** | 2026-06-18 |
| **Last run** | 2026-07-02 |
| **Doc updated** | 2026-06-30 |

## Context
...

MLX-quantized Ollama variant of the Qwen3.6 35B-A3B model. **Prefer this over
`qwen3.6:35b-a3b-coding-mxfp8` for Ollama runs** — smoke tests show it is ~3.3×
faster (24s avg vs 81s avg) with identical pass rates. The MLX quantization runs
natively on Apple Silicon GPU; the coding-mxfp8 variant does not benefit from the
same hardware path.

See [qwen--qwen3.6-35b-a3b.md](qwen--qwen3.6-35b-a3b.md) for results on the
lmstudio runtime (where both variants are equivalent).

## Results summary

Full 11-case / 38-check suite, run 2026-07-02 (see
[qwen--qwen3.6-35b-a3b.md § Cross-runtime comparison](qwen--qwen3.6-35b-a3b.md#cross-runtime-comparison-2026-07-02)
for the matched lms/mlx numbers on the same weights):

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| interpreter | 100% | 73.6s | ollama | only adapter to hit a perfect score here |
| opencode | 95% | 129.2s | ollama | slowest of the 80%+ scorers |
| pi | 92% | 95.4s | ollama | |
| aider | 91% | 72.5s | ollama | |
| codex | 89% | 45.3s | ollama | fastest of the 80%+ scorers |
| hermes | 89% | 83.5s | ollama | only adapter where Ollama beats lms on speed (83.5s vs 97.4s) |
| openhands | 85% | 126.5s | ollama | |
| cline | intermittent | — | ollama | passed individually, failed once in full sweep — flagged in `compat.json` |

**Working adapters total:** 7/9 tested cleared 85%+; cline intermittent.
**Overall:** no adapter reached 100% except interpreter — Ollama trails lms
(5 adapters at 100%) for this model.

## Timing observations

| Adapter | Speed (avg) | Case |
|---------|--------------|------|
| codex | 45.3s | fastest 80%+ scorer |
| hermes | 83.5s | js-05-multiselect-filter ran 222s, an outlier |
| aider | 72.5s | consistent 38–130s range |
| interpreter | 73.6s | slowest case bash-01-topwords at 160s (cold Python startup) |
| pi | 95.4s | |
| openhands | 126.5s | |
| opencode | 129.2s | slowest of adapters tested |

Ollama is consistently 1.4×–2.6× slower than lms per case for this model
(exception: hermes, where Ollama is slightly faster). See
[docs/runtimes/ollama.md](../runtimes/ollama.md) for the general pattern.

## Better alternatives

None identified for Ollama specifically. On lms, the same weights (via
`qwen/qwen3.6-35b-a3b`) score higher and faster across the board — prefer lms
when raw accuracy/speed matters more than keeping a model resident.

## Failure patterns

cline intermittent — passed a standalone smoke run but failed one case when
run as part of the full adapter sweep; not yet root-caused, flagged in
`compat.json` for tracking.

## Status

**keep** — confirm this is the right Ollama tag to use for qwen3.6-35b-a3b
weights (prefer over `qwen3.6:35b-a3b-coding-mxfp8`, see Context above).
