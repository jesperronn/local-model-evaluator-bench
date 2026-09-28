# litellm

> **Historical card.** LiteLLM is retired as of 2026-09-28 — see
> [docs/DECISION-replace-litellm-with-olla.md](../DECISION-replace-litellm-with-olla.md).
> This card is kept for reference; do not add new backends to it. It is not a
> runtime in the same sense as lms/ollama/mlx (no model inference of its
> own) — it's a proxy layer that fronted the actual runtimes.

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy impact vs baseline** | none observed — LiteLLM passthrough did not change per-model results (21/21 adapters smoke-passing 2026-08-30, `2b1df3c`) |
| **Speed vs baseline** | not measured — no lms-vs-through-LiteLLM latency comparison was ever run; only RSS (~270 MB) was measured (docs/archived/DECISION-litellm-proxy.md, 2026-08-02) |
| **Best model class** | n/a — proxy layer, not model/quantization-dependent |
| **Recommended for** | nothing going forward — retired; see Status |
| **Status** | drop |

> Rule: when two runtimes have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **CLI/binary** | `bin/litellm-proxy` (wraps `uvx litellm`, pinned `--python 3.12 --with 'fastapi<0.116'`) |
| **API compatibility** | OpenAI-compatible `/v1`, plus Anthropic `/v1/messages` (not exercised in the olla spike's comparison) |
| **Base URL** | `$LITELLM_BASE_URL` (default `http://127.0.0.1:4444/v1`, `$LITELLM_PORT=4444`) |
| **Model formats** | n/a — passthrough to lms/ollama/mlx/omlx/mtplx, no format handling of its own |
| **Platform** | macOS/Linux (Docker required for the store_model_in_db backing since 2026-08-22, `7adfccf`) |
| **Loads/unloads models** | n/a — delegates to backend runtimes |
| **Last reviewed** | 2026-09-28 |

## Connection setup

Adapters set `LITELLM_BASE_URL`/`LITELLM_MASTER_KEY` and route model IDs
through wildcard routes (`lms/*`, `ollama/*`, `mlx/*`, `omlx/*`, `mtplx/*`)
that pass the model id through without per-model registration in the config
file itself — but `store_model_in_db` (added 2026-08-22, `7adfccf`) still
requires each model to be synced into LiteLLM's Postgres store before it's
routable, which was a recurring source of manual/ad-hoc sync work
(2026-09-05 to 2026-09-09 fixes for MTPLX/oMLX). Auth requires a
pre-registered `sk-*` master key even for localhost clients — `config.sh`
ships with `LITELLM_PROXY_MODE=0` (proxy disabled) specifically because of
this, per the comment "Auth requires pre-registering keys in litellm's
token database. For now, disable proxy."

## Performance characteristics

**Not measured.** No dedicated lms-direct-vs-through-LiteLLM latency
comparison was run in this project. The one quantitative measurement on
record is process footprint: **~270 MB RSS**, measured 2026-08-02
(docs/archived/DECISION-litellm-proxy.md) and judged negligible next to the
KV-cache budget. Startup was qualitatively "Docker + Postgres, multi-step,
slow" per the same doc and the 2026-09-28 olla spike's comparison table, but
no seconds-level number was captured for LiteLLM's own cold start (contrast
with Olla's measured ~0.8s in docs/runtimes/olla.md).

## Supported model formats

n/a — LiteLLM is a proxy, not an inference runtime; format support is
whatever the backend runtime (lms/ollama/mlx/omlx/mtplx) supports.

## Adapter compatibility

| Adapter | Status | Note |
|---------|:------:|------|
| all 21 adapters | ✅ | smoke-passing through LiteLLM as of 2026-08-30 (`2b1df3c`), after the 2026-08-23 unification (`f077698`) removed the per-runtime `--runtime` flag |
| opencode | ⚠️ | required a static `~/.config/opencode/opencode.json` provider-config sync (`bin/agents-config`'s `sync_opencode_models`) — does not read `LITELLM_BASE_URL` live at invocation time; a pre-existing adapter-wiring characteristic, not specific to LiteLLM |

## Status

**drop** — retired 2026-09-28 in favor of Olla
([docs/DECISION-replace-litellm-with-olla.md](../DECISION-replace-litellm-with-olla.md)).
LiteLLM's adapter-unification win (collapsing five runtime-specific code
paths into one, `f077698`) is being kept; the Docker/Postgres/auth
machinery it required to do that is not. See
[docs/runtimes/olla.md](olla.md) for the replacement.
