# olla

> Adopted 2026-09-28 to replace LiteLLM as the unified local proxy — see
> [docs/DECISION-replace-litellm-with-olla.md](../DECISION-replace-litellm-with-olla.md)
> and the spike it's based on,
> [docs/DECISION-proxy-olla.md](../DECISION-proxy-olla.md). **Phase 1 of code
> migration is done**: `bin/rt olla install|start|stop|status|models`,
> `config.sh` vars, and two pilot adapters (`pi`, `claude`) are wired and
> verified end-to-end through `bin/smoke`. The remaining ~20 adapters are a
> follow-up — see "Adapter wiring" below for the pattern to use. This card's
> Quick verdict / Performance numbers are still the spike's measurements
> against v0.0.29; they haven't been re-run under the real harness.

## Installation

Repo-local, no sudo — managed entirely by `bin/rt`:

```bash
bin/rt olla install   # downloads the pinned v0.0.29 darwin-arm64 release,
                       # verifies its SHA-256 against a checksum pinned in
                       # bin/rt, and unpacks it to $OLLA_INSTALL_DIR
                       # (default: .tools/olla, gitignored)
bin/rt olla start      # runs it in the background, waits up to 10s for
                        # /internal/health, prints the URLs
bin/rt olla status      # read-only — never autostarts anything
bin/rt olla models       # every model Olla discovered, across all backends
bin/rt olla stop
```

The manual install steps this section used to show (download, verify
checksum by hand, unzip, `cd` into a working directory that also holds
`config/profiles/`) are exactly what `bin/rt olla install`/`start` now do
for you — see `cmd_olla` in `bin/rt` for the implementation. The one
non-obvious constraint that drove that implementation still applies: Olla
resolves `config/profiles/*.yaml` relative to its **CWD**, not to
`--config`'s path, so `bin/rt olla start` always runs the binary with the
install dir as CWD (a profiles-less CWD silently falls back to a minimal
built-in profile set lacking `omlx`/`mtplx`).

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
Full template: [config-templates/olla.yaml](../../config-templates/olla.yaml);
the MTPLX profile itself is committed at
[config-templates/olla-profiles/mtplx.yaml](../../config-templates/olla-profiles/mtplx.yaml)
and `bin/rt olla start` copies it into the install dir before every start, so
it can't drift from what's in the repo.

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
| pi (OpenAI-format harness) | ✅ | migrated in Phase 1 — routes ONLY through Olla (`adapters/pi.sh`); `bin/smoke -m omlx/Ornith-1.5-9B-MLX-4bit -a pi --skip-compat-update` → 6/6 PASS, confirmed in Olla's log as `omlx` dispatches via `/olla/proxy/v1/chat/completions` |
| claude (Anthropic-format harness) | ✅ | migrated in Phase 1 — routes ONLY through Olla's native `/olla/anthropic/v1/messages` (`adapters/claude.sh`); `bin/smoke -m omlx/Ornith-1.5-9B-MLX-4bit -a claude --skip-compat-update` → 6/6 PASS, confirmed in Olla's log with `"translator_mode":"passthrough"` |
| opencode (OpenAI-format harness) | ❌ | not yet migrated — opencode reads a static `~/.config/opencode/opencode.json` provider config that doesn't pick up base-URL env var overrides live; the same config-sync work `bin/agents-config` already does for LM Studio/LiteLLM needs re-pointing at Olla (see docs/tools/opencode.md). Pre-existing limitation, not Olla-specific. |
| all other adapters (~20) | ⚠️ not yet migrated | Phase 2 — follow the "Adapter wiring" pattern below. Neither LiteLLM nor direct-runtime fallback should be added to a migrated adapter; strip it out entirely per the pi/claude diffs. |

## Adapter wiring

The pattern Phase 1 (`adapters/pi.sh`, `adapters/claude.sh`) established for
migrating the rest. A migrated adapter routes through Olla **only** — delete
its LiteLLM branch, its direct-runtime branches, and any hardcoded
per-runtime model list; Olla's own discovery replaces all of that.

**Env vars (`config.sh`):**

| Var | Value | Use for |
|-----|-------|---------|
| `OLLA_BASE_URL` | `http://127.0.0.1:$OLLA_PORT/olla/proxy/v1` | OpenAI-format adapters (`baseUrl`/`--api-base`/etc.) |
| `OLLA_ANTHROPIC_BASE_URL` | `http://127.0.0.1:$OLLA_PORT/olla/anthropic` | Anthropic-format adapters (`ANTHROPIC_BASE_URL`) — the client appends `/v1/messages` itself, same as the old `OMLX_BASE_URL`/`/v1`-stripping convention |
| `OLLA_API_KEY` | `olla` | any client that requires *some* auth value (Olla doesn't validate it) |
| `OLLA_HOST_URL` | `http://127.0.0.1:$OLLA_PORT` | health checks (`olla_up`), Olla's own non-API routes |

**Helpers (`lib/common.sh`):**

- `olla_up` — reachability check against `$OLLA_HOST_URL/internal/health`. Use it as a preflight; die with `"Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)"` rather than letting the client fail with an opaque connection error.
- `strip_runtime_prefix <model-id>` — strips a leading `lms/`, `ollama/`, `mlx/`, `omlx/`, `mtplx/`, or `openai/` from a model id. Olla addresses every backend's models by their bare id (its discovery is unified across backends), so pass the *stripped* id to Olla even though `$MODEL_ID` may arrive prefixed (e.g. from `bin/bench --model omlx/Foo`).

**Before/after — OpenAI-format adapter** (`adapters/pi.sh`; the same shape applies to any adapter with an OpenAI-compatible `baseUrl`/`api_base` setting):

```bash
# BEFORE — branched on model prefix, picked LiteLLM or a direct runtime,
# hardcoded a model list per branch.
if [[ "$MODEL_ID" =~ ^omlx/ ]]; then
  RUNTIME_CONFIG='{"baseUrl":"'"$OMLX_BASE_URL"'", ..., "models":[{"id":"Ornith-1.5-35B-A3B-MLX-4bit"}, ...]}'
elif [ "$LITELLM_PROXY_MODE" = "1" ]; then
  RUNTIME_CONFIG='{"baseUrl":"'"$LITELLM_BASE_URL"'", ..., "models":[{"id":"lms/qwen2.5-coder-7b"}, ...]}'
else
  RUNTIME_CONFIG='{"baseUrl":"'"$LMS_BASE_URL"'", ..., "models":[]}'
fi

# AFTER — one config, pointed at Olla. If the client needs a non-empty
# `models` array to recognize the provider at all (pi does — an empty array
# means `--list-models` won't show it), populate it from Olla's own live
# discovery instead of a hardcoded list, so it can't go stale:
olla_up || die "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)"
BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"
OLLA_MODELS_JSON="$(runtime_models "$OLLA_BASE_URL" | jq -R -s -c 'split("\n") | map(select(length>0)) | map({id:.})')"
RUNTIME_CONFIG="$(jq -n --arg b "$OLLA_BASE_URL" --arg k "$OLLA_API_KEY" --argjson m "$OLLA_MODELS_JSON" \
  '{baseUrl:$b, api:"openai-completions", apiKey:$k, models:$m}')"
```

**Before/after — Anthropic-format adapter** (`adapters/claude.sh`; the same shape applies to any adapter that sets `ANTHROPIC_BASE_URL`):

```bash
# BEFORE — branched per prefix between direct oMLX/MTPLX/LMS endpoints and LiteLLM.
if [[ "$PREFIXED_MODEL_ID" =~ ^omlx/ ]]; then
  CLAUDE_BASE_URL="${OMLX_BASE_URL%/v1}"; AUTH_TOKEN="$OMLX_API_KEY"
elif [[ "$PREFIXED_MODEL_ID" =~ ^mtplx/ ]]; then
  CLAUDE_BASE_URL="${MTPLX_BASE_URL%/v1}"; AUTH_TOKEN="$MTPLX_API_KEY"
# ... lms branch, litellm-or-lms fallback ...
fi

# AFTER — one target, no branching:
olla_up || die "Olla proxy not reachable at $OLLA_HOST_URL (start it: bin/rt olla start)"
BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"
env ANTHROPIC_BASE_URL="$OLLA_ANTHROPIC_BASE_URL" \
    ANTHROPIC_AUTH_TOKEN="$OLLA_API_KEY" ANTHROPIC_API_KEY="$OLLA_API_KEY" \
    ANTHROPIC_MODEL="$BARE_MODEL_ID" \
    claude ...
```

**How to verify a migrated adapter:**

1. `bin/rt olla start` (idempotent — no-ops if already up), then `bin/rt olla models` to confirm the target model is discovered.
2. `bin/smoke -m omlx/Ornith-1.5-9B-MLX-4bit -a <adapter> --skip-compat-update` (use `-a`/`--adapter`, not `-t` — that flag doesn't exist and silently falls through to `$DEFAULT_ADAPTERS`). PASS or PARTIAL means the adapter reached the model; FAIL is a wiring bug, not a model-quality issue.
3. Confirm the traffic actually went through Olla rather than some leftover direct/LiteLLM path: `grep '"path":"/olla/' .tools/olla/run/olla.log | tail`, matching on the request's `user_agent` and timing against the smoke run. For Anthropic-format adapters, also check `"translator_mode":"passthrough"` in the log line.
4. `bash -n adapters/<name>.sh` and `bin/lint --scripts adapters/<name>.sh`.

**Smoke preflight:** `bin/smoke` fails fast with a clear error
(`Olla proxy not reachable ... (run: bin/rt olla start)`) if Olla is down and
the requested adapter is one of the Olla-routed ones — see
`_OLLA_ROUTED_ADAPTERS` in `bin/smoke`. Add each newly migrated adapter's
name to that list so it gets the same fast, clear failure instead of an
opaque per-case connection error.

## Status

**keep** — adopted 2026-09-28 to replace LiteLLM
([docs/DECISION-replace-litellm-with-olla.md](../DECISION-replace-litellm-with-olla.md)).
Phase 1 shipped `bin/rt olla install|start|stop|status|models`, `config.sh`
vars, and two verified pilot adapters (pi, claude — both 6/6 on
`bin/smoke`, traffic confirmed in Olla's own log). Fixes all three of
LiteLLM's pain points (auth, manual model sync, slow startup). Known caveats
before full adoption: opencode's (and similar static-config adapters')
config-sync step isn't implemented yet, and model-ID collision behavior
under `routing_strategy: strict` hasn't been exercised (no two backends here
share a model name). The remaining ~20 adapters are Phase 2, using the
"Adapter wiring" pattern above. Compare with the retired predecessor:
[docs/runtimes/litellm.md](litellm.md).
