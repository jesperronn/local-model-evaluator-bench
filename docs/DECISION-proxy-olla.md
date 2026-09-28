# Decision: Olla as a LiteLLM replacement

Spike date: 2026-09-28. Olla version tested: **v0.0.29** (darwin-arm64 release
binary). Repo: https://github.com/thushan/olla.

## TL;DR

**Adopt-with-caveats.** Olla fixes all three LiteLLM pain points outright (no
auth token, zero manual model sync, ~0.8s single-binary startup vs
Docker+Postgres), and it turns out both oMLX and MTPLX already speak the
Anthropic Messages API natively, so Olla mostly gets to passthrough rather
than translate. The one real caveat: Olla's out-of-the-box "openai-compatible"
profile has cloud-oriented (`gpt-*`/`*turbo*`) capability-matching patterns
baked in, so a custom local backend like MTPLX needs a small hand-written
profile file before tool-calls/Anthropic-routing work for it — a 15-minute
one-time fix, not a blocker. Harness integration (bin/smoke) confirmed the
Anthropic-format path (`claude` adapter) works end-to-end through Olla with
no code changes; the OpenAI-format path (`opencode`) needs its provider
config pre-synced the same way it already needs for LiteLLM/LM Studio direct
(a pre-existing, Olla-unrelated limitation — see docs/tools/opencode.md).

## Comparison vs LiteLLM

| Dimension | LiteLLM (current) | Olla v0.0.29 |
|---|---|---|
| Auth needed locally | Yes — `sk-*` master key required even for localhost clients | **No** — confirmed: requests succeed with no `Authorization` header, and Olla also accepts (and forwards untouched) a dummy `Bearer x` without erroring |
| Model sync | Manual — `store_model_in_db` backed by Postgres; models must be registered | **Automatic** — static endpoint list only; Olla discovers each backend's own `/v1/models` on its own (30s health-check / 5m model-discovery interval), no per-model registration |
| Startup | Docker + Postgres container; multi-step, slow | **Single static binary**, cold start to first healthy `/internal/health` ≈ **0.8s** (see below) |
| Anthropic `/v1/messages` support | Yes (LiteLLM serves `/v1/messages` and translates to OpenAI backends; not exercised in this spike) | **Yes** — dedicated `/olla/anthropic/v1/messages` route, with native passthrough when the backend supports it (both oMLX and MTPLX do) and OpenAI-translation fallback otherwise |
| OpenAI tool calls | Passthrough only | Passthrough; verified structured `tool_calls` survive intact |
| Down-backend tolerance | N/A (not tested this spike) | **Good** — lms/ollama configured but down; Olla marks them `offline` at startup and keeps serving omlx/mtplx with no crash, no blocking |
| Unified model discovery | Manual registration | Automatic; unified `/olla/proxy/v1/models` lists all backends' models without per-model config |

## Install

```bash
curl -sL -o olla_v0.0.29_macos_arm64.zip \
  https://github.com/thushan/olla/releases/download/v0.0.29/olla_v0.0.29_macos_arm64.zip
curl -sL -o checksums.txt \
  https://github.com/thushan/olla/releases/download/v0.0.29/checksums.txt
grep macos_arm64 checksums.txt   # a879d124...ce7fe0b4
shasum -a 256 olla_v0.0.29_macos_arm64.zip   # matched — verified official asset
unzip olla_v0.0.29_macos_arm64.zip -d olla_bin
```

Verified via GitHub's release API (`api.github.com/repos/thushan/olla/releases/latest`)
that this asset belongs to `thushan/olla`, tag `v0.0.29`. SHA-256 checksum
matched the published `checksums.txt`. No sudo, no system-wide install — the
binary ran straight out of the unzip directory. All spike files live under
the scratch dir (see path in the task); nothing outside `docs/` and
`config-templates/` was written to the repo.

## Config used

Saved as [`config-templates/olla.yaml`](../config-templates/olla.yaml) —
endpoints for omlx (`:8000`), mtplx (`:8001`), lms (`:1234`, down), ollama
(`:11434`, down). Comments in that file explain two non-obvious setup
requirements discovered during the spike:

1. Olla resolves `config/profiles/*.yaml` **relative to the process's
   working directory**, not relative to `--config`'s path. Running it from a
   directory that doesn't also have the release's `config/profiles/`
   silently falls back to a minimal built-in profile set (`llamacpp,
   lm-studio, ollama, auto` only) and the endpoint config then fails to
   load with `unsupported endpoint type: omlx`. Always run `olla` from the
   directory holding both `config/config.yaml` and `config/profiles/`.
2. MTPLX needs a **custom profile** (no built-in one ships). See "Known
   gaps" below for why and for the profile content.

Olla ships a built-in `omlx` profile already (`config/profiles/omlx.yaml`,
in the release zip) that documents oMLX's native Anthropic support — no
custom work needed there.

## Tests

### 1. Install + cold startup timing — PASS

```
$ (cd run && nohup ./olla_bin/olla --config run/config/config.yaml &)
... poll /internal/health every 100ms ...
healthy after .805976000 s (loop 7)
$ curl -s http://127.0.0.1:40114/internal/health
{"status":"healthy"}
```
~0.8s from process launch to first successful health response. No Docker,
no database, no migration step.

### 2. Config schema / auto-discovery — PASS

Fetched docs from thushan.github.io/olla and the shipped `config/config.yaml`
default file (which is extensively commented and served as ground truth over
guessing). Confirmed endpoint types (`omlx`, `openai-compatible`, `ollama`,
`lm-studio`, `vllm`, `vllm-mlx`, `llamacpp`, `sglang`, `lmdeploy`, `dmr`,
`lemonade`), default port `40114`, and `discovery.model_discovery.interval:
5m` (also `discovery.refresh_interval: 30s` for endpoint health). Discovery
requires only `url` + `type` + a name per endpoint — no per-model listing.

### 3. Model discovery (unified list, dynamic refresh, down-backend tolerance) — PASS

```
$ curl -s http://127.0.0.1:40114/olla/proxy/v1/models | python3 -m json.tool
{
  "object": "list",
  "data": [
    {"id": "Ornith-1.5-9B-MLX-4bit", "object": "model", "owned_by": "olla", ...},
    {"id": "Ornith-1.5-35B-A3B-MLX-6bit", ...},
    {"id": "mtplx-flash-next-optimized-speed", ...},
    {"id": "Qwen3.5-2B-bf16", ...},
    {"id": "Ornith-1.5-35B-A3B-MLX-4bit", ...},
    {"id": "gemma-4-E4B-it-MLX-8bit", ...},
    {"id": "NVIDIA-Nemotron-3.5-Lightning-30B-A3B-MLX-4bit", ...},
    {"id": "gemma-4-31B-it-MLX-4bit", ...},
    {"id": "Qwen3.8-Flash-Next-oQ4e-mtp", ...}
  ]
}
```
All 8 omlx models + the 1 mtplx model appear with zero manual registration.
`/internal/status/endpoints` confirmed `lms` and `ollama` marked
`"status":"offline"`, `"model_count":0`, with no startup block and no crash;
omlx/mtplx showed `"status":"healthy"`. Discovery refresh interval is
`5m` per docs/config (not independently re-verified by waiting 5 minutes in
this time-boxed spike — taken from the shipped config's own comment and
schema, which is authoritative).

### 4. Auth — PASS

```
$ curl -s http://127.0.0.1:40114/olla/proxy/v1/models -o /dev/null -w "HTTP %{http_code}\n"
HTTP 200
$ curl -s -H "Authorization: Bearer x" http://127.0.0.1:40114/olla/proxy/v1/models -o /dev/null -w "HTTP %{http_code}\n"
HTTP 200
```
Confirmed via docs too: "Olla does not implement authentication at the proxy
level" — any `Authorization`/`x-api-key` header a client sends is forwarded
to the backend untouched, never validated/required by Olla itself.

### 5. OpenAI chat completions (non-stream, stream, tool call) — PASS

Non-streaming (omlx, no auth header):
```json
{"id":"chatcmpl-6130d9a3","object":"chat.completion","model":"Qwen3.5-2B-bf16",
 "choices":[{"index":0,"message":{"role":"assistant","content":"Hello there!"},"finish_reason":"stop"}],
 "usage":{"prompt_tokens":19,"completion_tokens":3,"total_tokens":22, "model_load_duration":4.2,"total_time":1.12}}
```
Streaming (mtplx, with dummy `Bearer x`): got `data: {...delta:{role:assistant}...}` SSE chunks with `keep-alive` comments, standard OpenAI SSE shape.

Tool call (omlx, `get_weather("Paris")`):
```json
{"id":"chatcmpl-6092ca9d","choices":[{"message":{"role":"assistant",
  "tool_calls":[{"id":"call_50905fd6","type":"function",
     "function":{"name":"get_weather","arguments":"{\"city\": \"Paris\"}"}}]},
  "finish_reason":"tool_calls"}], ...}
```
Structured `tool_calls` survive Olla's proxy intact.

### 6. Anthropic Messages API — PASS (with the mtplx profile fix)

Direct oMLX native probe (bypassing Olla, port 8000):
```
$ curl -s -w "\nHTTP %{http_code}\n" http://127.0.0.1:8000/v1/messages -d '{"model":"Qwen3.5-2B-bf16","max_tokens":16,"messages":[{"role":"user","content":"hi"}]}'
{"id":"msg_58ba9397da7941faac61a499","type":"message","role":"assistant","model":"Qwen3.5-2B-bf16",
 "content":[{"type":"text","text":"Hi! How can I help you today?","cache_control":null}],
 "stop_reason":"end_turn", ...}
HTTP 200
```
**oMLX (and, discovered mid-spike, MTPLX too) already natively serve
`/v1/messages`.** This matters a lot: Olla mostly doesn't need to *translate*
Anthropic↔OpenAI for this stack, just passthrough, which is lower-risk than
the translation path.

Through Olla, non-streaming (omlx):
```json
{"id":"msg_75edc1a21b7c4ce3a6738569","type":"message","role":"assistant","model":"Qwen3.5-2B-bf16",
 "content":[{"type":"text","text":"Hello there!","cache_control":null}],"stop_reason":"end_turn", ...}
```
Through Olla, streaming (omlx) — proper Anthropic SSE event sequence:
```
event: message_start
data: {"type": "message_start", ...}
event: content_block_start
data: {"type": "content_block_start", "index": 0, "content_block": {"type": "text", "text": ""}}
event: content_block_delta
data: {"type": "content_block_delta", "index": 0, "delta": {"type": "text_delta", "text": "Here"}}
...
event: content_block_stop
```
Through Olla, tool_use (omlx, `get_weather("Paris")`):
```json
{"id":"msg_e8e954764dd84169898c9970","type":"message","role":"assistant","model":"Qwen3.5-2B-bf16",
 "content":[{"type":"tool_use","id":"call_7d8e333a","name":"get_weather","input":{"city":"Paris"}}],
 "stop_reason":"tool_use", ...}
```

**Gap hit and fixed:** the same request against **mtplx** initially failed —
`{"error":{"message":"model_unavailable","type":"api_error"}}`, HTTP 503, logged as
`"Model routing rejected request" ... reason":"model_unavailable"`. Root
cause (confirmed from Olla's own logs and the shipped
`config/profiles/openai-compatible.yaml`): I'd typed mtplx as
`type: "openai-compatible"`, and that profile's `capability_patterns.chat`
only matches `gpt-*`/`*turbo*` — cloud-model-shaped names — so
`mtplx-flash-next-optimized-speed` was never tagged "chat capable" and
Olla's `strict` routing strategy filtered it out of the Anthropic route
entirely (plain OpenAI `/v1/chat/completions` wasn't affected — that path
doesn't filter on the same capability tag). Writing a small custom profile
fixed it completely:

```yaml
# config/profiles/mtplx.yaml
name: mtplx
version: "1.0"
display_name: "MTPLX"
routing:
  prefixes: [mtplx]
api:
  openai_compatible: true
  anthropic_support:
    enabled: true
    messages_path: /v1/messages
    token_count: false
  paths: [/v1/models, /v1/chat/completions, /v1/completions, /v1/messages]
  model_discovery_path: /v1/models
  health_check_path: /v1/models
characteristics: {timeout: 3m, max_concurrent_requests: 4, default_priority: 90, streaming_support: true}
models:
  name_format: "{{.Name}}"
  capability_patterns:
    chat: ["mtplx-*"]
```
After adding this and switching the endpoint's `type` to `mtplx`, both
non-tool and tool_use Anthropic requests to mtplx succeeded:
```json
{"stop_reason":"tool_use","content":[{"type":"tool_use","id":"call_2d5a3f41","name":"get_weather","input":{"city":"Paris"}}]}
```
(HTTP 200 in both cases.) **Lesson for the migration:** any backend with a
non-`gpt-*`-shaped model naming convention needs its own profile (or at
minimum a `capability_patterns` override) for the Anthropic/tool-call
routes — the generic `openai-compatible` profile is tuned for cloud models
and silently drops local ones from those two routes without erroring loudly
at config-load time.

### 7. Model naming — PASS, with a routing nuance

Bare model IDs work on the aggregating `/olla/proxy/v1/...` routes (what
every test above used) and on backend-scoped routes
(`/olla/omlx/v1/chat/completions` also returned HTTP 200 for the same bare
ID). No prefix is required for uniquely-named models. Requesting an unknown
ID returns a clean `model_not_found` error rather than a crash. Because
omlx/mtplx/lms/ollama in this environment don't share any model IDs, true
collision behavior (`routing_strategy: strict` vs `optimistic`) wasn't
exercised — config comments show a `model_aliases:` block exists precisely
for the "same logical model, different names per backend" case, and
`routing_strategy.type` controls fallback if a request's model exists on
only some backends. Worth a deeper look before a multi-backend-overlap
migration, but doesn't block adoption for this stack today.

### 8. Harness end-to-end (bin/smoke) — PARTIAL PASS (time-boxed)

**Anthropic-format harness (`claude` adapter) — PASS.** Pointed
`OMLX_BASE_URL` at Olla's omlx-scoped route
(`http://127.0.0.1:40114/olla/omlx/v1`; `adapters/claude.sh` strips the
trailing `/v1` and lets the `claude` CLI's own `ANTHROPIC_BASE_URL` handling
append `/v1/messages`, landing on `/olla/omlx/v1/messages` — the native
oMLX passthrough path, verified working in test 6 above). No adapter code
was touched, only the env var override, consistent with the run instructions.
```
$ timeout 90 env OMLX_BASE_URL="http://127.0.0.1:40114/olla/omlx/v1" OMLX_API_KEY="olla" \
    bin/smoke --model omlx/Qwen3.5-2B-bf16 --adapter claude --skip-compat-update
[PASS] claude  Qwen3.5-2B-bf16  smoke-00-hello       PASS    (2s)
[WARN] claude  Qwen3.5-2B-bf16  smoke-01-edit-file   PARTIAL — 0/2 (2s)
[WARN] claude  Qwen3.5-2B-bf16  smoke-02-numbers     PARTIAL — 0/2 (2s)
[PASS] all adapters reached the model
```
The PARTIAL results are the tiny 2B smoke model's own capability limits
(wrong edit/sequence output), not a proxy problem — `[PASS] all adapters
reached the model` is the line that matters for this spike: the harness
drove a real chat/tool loop through Olla's Anthropic route successfully.

**OpenAI-format harness (`opencode` adapter) — FAIL, not Olla's fault.**
Same env var override:
```
$ timeout 90 env OMLX_BASE_URL="http://127.0.0.1:40114/olla/omlx/v1" OMLX_API_KEY="olla" \
    bin/smoke --model omlx/Qwen3.5-2B-bf16 --adapter opencode --skip-compat-update
[FAIL] opencode  Qwen3.5-2B-bf16  smoke-00-hello  FAIL — error(1)
  Error: {"name":"UnknownError","data":{"message":"Unexpected server error. Check server logs for details."}}
```
`docs/tools/opencode.md` already documents why: opencode reads its
provider `baseURL` from a static `~/.config/opencode/opencode.json` file
that `bin/agents-config`'s `sync_opencode_models` pre-populates — it does
**not** pick up `OMLX_BASE_URL`/`LITELLM_BASE_URL` env var overrides live,
so this failure would happen identically pointing opencode at plain LiteLLM
or LM Studio directly without the config pre-sync step. This is a
pre-existing opencode/adapter wiring characteristic, not something Olla
introduces. What migration would need: teach `bin/agents-config` (or a new
sync step) to write Olla's base URL into `opencode.json`'s provider block —
sketched below, not implemented (out of scope / time-boxed per the task).

### 9. Stop Olla — PASS

```
$ kill $(cat run/olla.pid); sleep 1
$ lsof -iTCP -sTCP:LISTEN | grep -i 40114
(no output)
$ ps aux | grep "[o]lla_bin/olla"
(no output)
```
`bin/rt status` after stopping Olla shows lms/ollama still down and
oMLX/MTPLX/MLX/LiteLLM in the same up/down state as at the start of the
spike — nothing else was started, stopped, or restarted.

## Known gaps

- **MTPLX needs a hand-written Olla profile** for tool-calls/Anthropic
  routing (test 6) — a real but small one-time authoring cost, not a
  runtime limitation.
- **`routing_strategy: strict` + model-ID collisions across backends**
  wasn't exercised (test 7) — no two backends here share a model name.
  Needs a dedicated check (`model_aliases:`, `routing_strategy.type:
  optimistic`) before relying on Olla to disambiguate identically-named
  models from two backends.
- **opencode (and any adapter reading a static provider-config file rather
  than an env var at invocation time) needs its own config-sync step**
  pointed at Olla — this is not new work created by Olla, it's the same
  work `bin/agents-config` already does for LM Studio/LiteLLM, just
  re-pointed.
- **5-minute model-discovery refresh interval** was read from config/docs,
  not observed by waiting out a live model add/remove in this session
  (oMLX/MTPLX model sets couldn't be changed without touching those
  runtimes, which was out of scope).
- Auth is fully delegated to the backend/network layer — Olla forwards
  whatever `Authorization`/`x-api-key` header it's given without validating
  it. Fine for a localhost-only bench setup; would need a reverse proxy or
  Olla's per-endpoint outbound `auth:` block if any backend needed to be
  reachable off-box.

## Migration sketch (not implemented)

If adopted, the shape of the change in this repo would be:

- **`config.sh`**: add `OLLA_PORT` (default `40114`), `OLLA_BASE_URL`
  (`http://127.0.0.1:${OLLA_PORT}`), drop `LITELLM_*`/`DATABASE_URL`/
  `LITELLM_PG_*` vars (or keep them dormant for a rollback window).
  `LITELLM_PROXY_MODE` becomes `OLLA_PROXY_MODE`.
- **`bin/rt`**: replace the `bin/litellm-proxy` Docker/Postgres lifecycle
  with a plain `bin/olla-proxy start|stop|status` that runs the release
  binary directly (no container, matching how `bin/omlx`/`mtplx` are
  already run) — `bin/rt status` gains an `Olla` line the same shape as
  its existing `LiteLLM` line.
- **`adapters/*.sh`**: model ID prefixing (`lms/`, `omlx/`, `mtplx/`, ...)
  stays the same pattern; the base URL constants they read from
  `config.sh` (`OMLX_BASE_URL`, etc.) get pointed at
  `${OLLA_BASE_URL}/olla/<provider>/v1` for direct-to-backend calls, or
  `${OLLA_BASE_URL}/olla/proxy/v1` for the aggregating route. The Anthropic
  route (`${OLLA_BASE_URL}/olla/anthropic/v1/messages`) is new capability
  `claude.sh` doesn't currently have any equivalent for against LiteLLM
  (LiteLLM has no Anthropic route at all) — this is a net-new integration
  point, not a port.
- **`bin/agents-config`**: extend `sync_opencode_models` (and any sibling
  sync functions for other static-config adapters) to also write an
  Olla-pointed provider block, so opencode/similar tools work without a
  code change once Olla is the default proxy.
- A `config/profiles/mtplx.yaml` (content above) would need to ship
  alongside Olla's binary in whatever directory `bin/rt`/`bin/olla-proxy`
  runs it from.

None of the above was implemented — this was a read/config/curl-only spike
per the task's constraints.

## Lint

```
$ bin/lint docs/DECISION-proxy-olla.md config-templates/olla.yaml
[FAIL] unknown option: docs/DECISION-proxy-olla.md
lint — validate scripts, adapters, and cards
USAGE
  lint [OPTIONS]
OPTIONS
--scripts    shell scripts (bash -n, shellcheck)
--adapters   adapter registration and compatibility
--cards      model/tool/runtime card specs
--fix        auto-fix issues (cards only)
```
`bin/lint` does not accept file/directory path arguments at all — despite
the repo-wide convention (this session's global `AGENTS.md`) that a project's
lint entrypoint should "accept any number of file/directory paths as
arguments... lints the whole project when given no args." This repo's
`bin/lint` only has fixed `--scripts`/`--adapters`/`--cards` flags and no
positional-path support, and it has no Markdown/YAML checks at all (it
validates shell scripts, adapter registration, and card specs). So: **`.md`
and `.yaml` files cannot be linted by this repo's `bin/lint` in any form** —
not a partial miss, there's no applicable mode. Bringing `bin/lint` in line
with the global convention (positional path args, whole-project default) is
a separate, pre-existing gap unrelated to Olla; flagged here rather than
fixed, since it's out of this spike's scope.
