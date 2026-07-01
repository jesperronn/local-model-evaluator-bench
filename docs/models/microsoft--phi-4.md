# microsoft/phi-4

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | ~7–9% (smoke test only) |
| **Speed (avg)** | 0.9s (Ollama), 28s (MLX hermes) |
| **Best adapter** | N/A (broken tool calling) |
| **Recommended for** | None (do not use for agentic work) |
| **Status** | avoid |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Status** | AVOID — broken tool calling (7–9%, smoke test only) |
| **Model key (Ollama)** | `phi4:latest` |
| **Model key (MLX)** | `mlx-community/Phi-4-4bit` |
| **Family / arch** | Phi-4, dense, 14B |
| **Parameter count** | 14B |
| **Quantization** | 4-bit (MLX); fp16 or Q4 (Ollama) |
| **Added** | 2026-06-xx |
| **Last run** | 2026-06-19 |
| **Doc updated** | 2026-06-20 |

## Results summary

**Broken tool calling. Do not use.**

Ollama scores 2/28 (7.1%) — only the trivial first two sub-checks of `js-01-slugify-bug` pass. Zero real tool calls succeed. MLX scores 6/68 (8.8%) across three trials — slightly above 7.1% but the pattern is the same: all passes are the smoke-test sub-cases, no coding or file-editing task succeeds.

These results place Phi-4 among the lowest-scoring models in the suite, alongside Phi-4 mini and the Gemma 31b variants.

## Failure patterns

**Ollama `phi4:latest` — opencode (2/28, 7.1%):** the only adapter tested on Ollama. 2/28 means the smoke sub-tests pass (js-01 first two checks require only text output) and every subsequent case scores 0. Responses are very fast (avg 0.9s), consistent with the model returning short text that doesn't include valid tool call syntax.

**MLX `Phi-4-4bit` — hermes, codex, caveman (2/28 each, 3 trials each):** all three MLX adapters score the same minimum. hermes slightly higher at 2/12 (16.7%) in one framing but the same 2/28 pattern holds across all codex and caveman trials. Zero meaningful coding tasks complete.

## Better alternatives

If you need a working 14B model: `gpt-oss:20b` (Ollama) scores 80% at 20.9B — the closest working alternative in the Ollema suite. For LM Studio/lms, `qwen/qwen3-coder-30b` at 83.5% (MoE, 3B active) is faster and more accurate.

## Timing observations

- **Ollama:** avg 0.9s per case — suspiciously fast; model is responding but not engaging with tool use.
- **MLX hermes:** avg 28s — longer than Ollama because hermes has conversation overhead before timing out.
- **MLX codex / caveman:** avg ~0s — likely immediate errors or empty responses.

## Known issues

**Tool call format incompatibility:** Phi-4 uses a different tool-calling format than the OpenAI API convention expected by all adapters in this bench. The model may generate tool calls in a proprietary schema (`<|tool_call|>` tags) that none of the adapters parse. This is a known issue with Microsoft's Phi series and requires adapter-side shim work to fix.

## Status

**avoid** — broken tool calling across all tested runtimes (Ollama, MLX). Scores 7–9% (smoke test only), with zero actual coding tasks completing. The Phi-4 tool-call format is not compatible with any adapter in this bench without additional proxy/shim work.

**Cleanup:** remove `phi4:latest` from `models-ollama.txt` and `mlx-community/Phi-4-4bit` from any MLX model lists. Do not load for agentic work.

**If you need a working 14B model:** `gpt-oss:20b` (Ollama) scores 80% at 20.9B — the closest working alternative in the Ollama suite. For LM Studio/lms, `qwen/qwen3-coder-30b` at 83.5% (MoE, 3B active) is faster and more accurate.

See also: [Models to Avoid in LEADERBOARD.md](../../LEADERBOARD.md#models-to-avoid), [microsoft--phi-4-mini.md](microsoft--phi-4-mini.md)
