# autohand (Autohand Code CLI)

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | untested |
| **Speed (avg)** | untested |
| **Best model** | untested |
| **Recommended for** | untested |
| **Status** | untested |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Autohand Code CLI |
| **CLI command** | `autohand` |
| **Install** | `brew install autohandai/code/autohand-code` |
| **Homepage** | https://autohand.ai/code/ |
| **Repository** | https://github.com/autohandai/code-cli |
| **Version** | untested |
| **Adapter script** | none yet — not wired into `adapters/` |
| **How it connects** | Has native local providers (`ollama`, `llamacpp`, `mlx`) plus an `openai`-compatible provider slot. No documented litellm-proxy mode specifically, but pointing its OpenAI provider's base URL at `$LITELLM_BASE_URL` (litellm's OpenAI-compatible surface) should work in principle — **unconfirmed**. |
| **Runtime model discovery** | unknown — not yet inspected |
| **Last reviewed** | 2026-08-29 |
| **Recommended for** | untested |

## Edit mechanism

Not yet evaluated in this bench.

## Iteration / self-verify behaviour

Not yet evaluated in this bench.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|

No runs recorded yet.

## Capability notes

- Cloud login is **optional** (`/login`/`/logout` are opt-in slash commands) — does *not* require a cloud account to run, unlike some harnesses excluded from this bench for that reason.
- Ships local-inference providers (Ollama, llama.cpp, MLX) out of the box, which is why it's worth testing here rather than excluding it.
- Litellm-proxy interop is a guess based on it having an `openai` provider, not confirmed against this repo's `bin/litellm-proxy`.

## Adapter flags and their rationale

Not yet written — no adapter exists yet.

## Failure modes

Not yet evaluated in this bench.

## Status

**untested** — added to the harness list 2026-08-29 after confirming it (a) supports local model runtimes natively and (b) does not require cloud login, so it does not belong on the excluded/cloud-login-required list. No adapter script or benchmark runs exist yet.
