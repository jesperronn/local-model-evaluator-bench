# mlx (`mlx_lm.server`)

## Installation

⚠️ **macOS (Apple Silicon) only**

```bash
# Install mlx-lm package
brew install mlx-lm

# Or via pip
pip install mlx-lm

# Verify installation
mlx_lm.server --help
```

Start the OpenAI-compatible server with a model:
```bash
mlx_lm.server --model Qwen/Qwen3.6-35B-A3B-MLX-4bit
# Listens on http://localhost:8080 (default)
```

Verify it's running:
```bash
curl http://localhost:8080/v1/models
```

> Note: Start the server manually before running benchmarks. Unlike lms, mlx doesn't auto-load models — you must specify one when starting the server.

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy impact vs baseline** | none, *if* the adapter handles the model-id correctly (hermes, pi: 100%, identical to lms) — otherwise severe (aider/codex/opencode collapse to 38–56%) |
| **Speed vs baseline** | roughly on par with lms for compatible adapters (pi: 52s vs lms 29s — 1.8× slower; hermes: 106s vs lms 97s — ~same) |
| **Best model class** | matched MLX-quant weights shared with lms/Ollama, e.g. Qwen3.6-35B-A3B-MLX-4bit |
| **Recommended for** | apples-to-apples MLX-vs-other-runtime comparison, using only adapters confirmed compatible (see below) |
| **Status** | experimental |

> Rule: when two runtimes have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **CLI/binary** | `mlx_lm.server` (from `mlx-lm` package, Homebrew: `mlx-lm`) |
| **API compatibility** | OpenAI-compatible `/v1` |
| **Base URL** | `http://localhost:8080` (start manually before `bin/bench --runtime mlx`) |
| **Model formats** | MLX only |
| **Platform** | macOS (Apple Silicon) only |
| **Loads/unloads models** | no — one model per running server process; start/stop manually |
| **Last reviewed** | 2026-07-02 |

## Connection setup

`bin/bench --runtime mlx` takes the model as either a HuggingFace repo id or a
**local absolute filesystem path** to an MLX model directory — pass it via
`--models`, or omit `--models` and it discovers whatever `mlx_lm.server` is
currently serving via `/v1/models`. This is the critical gotcha:

> ⚠️ **Known compat bug — model-id-as-path breaks LiteLLM-based adapters.**
> When the model argument is a raw filesystem path (e.g.
> `/Users/.../Qwen3.6-35B-A3B-MLX-4bit`), adapters whose model-info lookup is
> keyed by a recognizable model ID (aider, codex, opencode — all LiteLLM or
> similar-family clients) can't resolve it. Symptoms:
> - **aider**: falls back to a tiny default context window → many partial
>   failures, not outright errors (e.g. 16/38 on qwen3.6-35b-a3b).
> - **codex, opencode**: reject the model outright, erroring in ~2s on every
>   case (12/38 on both — only the trivial cases partially credit).
>
> This reproduced identically across two separate models tested via mlx —
> it's a plumbing issue with how these three adapters resolve model
> identities, not a model-quality or runtime-quality problem. **hermes and pi
> are unaffected** and scored a clean 38/38, identical to their lms results,
> confirming mlx's actual inference quality matches lms when the adapter
> handles the id correctly.
>
> No fix attempted yet — candidates: register a model alias mlx_lm.server can
> serve under a recognizable name, or patch the affected adapters' env/config
> to force a known model-name override.

## Performance characteristics

qwen3.6-35b-a3b (Qwen3.6-35B-A3B-MLX-4bit), full 11-case / 38-check suite,
2026-07-02 — see
[docs/models/qwen--qwen3.6-35b-a3b.md](../models/qwen--qwen3.6-35b-a3b.md):

| Adapter | Score | Avg s/case | Note |
|---------|:-----:|:----------:|------|
| hermes | 100% | 105.8 | unaffected by model-id bug; slightly slower than lms (97.4s) |
| pi | 100% | 52.4 | unaffected by model-id bug; 1.8× slower than lms (29.5s) |
| cline | 82% | 41.1 | real inference, some genuine failures (not the model-id bug) |
| aider | 56% | n/a | **model-id-as-path bug** — degraded context window |
| codex | 38% | n/a | **model-id-as-path bug** — outright rejection, 2s errors |
| opencode | 38% | n/a | **model-id-as-path bug** — outright rejection, 2s errors |
| caveman, copilot | 38% | n/a | broken on every runtime tested, not mlx-specific |

interpreter and openhands have no `-mlx` adapter variant yet (skipped —
`adapters/interpreter-mlx.sh` / `adapters/openhands-mlx.sh` don't exist).

## Supported model formats

| Format | Support | Notes |
|--------|:-------:|-------|
| MLX | ✅ | only format supported |
| GGUF | ❌ | |

## Adapter compatibility

| Adapter | Status | Note |
|---------|:------:|------|
| hermes, pi | ✅ | 100% — unaffected by the model-id-as-path bug |
| cline | ⚠️ | 82% — real inference, no plumbing bug, but some genuine failures |
| aider | ❌ | model-id-as-path bug degrades context; 56% |
| codex, opencode | ❌ | model-id-as-path bug causes outright rejection; 38% |
| caveman, copilot | ❌ | broken everywhere, not mlx-specific |
| interpreter, openhands | — | no mlx adapter script exists yet |

## Status

**experimental** — accuracy is on par with lms for compatible adapters, but
adapter coverage is the narrowest of the three runtimes until the
model-id-as-path bug is fixed for aider/codex/opencode. Use hermes or pi if
you need mlx today.
