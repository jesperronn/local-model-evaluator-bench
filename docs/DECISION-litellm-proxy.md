# Decision: LiteLLM proxy layer

**Date:** 2026-06-27
**Status:** Deferred — revisit when pain increases

## Context

We run strictly local, air-gapped open-weight models. Each runtime (LM Studio,
Ollama, mlx_lm.server) has its own model list file (`models.txt`,
`models-ollama.txt`, `models-mlx.txt`) and its own adapter code. Agents must be
configured per-runtime with hardcoded API base URLs and model identifiers.

LiteLLM is a Python proxy that presents a single OpenAI-compatible API in front
of multiple backends. It runs locally and routes requests to whichever runtime
is serving the model.

## Decision

Skip LiteLLM for now. The current setup works and adding a proxy is an extra
moving part without enough payoff today.

## Criteria for revisiting

We should revisit this decision if LiteLLM would help with any of these:

### 1. Simplify model configuration

Today we maintain three `models*.txt` files with runtime-specific model
identifiers (LM Studio keys, Ollama tags, HuggingFace repo paths). A proxy
layer could let us define models once with canonical names and map them to
whatever runtime is available.

**Revisit when:** maintaining three model lists becomes a source of drift or
errors, or when we want to test the same logical model across runtimes without
duplicating config.

### 2. Reduce adapter count

Each runtime needs its own adapter logic to handle API differences. If LiteLLM
normalizes all backends behind one OpenAI-compatible endpoint, adapters could
collapse into a single "talk to LiteLLM" adapter.

**Revisit when:** we add more runtimes (vLLM, llama.cpp server, etc.) and
adapter maintenance becomes a drag.

### 3. Model discovery without hardcoded config

Today, agents need a specific model identifier baked into their config. LiteLLM
can list available models via its `/v1/models` endpoint, which aggregates across
all connected backends. Agents could discover what's loaded at runtime instead
of relying on static config files.

**Revisit when:** we want agents to auto-select models, or when the
model-loading workflow (download → add to txt file → run bench) feels too
manual.

## Notes

- LiteLLM does not need internet at runtime for local routing, but phones home
  for telemetry by default (disable with `LITELLM_TELEMETRY=False`).
- Install while online (`pip install litellm[proxy]`), then run offline.
- Our `config.sh` already has `LMS_API_BASE` — this is the same abstraction
  point where LiteLLM would slot in.
