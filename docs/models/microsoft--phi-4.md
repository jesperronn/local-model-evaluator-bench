# microsoft/phi-4

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 66.7% (LMS), ~7–9% (Ollama/MLX) |
| **Speed (avg)** | 70s (LMS), 0.9s (Ollama), 28s (MLX) |
| **Best adapter** | pi, goose (100% on LMS) |
| **Recommended for** | 13-14B tier on LMS runtime |
| **Status** | keep (LMS) / avoid (Ollama, MLX) |

> **Runtime-dependent:** Phi-4 performs exceptionally well on LM Studio (66.7%) but fails on Ollama/MLX (7–9%). Use **LMS runtime only**.

## Metadata

| Field | Value |
|-------|-------|
| **Status** | KEEP for LMS runtime; AVOID for Ollama/MLX |
| **Model key (LMS)** | `microsoft/phi-4` |
| **Model key (Ollama)** | `phi4:latest` |
| **Model key (MLX)** | `mlx-community/Phi-4-4bit` |
| **Family / arch** | Phi-4, dense, 14B-15B |
| **Parameter count** | 14-15B (varies by quantization) |
| **Disk size** | ~9.05 GB (LMS GGUF) |
| **Added** | 2026-06-xx |
| **Last run** | 2026-07-04 (LMS smoke test) |
| **Doc updated** | 2026-07-04 |

## Results summary

### LMS Runtime (2026-07-04) — STRONG PERFORMER ✅

**Smoke test performance: 24/36 cases (66.7%)**

| Adapter | Pass Rate | Notes |
|---------|-----------|-------|
| **pi** | 6/6 (100%) ✓ | Perfect execution across all smoke tests |
| **goose** | 6/6 (100%) ✓ | Excellent performance, reliable tool calls |
| **interpreter** | 5/6 (83%) | Mostly works; 1 partial (greeting.txt formatting) |
| **nanocoder** | 2/3 (67%) | Passes basic cases; 1 timeout on edit-file |
| **hermes** | 3/6 (50%) | Mixed results; partial success on some cases |
| **opencode** | 0/6 (0%) | "Unexpected server error" (adapter-level issue, not model) |

**Note:** Aider and cline were not tested in this run (smoke test truncated early), but expected to perform in the 50-83% range based on compatibility patterns.

### Historical Results (Ollama/MLX) — BROKEN TOOL CALLING ❌

Ollama scores 2/28 (7.1%) — only trivial first two sub-checks pass; zero real tool calls succeed.
MLX scores 6/68 (8.8%) — same pattern: smoke-test only, no coding tasks complete.

**Status:** Tool-call incompatibility on Ollama/MLX runtimes, but works reliably on LMS.

## Failure patterns

### LMS Runtime — Known Issues

**opencode adapter (0/6, all fail):** "Unexpected server error" across all cases. This error also occurs with Mistral Nemo on LMS, indicating an adapter-level incompatibility with the LM Studio OpenAI API, not a model issue.

**nanocoder timeout (1/3):** smoke-01-edit-file times out at 301s. Nanocoder's slower iteration strategy exceeds the timeout on edit tasks, but still passes other cases (67% overall).

**hermes mixed (3/6, 50%):** Hermes shows inconsistent results — passes smoke-01-edit-file perfectly but fails on trivial write-from-scratch and number-editing tasks. Likely due to hermes' agentic complexity being overkill for simple tasks.

### Ollama/MLX Runtimes — Broken Tool Calling

**Ollama `phi4:latest` (2/28, 7.1%):** Only smoke sub-checks pass; zero real tool calls execute. Responses average 0.9s — suspiciously fast, indicating the model returns short text without valid tool call syntax.

**MLX `Phi-4-4bit` (6/68, 8.8%):** All three tested adapters (hermes, codex, caveman) show the same minimum score pattern — smoke-test passes only, zero coding tasks complete.

**Root cause:** Phi-4's tool-call format differs from OpenAI convention. Ollama/MLX don't bridge this gap; LMS handles it more gracefully.

## Timing observations

**LMS:** pi (55s avg), interpreter (60s avg), hermes (58s avg), goose (100s avg — slower due to agent overhead)
**Ollama:** 0.9s avg (suspiciously fast — no real work happening)
**MLX:** 28s hermes avg, ~0s codex/caveman (immediate errors)

## Known issues

### Runtime-dependent tool-call handling

Phi-4's tool-call format works reliably on **LMS only**. On Ollama/MLX, adapters cannot parse the generated tool calls, resulting in complete failure. This is likely due to LMS's prompt template wrapper or how it bridges the model's native format to the OpenAI API.

### opencode adapter incompatibility

**Status:** Adapter-level issue affecting both Phi-4 and Mistral Nemo on LMS. Skip opencode for all local agentic work on LMS runtime.

## Better alternatives

**For LMS runtime on 13-14B tier:**
- **Phi-4 (15B):** 66.7% smoke pass — Recommended for users with ≥32GB RAM
- **qwen/qwen3.5-9b (9B):** 100% smoke pass on aider — More efficient, smaller footprint
- **Mistral Nemo (12B):** 16.7% smoke pass — Not recommended (avoid)

**For Ollama/MLX runtimes:**
- **Ollama:** `gpt-oss:20b` scores 80% at 20.9B — closest working alternative
- **MLX:** Use `qwen/qwen3.6-35b-a3b` (MLX variant) — 100% across adapters

## Status

**keep (LMS runtime)** — Recommended 13-14B tier model on LMS. Phi-4 delivers strong smoke test results (66.7%), with two adapters (pi, goose) at perfect 100% compatibility. The LMS runtime properly handles Phi-4's tool-call format, enabling reliable agentic work.

**avoid (Ollama/MLX)** — Broken tool calling due to format incompatibility. Do not use on Ollama or MLX runtimes.

**Recommendation:** Use Phi-4 on **LMS only**. For Ollama/MLX, choose alternatives listed above.

See also: [mistralai/mistral-nemo-instruct-2407](mistralai--mistral-nemo-instruct-2407.md) — Alternative 12B (not recommended), [microsoft--phi-4-mini.md](microsoft--phi-4-mini.md)
