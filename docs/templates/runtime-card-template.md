# {Runtime name}

<!-- Replace {Runtime name} with the display name, e.g. LM Studio, Ollama, vLLM -->

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy impact** | <!-- e.g. no observed accuracy delta vs Ollama; or: ~5% lower on tool-call adapters --> |
| **Speed vs baseline** | <!-- e.g. ~3.3× faster than GGUF Ollama on MLX; or: comparable to lms --> |
| **Best model class** | <!-- e.g. GGUF quants, MLX, bfloat16 --> |
| **Recommended for** | <!-- e.g. workstation air-gapped use, GPU server batching, Apple Silicon --> |
| **Status** | <!-- primary / secondary / experimental / not-installed --> |

> **Rule:** when two runtimes produce equal accuracy, prefer the faster one.
> Speed column must always be filled — "unknown" is not acceptable for an evaluated runtime.

---

## Metadata

| Field | Value |
|-------|-------|
| **Runtime name** | <!-- display name --> |
| **CLI / binary** | <!-- e.g. `lms`, `ollama`, `vllm` --> |
| **Version** | <!-- e.g. 0.3.15 --> |
| **API compatibility** | <!-- e.g. OpenAI-compatible (`/v1/chat/completions`) --> |
| **Base URL** | <!-- e.g. `http://localhost:1234/v1` --> |
| **Model formats** | <!-- e.g. GGUF, MLX, bfloat16, AWQ --> |
| **Platform** | <!-- e.g. macOS (Apple Silicon), Linux (CUDA), cross-platform --> |
| **Last reviewed** | <!-- YYYY-MM-DD --> |

---

## Connection setup

<!-- How adapters connect to this runtime. Include env vars, base URL, and any quirks. -->

```bash
# Key env vars / adapter config
LMS_BASE_URL="http://localhost:1234/v1"
# or
OLLAMA_BASE_URL="http://localhost:11434/v1"
```

<!-- Adapter-level notes: does this runtime require stripping /v1 from base URL? Parameter passthrough differences? -->

---

## Performance characteristics

> Speed = median wall-clock time per case relative to baseline (lms as baseline = 1.0×).
> Fill in from actual runs; leave blank and note "not yet measured" if no data.

| Model class | Accuracy | Speed vs baseline | Notes |
|-------------|:--------:|:-----------------:|-------|
| <!-- e.g. MLX 6-bit --> | <!-- e.g. equal --> | <!-- e.g. ~3.3× faster --> | |
| <!-- e.g. GGUF Q4 --> | <!-- e.g. equal --> | <!-- e.g. baseline --> | |

---

## Supported model formats

| Format | Supported | Notes |
|--------|:---------:|-------|
| GGUF | <!-- ✅ / ❌ --> | |
| MLX | <!-- ✅ / ❌ --> | <!-- Mac only --> |
| bfloat16 / safetensors | <!-- ✅ / ❌ --> | |
| AWQ / GPTQ | <!-- ✅ / ❌ --> | |
| GGML (legacy) | <!-- ✅ / ❌ --> | |

---

## Adapter compatibility

| Adapter | Compatibility | Notes |
|---------|:-------------:|-------|
| <!-- aider --> | <!-- ✅ full --> | |
| <!-- cline --> | <!-- ✅ full --> | |
| <!-- caveman --> | <!-- ❌ broken --> | <!-- error(1) on all non-trivial cases --> |

---

## Known limitations

<!-- Repeatable issues: parameter stripping, context limits, tool-call format differences, cold-start overhead. -->

<!-- Example:
**Parameter X not forwarded:** This runtime strips `stop` sequences — adapters that rely on stop tokens may behave differently.
-->

---

## Observations across runs

<!-- Append a section per run batch. Newest first. -->

### {YYYY-MM-DD} — {context}

<!-- What changed, what was notable. Keep to 3–5 sentences. -->

---

## Status

**{primary / secondary / experimental / not-installed}** — one-sentence rationale. Cross-link relevant model and tool pages.
