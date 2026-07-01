# openai/gpt-oss-20b

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | measured pending |
| **Speed (avg)** | measured pending |
| **Best adapter** | measured pending |
| **Recommended for** | measured pending |
| **Status** | watch |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `gpt-oss:20b` (Ollama) |
| **Family / arch** | GPT-OSS (OpenAI open-weight), dense |
| **Parameter count** | 20.9B |
| **Disk size** | 13 GB |
| **Quantization** | MXFP4 |
| **Context length** | 131072 (128K) |
| **Added** | 2026-06-12 |
| **Last run** | measured pending |
| **Doc updated** | 2026-06-12 |

## Results summary

Not yet benchmarked. OpenAI open-weight release with tools + thinking support,
Apache 2.0 license. 20.9B params, MXFP4 quantized (13 GB). System prompt says
"You are ChatGPT, a large language model trained by OpenAI." — this is OpenAI's
first open-weight model release.

## Timing observations

measured pending

## Failure patterns

no known failures recorded yet

## Better alternatives

No benchmarks available yet to determine alternatives.

## Status

**pending** — not yet benchmarked. Add to Ollama test queue: hermes, caveman,
codex (aider may need `--edit-format whole` if GPT-style responses differ from
expected diff format).
