# olla

> Adopted 2026-09-28 to replace LiteLLM as the unified local proxy — see
> [docs/DECISION-replace-litellm-with-olla.md](../DECISION-replace-litellm-with-olla.md)
> and the spike it's based on,
> [docs/DECISION-proxy-olla.md](../DECISION-proxy-olla.md). Code migration
> (`bin/olla-proxy`, `config.sh` vars, adapter routing) is a follow-up, not
> yet implemented — this card reflects the spike's measurements against
> v0.0.29, not a production integration.

## Installation

```bash
curl -sL -o olla_v0.0.29_macos_arm64.zip \
  https://github.com/thushan/olla/releases/download/v0.0.29/olla_v0.0.29_macos_arm64.zip
curl -sL -o checksums.txt \
  https://github.com/thushan/olla/releases/download/v0.0.29/checksums.txt
grep macos_arm64 checksums.txt         # a879d124...ce7fe0b4
shasum -a 256 olla_v0.0.29_macos_arm64.zip   # verify it matches
unzip olla_v0.0.29_macos_arm64.zip -d olla_bin
```

No sudo, no system-wide install — the binary runs straight out of the
unzip directory. Must be run from a working directory that has both
`config/config.yaml` and the release's `config/profiles/` alongside it
(Olla resolves profiles relative to CWD, not `--config`'s path — a
profiles-less CWD silently falls back to a minimal built-in profile set
lacking `omlx`/`mtplx`).

Start it:
```bash
cd run && ./olla_bin/olla --config config/config.yaml
# Listens on http://127.0.0.1:40114 (default)
```

Verify it's running:
```bash
curl -s http://127.0.0.1:40114/internal/health
# {"status":"healthy"}
```

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy impact vs baseline** | none observed — Anthropic-format harness (`claude` adapter) reached the model with no code changes; tool_calls and Anthropic tool_use both survived the proxy intact (spike tests 5–6) |
| **Speed vs baseline** | not directly comparable (×lms) — no lms-vs-through-Olla latency run was done. Measured instead: **~0.8s cold start** to first healthy `/internal/health` (spike test 1), vs LiteLLM's qualitatively much slower Docker+Postgres startup (docs/runtimes/litellm.md) |
| **Best model class** | backends that natively speak the Anthropic Messages API (oMLX, MTPLX both do) — Olla passthroughs rather than translates for those, which is lower-risk |
| **Recommended for** | default local proxy going forward, once the code migration lands |
| **Status** | keep |

> Rule: when two runtimes have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **CLI/binary** | `olla` (single static release binary, darwin-arm64 tested) |
| **Version** | v0.0.29 |
| **API compatibility** | OpenAI-compatible (`/olla/proxy/v1/...`), native Anthropic Messages (`/olla/anthropic/v1/messages`), per-backend scoped routes (`/olla/<name>/v1/...`) |
| **Base URL** | default `http://127.0.0.1:40114` (port 40114) |
| **Model formats** | n/a — passthrough proxy; format support is the backend's (omlx/mtplx/lms/ollama tested in the spike) |
| **Platform** | macOS (darwin-arm64 release tested); other platforms have releases but weren't verified here |
| **Loads/unloads models** | n/a — delegates to backend runtimes |
| **Last reviewed** | 2026-09-28 |

## Connection setup

No auth required locally — confirmed in the spike that requests succeed
with no `Authorization` header, and a dummy `Bearer x` is forwarded
untouched, never validated (spike test 4). Discovery is static-endpoint
based: `discovery.static.endpoints` lists each backend's `url`+`type`+name,
with `discovery.model_discovery.interval: 5m` for the model list refresh
and `discovery.refresh_interval: 30s` for endpoint health checks (read from
shipped config/docs, not observed live over a full 5-minute window). MTPLX
needs a **hand-written custom profile**
(`config/profiles/mtplx.yaml`, shown in
[docs/DECISION-proxy-olla.md](../DECISION-proxy-olla.md#config-used)) —
the built-in `openai-compatible` profile's `capability_patterns` are tuned
for cloud model names (`gpt-*`/`*turbo*`) and silently drop `mtplx-*`
models from tool-call/Anthropic routing without an error at config-load
time. oMLX ships a working built-in profile already, no custom work needed.
Full template: [config-templates/olla.yaml](../../config-templates/olla.yaml).

## Performance characteristics

Measured startup: **cold process launch to first healthy
`/internal/health` response ≈ 0.8s** (spike test 1, single run,
darwin-arm64, v0.0.29) — no Docker, no database, no migration step. This is
the only hard latency number from the spike; per-request proxy overhead
(Olla vs calling the backend directly) was **not measured** — the spike's
harness runs (test 8) report end-to-end smoke pass/fail, not a timing
delta attributable to Olla itself, so treat any implied "Olla adds ~0ms"
as **inferred**, not measured, from the fact that responses looked
identical in shape and content to direct-backend calls.

## Supported model formats

n/a — Olla is a proxy, not an inference runtime; format support is
whatever the backend (omlx/mtplx/lms/ollama) supports. Model discovery
itself is format-agnostic: all 8 omlx models + 1 mtplx model appeared via
`/olla/proxy/v1/models` with zero manual registration (spike test 3).

## Adapter compatibility

| Adapter | Status | Note |
|---------|:------:|------|
| claude (Anthropic-format harness) | ✅ | `bin/smoke --adapter claude` reached the model end-to-end through Olla's native `/olla/omlx/v1/messages` passthrough, no adapter code changed (spike test 8) |
| opencode (OpenAI-format harness) | ❌ | failed — but not Olla's fault: opencode reads a static `~/.config/opencode/opencode.json` provider config that doesn't pick up base-URL env var overrides live; identical failure would occur pointing it at LiteLLM or LM Studio directly without a config-sync step (spike test 8; see docs/tools/opencode.md) |
| all other adapters | ⚠️ untested | not exercised against Olla in the spike; only `claude` and `opencode` were run through `bin/smoke` in the time-boxed evaluation |

## Status

**keep** — adopted 2026-09-28 to replace LiteLLM
([docs/DECISION-replace-litellm-with-olla.md](../DECISION-replace-litellm-with-olla.md)).
Fixes all three of LiteLLM's pain points (auth, manual model sync, slow
startup) per the spike's measurements. Known caveats before full adoption:
MTPLX's custom profile requirement, opencode's static-config sync (not
implemented), and model-ID collision behavior under
`routing_strategy: strict` (not exercised — no two spike backends shared a
model name). Code migration is not yet implemented; see
[docs/DECISION-proxy-olla.md](../DECISION-proxy-olla.md#migration-sketch-not-implemented)
for the sketch. Compare with the retired predecessor:
[docs/runtimes/litellm.md](litellm.md).
