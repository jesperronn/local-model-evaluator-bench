# zai-org/glm-4.7-flash

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 41% overall (65% on codex) |
| **Speed (avg)** | ~300s per case (hits timeout floor) |
| **Best adapter** | codex — 65% accuracy |
| **Recommended for** | none (effectively unusable) |
| **Status** | drop |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `zai-org/glm-4.7-flash` |
| **Family / arch** | GLM-4.7 (Zhipu AI), dense transformer |
| **Parameter count** | 30B |
| **Context window** | 128K tokens |
| **License** | measured pending |
| **Disk size** | 24.36 GB (GGUF, lmstudio-community) |
| **Added** | 2026-06-28 |
| **Last run** | 2026-06-29 (run `20260629-173748`) |
| **Doc updated** | 2026-06-30 |

## Results summary

Effectively unusable for agentic tasks at the 300s timeout. codex is the only adapter with meaningful throughput (2spl/38, 65%); all other adapters score 37–43%, matching the timeout-floor baseline (smoke tests + one or two easy cases pass; everything else times out). Overall 147/358 (41%).

| Adapter | 2026-06-29 (LMS) | Notes |
|---------|-----------------|-------|
| codex | 25/38 (65%) | Only viable adapter — fewer round-trips per case |
| interpreter | 14/32 (43%) | Slightly above timeout floor |
| nanocoder | 12/34 (35%) | All 300s timeout; js-06 4/4 PASS (self-verify, multi-turn); timeout floor |
| aider | 12/32 (37%) | Timeout floor |
| caveman | 12/32 (37%) | LMS incompatible + too slow |
| cline | 12/32 (37%) | Timeout floor |
| copilot | 12/32 (37%) | LMS incompatible + too slow |
| goose | 12/32 (37%) | Timeout floor |
| hermes | 12/32 (37%) | Timeout floor |
| opencode | 12/32 (37%) | Timeout floor |
| openhands | 12/32 (37%) | Timeout floor |
| pi | 12/32 (37%) | Timeout floor |

The 12/32 floor represents adapters that pass only the 3 smoke tests plus the simplest 1-2 cases before hitting 300s timeouts. It is not partial capability — it is a hard wall at benchmark timeout.

## Timing observations

- **Slowest cases:** All cases hitting 300s timeout.
- **Note:** Token generation rate of ~1–3 tokens/sec on Apple Silicon under GGUF backend makes agentic loops take far too long. Dense 30B GGUF is significantly slower than MoE models of comparable parameter count which provide 10–30 tok/s.

## Failure patterns

- **Timeout floor:** Most adapters (9/11) fail with a 300s timeout because the model is too slow for multi-turn agentic tasks on this hardware. This is due to the GGUF backend throughput limits on Apple Silicon.

## Better alternatives

- MoE models of comparable total parameter count (e.g. those providing 10–30 tok/s).

## Observations across runs

- 2026-06-28 (initial): smoke test passed (model wired and responding)
- 2026-06-28 (aider trial): STALLED — js-02-debounce-feature, 593s total, watchdog abort during generation
- 2026-06-29 (overnight full sweep): Confirmed at scale — 10 of 11 adapters at timeout floor; codex best at 65%

## Status

**Removed from effective rotation** — the model cannot complete benchmark cases within the 300s timeout for any agentic adapter except codex. Still in `models.txt` for reference, but results are not representative of model capability — they reflect GGUF backend throughput limits on this hardware.

To properly evaluate this model, either:
1. Run with `BENCH_TIMEOUT=900` (3× current) — would allow more cases to complete but is impractical for routine sweeps
2. Wait for an MLX variant (if Zhipu publishes one) — MLX-optimized models run 3–5× faster than GGUF on Apple Silicon

## Download

```bash
lms get zai-org/glm-4.7-flash
lms ls --json | jq -r '.[].modelKey' | grep -i glm
```

GGUF published by the LM Studio community team. Fits a 32GB Mac.
