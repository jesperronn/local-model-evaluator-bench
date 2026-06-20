# microsoft/phi-4-mini

## Metadata

| Field | Value |
|-------|-------|
| **Status** | AVOID — broken tool calling (≤19%, smoke test only across all runtimes) |
| **Model key (lms)** | `microsoft/phi-4-mini` |
| **Model key (Ollama)** | `phi4-mini:latest` |
| **Model key (MLX)** | `mlx-community/Phi-4-mini-instruct-4bit` |
| **Family / arch** | Phi-4 mini, dense, 3.8B |
| **Parameter count** | 3.8B |
| **Quantization** | 4-bit (MLX); varies (lms/Ollama) |
| **Added** | 2026-06-xx |
| **Last run** | 2026-06-19 |
| **Doc updated** | 2026-06-20 |

## Results summary

**Broken tool calling. Do not use.**

Tested across three runtimes; all show the same broken tool-calling pattern:

| Runtime | Model key | Pass% | Pattern |
|---------|-----------|-------|---------|
| lms | `microsoft/phi-4-mini` | 18.9% (34/180) | 6–7/30 per adapter; copilot 2/28 |
| Ollama | `phi4-mini:latest` | 6.7% (2/30) | smoke test only |
| MLX | `mlx-community/Phi-4-mini-instruct-4bit` | 7.1% (6/84) | 2/28 per adapter, 3 trials |

Despite the lms variant appearing to score higher at 18.9%, inspection reveals all 34 passes are smoke-test sub-cases or trivially-passed first checks. No adapter reaches ≥30% on lms, and the copilot adapter scores 2/28 (7.1%) — identical to Ollama/MLX. The lms score is inflated by running more adapters, each contributing a small fixed smoke-pass count.

## Failure patterns

**lms `microsoft/phi-4-mini` — all adapters low:** aider 23.3% (7/30), codex 21.9% (7/32), opencode 20.0% (6/30), hermes 20.0% (6/30), caveman 20.0% (6/30), copilot 7.1% (2/28). Every adapter's pass count maps to a small fixed count of smoke-test-adjacent sub-cases. None of the multi-file, self-verify, or complex coding cases pass on any adapter.

**Ollama `phi4-mini:latest` — opencode (2/30, 6.7%) and caveman (0/2, 0.0%):** the minimum possible score. Responses are near-instant (~1s), indicating the model returns text immediately without executing tool calls.

**MLX `Phi-4-mini-instruct-4bit` — hermes, codex, caveman (2/28 each, 3 trials):** consistent across three separate trial runs. Zero coding tasks complete.

## Timing observations

- **lms codex:** avg 394.6s — codex generates many tokens but none produce working edits; eventually times out on complex cases.
- **lms aider:** avg 30.9s — faster, but same pass pattern.
- **Ollama:** avg 1.0s — near-instant; model not engaging with tool use.
- **MLX hermes:** avg 107.3s — overhead from hermes conversation loop before timing out.

## Known issues

**Tool call format incompatibility:** same issue as Phi-4 14B. The Phi-4 family uses a non-standard tool-call format (`<|tool_call|>` tags in some variants, or raw JSON text in others) incompatible with the OpenAI tool_calls API format expected by all adapters in this bench. lms's higher score may reflect lms partially translating the format — but not enough for actual task completion.

**lms score inflation:** the 18.9% figure looks better than the Ollama/MLX 7% but is misleading. With 6 adapters × ~30 cases, even a model that consistently passes 1 smoke sub-case per adapter run will accumulate 6/180 = 3.3%. Passing js-01's first two sub-checks on all 6 adapters gives 12/180 = 6.7%. The actual observed 34/180 includes a few additional sporadic passes but no systematic capability.

## Status

**avoid** — broken tool calling across all three runtimes (lms, Ollama, MLX). No adapter or runtime combination produces reliable tool use. The consistent ≤20% pattern across all tested configurations makes this a model-family issue, not a runtime misconfiguration.

**Cleanup:** remove `phi4-mini:latest` from `models-ollama.txt`, `microsoft/phi-4-mini` from `models.txt`, and `mlx-community/Phi-4-mini-instruct-4bit` from any MLX model lists.

**If you need a working small model:** `qwen/qwen3.5-9b` (lms, 86.8%) is the best small model in the suite at 9B. For Ollama, `gpt-oss:20b` at 80% is the next working model, though larger.

See also: [Models to Avoid in LEADERBOARD.md](../../LEADERBOARD.md#models-to-avoid), [microsoft--phi-4.md](microsoft--phi-4.md)
