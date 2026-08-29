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

- **Blocker: Interactive onboarding wizard required.** On first run, autohand forces an interactive wizard that requires you to select a provider and configure credentials, even for local providers. No `--skip-setup`, `--headless`, or non-interactive mode flags are documented. This makes it unsuitable for automated/non-interactive benchmark runs.
- Cloud login is **optional** — can choose local provider (Ollama, llama.cpp, MLX) in the wizard rather than cloud providers.
- Ships local-inference providers (Ollama, llama.cpp, MLX) natively, but the mandatory interactive setup remains a practical barrier.
- Litellm-proxy interop is a guess based on it having an `openai` provider, not confirmed against this repo's `bin/litellm-proxy`.

## Adapter flags and their rationale

Not yet written — no adapter exists yet.

## Failure modes

Not yet evaluated in this bench.

## Status

**Not suitable for this benchmark** — while autohand does ship native local model providers (Ollama, MLX) and does not strictly require cloud login, it blocks first-time use with a mandatory interactive onboarding wizard. No documented flags to skip/bypass this setup step exist. This makes it unsuitable for non-interactive, automated benchmark runs in a CI/headless environment. Moving to excluded list.
