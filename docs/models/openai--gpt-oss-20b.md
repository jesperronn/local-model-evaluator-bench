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
| **Family / arch** | GPT-OSS (OpenAI open-weight), MoE (~3.6B active) |
| **Parameter count** | 20.9B total / ~3.6B active per token |
| **Fits** | 24GB and 32GB unified RAM (MXFP4 ~13–16GB, leaves room for 128K context) |
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

Architecture is MoE with ~3.6B active params of 20.9B total, so it runs
fast on Apple Silicon despite the 20B headline size. Field reports rate it
strongly for reasoning, tool routing, and orchestrating downstream
code-completion models under chained-tool agent prompts — worth prioritizing
in the benchmark queue as a low-VRAM (24GB-friendly) orchestrator candidate.

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
