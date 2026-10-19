# splash (local inference server) — runtime card

Tested 2026-10-20. Server: `http://127.0.0.1:8002` (OpenAI-compatible), single resident
model `unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M` (27B Q4 + DFlash speculative draft, 256K ctx,
vision). The user starts/stops it; this repo never does.

## Endpoint capabilities (curl-verified)

| Endpoint | Result |
|---|---|
| `GET /v1/models` | OK; reports `max_model_len`/`context_length` 262144, vision |
| `POST /v1/chat/completions` (non-stream) | OK; thinking comes back in `reasoning_content`, answer in `content`; extra `metrics`/`timings` fields |
| same, `stream:true` + `stream_options.include_usage` | OK; SSE, final usage chunk, `[DONE]` |
| tools (OpenAI schema) | OK — `tool_calls` parsed server-side, `finish_reason:"tool_calls"`, args is a JSON string: `{"city":"Paris"}` |
| `POST /v1/messages` (Anthropic) | exists, HTTP 200, returns Anthropic-shaped message |
| `POST /v1/responses` | exists, HTTP 200, returns Responses-API object (with reasoning item) |

Quirk: the very first request after idle showed ~3s `queue_to_start_ms`.

## Raw throughput (streaming, sequential, max_tokens 200-300)

| Prompt | prompt tokens | TTFT | decode tok/s |
|---|---|---|---|
| short | 68 | 0.23 s | 26.1 |
| "2K" (actually tokenized to 4.7K) | 4736 | 13.2 s (~360 tok/s prefill) | 22.1 |
| "16K" (actually 37K) | 37009 | 120.5 s (~307 tok/s prefill) | 20.7 |

Decode varies with speculative-draft acceptance (short chat bursts saw 30-100+ tok/s; real
content ~20-30). Prefill, not decode, dominates long agent contexts.

## Wiring (what changed)

splash is **not** behind Olla (not in `config-templates/olla.yaml`; adding it needs an Olla
restart, which was out of scope). Instead it is a direct runtime selected by the
`splash/` model prefix:

- `config.sh`: `SPLASH_PORT` (8002), `SPLASH_BASE_URL`, `SPLASH_API_KEY`.
- `lib/common.sh`: `splash_up()`; `strip_runtime_prefix` knows `splash/`.
- `bin/bench`: `splash` runtime (prefix parsing, base URL, preflight, no-op unload).
- `bin/smoke`: `splash/` prefix, splash up/serves-model check, Olla preflight skipped
  for omp/pi when `RUNTIME=splash`.
- `adapters/omp.sh`, `adapters/pi.sh`: when `RUNTIME=splash`, use provider `splash` at
  `$SPLASH_BASE_URL` instead of Olla (otherwise unchanged).

User-level config touched by running the adapters:
- `~/.pi/agent/models.json`: pi adapter adds a `splash` provider (backup:
  `~/.pi/agent/models.json.bak-splash`).
- `~/.omp/profiles/bench-splash/agent/models.yml`: new isolated omp profile (created by
  the adapter; `openai-models-list` discovery). Nothing in `~/.omp/agent` changed.

## Results

Smoke (`smoke-00/01/02`): omp 3/3 PASS, pi 3/3 PASS. (First omp smoke run failed with
`Model "splash/..." not found` — cold discovery in the freshly created bench-splash
profile; re-run passed.)

Small bench (js-01-slugify-bug, js-02-debounce-feature, bash-01-topwords), run 20261020-001430:
omp 8/12 checks (js-01 pass, js-02 pass 4/4 144s, bash-01 0/4 stall), pi 8/12 (js-01 4/4 77s,
js-02 4/4 74s, bash-01 0/4 stall 123s). Label: NOT the canonical baseline.

## Problems / deferred

- bash-01-topwords stalled on both harnesses: `WATCHDOG: stall phase — no progress for 120s
  (lms: idle)`. The stall watchdog appears lms-oriented; likely long reasoning with no
  output on splash. Not investigated (use `--stall 300`).
- pi edit-tool shim warning (`bin/pi-patch-edit-shim` not applied) unrelated to splash.
- Not registered in Olla; Olla-only adapters other than omp/pi cannot use splash yet.
- `compat.json` deliberately not updated (`--skip-compat-update` on smoke).

## Commands

    bin/smoke -m 'splash/unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M' -a <adapter> --skip-compat-update
    bin/bench -a <adapter> -m 'splash/unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M' --cases <c1,c2> --skip-compat-filter [--stall 300]

Only omp and pi currently honor `RUNTIME=splash`; other adapters need the same
`PROV_NAME/PROV_URL` branch (see `adapters/pi.sh`) and an entry in `_SPLASH_DIRECT_ADAPTERS` in `bin/smoke`.

## Adapter results (direct splash route, RUNTIME=splash)

Bench = `js-01-slugify-bug,js-02-debounce-feature`, `--stall 300`, one trial. Smoke = smoke-00/01/02.

| Adapter | Route | Smoke | Bench | Time (js-01 / js-02) | Notes |
|---|---|---|---|---|---|
| omp | direct | 3/3 | 8/8 (earlier run) | - / 144s | first smoke hit cold-discovery error, re-run passed |
| pi | direct | 3/3 | 8/8 (earlier run) | 77s / 74s | |
| goose | direct (OPENAI_BASE_URL) | 3/3 | 8/8 | 70s / 76s | first smoke attempt in a combined run reported failures; re-run 3/3 (flaky once) |
| qwen | direct (OPENAI_BASE_URL) | 3/3 | 8/8 | 99s / 186s | smoke slow (120s hello) - cold start |
