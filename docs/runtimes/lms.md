# lms (LM Studio)

## Installation

```bash
# macOS
brew install --cask lmstudio

# Linux / Windows: download from https://lmstudio.ai

# Verify installation
lms --version
```

Start the OpenAI-compatible server:
```bash
lms server start
# Listens on http://localhost:1234/v1 (default)
```

Verify it's running:
```bash
curl http://localhost:1234/v1/models
```

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy impact vs baseline** | baseline (reference runtime — other runtimes compared against this) |
| **Speed vs baseline** | 1× (fastest observed runtime so far — see Performance characteristics) |
| **Best model class** | MoE, e.g. qwen3.6-35b-a3b (3B active) |
| **Recommended for** | default runtime for all new model/adapter qualification |
| **Status** | primary |

> Rule: when two runtimes have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **CLI/binary** | `lms` (LM Studio CLI) |
| **API compatibility** | OpenAI-compatible `/v1` |
| **Base URL** | `$LMS_BASE_URL` (default `http://localhost:1234/v1`) |
| **Model formats** | GGUF, MLX |
| **Platform** | macOS (Apple Silicon), also Linux/Windows via LM Studio app |
| **Loads/unloads models** | yes — one model resident at a time, swapped automatically per run |
| **Last reviewed** | 2026-07-02 |

## Connection setup

Standard OpenAI-compatible base URL, no path-stripping quirks observed. Models
are referenced by their `lms ls --json` `modelKey` (e.g. `qwen/qwen3.6-35b-a3b`),
**not** a filesystem path — this is the setup convention every adapter's
LiteLLM/model-info lookup expects, and it's part of why lms has the broadest
adapter compatibility (see `mlx.md` for what breaks when a runtime is
addressed by raw path instead of a clean model ID).

## Performance characteristics

First real 3-way runtime comparison (qwen3.6-35b-a3b, full 11-case / 38-check
suite, 2026-07-02 — see
[docs/models/qwen--qwen3.6-35b-a3b.md](../models/qwen--qwen3.6-35b-a3b.md)):

| Adapter | Score | Avg s/case | vs Ollama | vs MLX |
|---------|:-----:|:----------:|:---------:|:------:|
| pi | 100% | **29.5** | 3.2× faster | 1.8× faster |
| codex | 92% | 31.5 | 1.4× faster | broken on mlx (compat bug) |
| interpreter | 100% | 43.1 | 1.7× faster | n/a (no mlx adapter) |
| opencode | 100% | 52.4 | 2.5× faster | broken on mlx (compat bug) |
| cline | 100% | 53.1 | n/a (ollama untested) | 1.3× faster |
| openhands | 97% | 61.4 | 2.1× faster | n/a (no mlx adapter) |
| aider | 87% | 71.3 | ~same | broken on mlx (compat bug) |
| hermes | 100% | 97.4 | slower (83.5s) | ~same (105.8s) |

**lms was the fastest runtime for every adapter that could be compared**,
except hermes where Ollama edged it out slightly. Model loads/unloads add
per-run overhead but per-case inference is consistently quickest here.

## Supported model formats

| Format | Support | Notes |
|--------|:-------:|-------|
| GGUF | ✅ | |
| MLX | ✅ | Apple Silicon only; generally faster than GGUF at equal quant on M-series |
| bf16/fp16 | ✅ | large disk footprint |
| AWQ | ❌ | not tested |

## Adapter compatibility

| Adapter | Status | Note |
|---------|:------:|------|
| aider, codex, cline, hermes, interpreter, opencode, openhands, pi, cn, goose | ✅ | all reach 87%+ on qwen3.6-35b-a3b |
| caveman | ❌ | `Unknown provider "lmstudio"` — caveman's provider list doesn't include local lms; error(1) on every case |
| copilot | ⚠️ | 44% — partial compatibility, inconsistent tool-call handling |

## Status

**primary** — default runtime for L0–L3 qualification (see
[TESTING-STRATEGY.md](../TESTING-STRATEGY.md)). Broadest adapter compatibility
and fastest per-case inference observed to date.
