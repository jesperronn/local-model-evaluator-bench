# ollama

## Installation

```bash
# macOS
brew install ollama

# Linux / Windows: download from https://ollama.ai

# Verify installation
ollama --version
```

Start the OpenAI-compatible server:
```bash
ollama serve
# Listens on http://localhost:11434/v1 (default)
```

Verify it's running:
```bash
curl http://localhost:11434/v1/models
```

Pull a model (e.g. qwen):
```bash
ollama pull qwen:35b-mlx
```

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy impact vs baseline** | mild drop — no adapter hit a perfect 100% on qwen3.6-35b-a3b (best: interpreter 100%, others 85–95%) |
| **Speed vs baseline** | 1.4×–2.6× slower than lms per case (models stay resident, but per-case latency is higher) |
| **Best model class** | MoE with matched MLX quantization, e.g. `qwen3.6:35b-mlx` |
| **Recommended for** | ⚠️ NOT RECOMMENDED — tool calling is unreliable; use oMLX or llama.cpp instead |
| **Status** | ⚠️ not recommended |

> **Why:** Ollama's vendored backend has broken tool calling and structured output support. Qwen models specifically show "problems with tool calls and garbage responses that only happen with Ollama." oMLX outperforms it (1.8× faster, better accuracy) and uses a stable llama.cpp foundation.

## ⚠️ Known issues

**Tool calling failures:** Ollama's custom vendored backend has known problems with tool call handling and structured output. Qwen and other models exhibit "garbage responses" when using tool calls that don't occur on llama.cpp or oMLX runtimes.

**Performance regression:** Ollama is ~1.8× slower than llama.cpp on identical hardware and models due to backend regresssions.

**Recommendation:** Use **oMLX** or direct **llama.cpp** instead. Both have better accuracy, faster performance, and stable tool calling support.

## Metadata

| Field | Value |
|-------|-------|
| **CLI/binary** | `ollama` |
| **API compatibility** | OpenAI-compatible `/v1` (also native `/api`) |
| **Base URL** | `$OLLAMA_BASE_URL` (default `http://localhost:11434/v1`) |
| **Model formats** | GGUF, MLX (Ollama-repackaged) |
| **Platform** | macOS, Linux, Windows |
| **Loads/unloads models** | no — models stay resident once loaded (`ollama ps`); good for repeated trials, but means only one model in memory per host |
| **Last reviewed** | 2026-07-02 |

## Connection setup

Standard OpenAI-compatible base URL. **Watch context-window defaults** — some
models (e.g. `qwen3.5:9b`) load with a 262K default context in Ollama, causing
300s+ timeouts and much worse scores than the identical weights on lms (97%
lms vs poor on Ollama). Always check `ollama show <model>` for the effective
context before trusting a slow/failing Ollama run as a model quality problem.

## Performance characteristics

qwen3.6-35b-a3b, full 11-case / 38-check suite, 2026-07-02 — see
[docs/models/qwen--qwen3.6-35b-a3b.md](../models/qwen--qwen3.6-35b-a3b.md):

| Adapter | Score | Avg s/case | vs lms |
|---------|:-----:|:----------:|:------:|
| interpreter | 100% | 73.6 | 1.7× slower |
| opencode | 95% | 129.2 | 2.5× slower |
| codex | 89% | 45.3 | 1.4× slower |
| hermes | 89% | 83.5 | 1.2× *faster* than lms's 97.4s (only adapter where Ollama wins) |
| aider | 91% | 72.5 | ~same |
| pi | 92% | 95.4 | 3.2× slower |
| openhands | 85% | 126.5 | 2.1× slower |

No adapter reached a perfect score on Ollama in this run, unlike lms (5
adapters at 100%) and MLX (2 adapters at 100%, compat-bug-limited elsewhere).
Per-case latency is the most variable of the three runtimes — ranges 45s–129s
among adapters that clear 80%+.

## Supported model formats

| Format | Support | Notes |
|--------|:-------:|-------|
| GGUF | ✅ | |
| MLX (repackaged) | ✅ | prefer the `-mlx` tag over `-coding-mxfp8`/similar GGUF-style tags when both exist — e.g. `qwen3.6:35b-mlx` is ~3.3× faster than `qwen3.6:35b-a3b-coding-mxfp8` on smoke tests with identical pass rates |

## Adapter compatibility

| Adapter | Status | Note |
|---------|:------:|------|
| aider, codex, hermes, interpreter, opencode, openhands, pi | ✅ | 85%+ on qwen3.6-35b-a3b (`qwen3.6:35b-mlx`) |
| cline | ⚠️ | intermittent — passed smoke individually but failed one case in the full sweep; flagged incompatible in `compat.json` for some models |
| caveman, copilot | ❌ | error(1) on Ollama across models tested — same class of failure as on lms |

## Status

**⚠️ Not recommended** — Ollama's tool calling is broken and its performance lags both oMLX and llama.cpp. Use oMLX instead for the same MLX-optimized performance without the tool-calling regressions.
