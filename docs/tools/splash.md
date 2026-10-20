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

Adapters honoring `RUNTIME=splash`: omp, pi, goose, qwen, aider, mini-swe-agent, openhands,
opencode, codex, claude, cn, copilot, gptme, hermes, interpreter, nanocoder, vibe, plus cline/forge
wired but not runnable here (listed in `_SPLASH_DIRECT_ADAPTERS` in `bin/smoke`). Most use the
`adapter_endpoint` helper in `lib/common.sh` (sets `EP_URL`/`EP_ROOT`/`EP_KEY`: splash when
`RUNTIME=splash`, else Olla). Not wired: caveman (not a candidate), opencode-orch.

## Adapter results (direct splash route, RUNTIME=splash)

Bench = `js-01-slugify-bug,js-02-debounce-feature`, `--stall 300`, one trial. Smoke = smoke-00/01/02.

| Adapter | Route | Smoke | Bench | Time (js-01 / js-02) | Notes |
|---|---|---|---|---|---|
| omp | direct | 3/3 | 8/8 (earlier run) | - / 144s | first smoke hit cold-discovery error, re-run passed |
| pi | direct | 3/3 | 8/8 (earlier run) | 77s / 74s | |
| goose | direct (OPENAI_BASE_URL) | 3/3 | 8/8 | 70s / 76s | first smoke attempt in a combined run reported failures; re-run 3/3 (flaky once) |
| qwen | direct (OPENAI_BASE_URL) | 3/3 | 8/8 | 99s / 186s | smoke slow (120s hello) - cold start |
| aider | direct (--openai-api-base) | 3/3 | 8/8 | 64s / 29s | |
| openhands | direct (LLM_BASE_URL) | 3/3 | 8/8 | 157s / 254s | |
| mini-swe-agent | direct (OPENAI_API_BASE) | 3/3 | 8/8 (re-run `--warmup 0 --timeout 600`) | 228s / 331s | first bench 5/8: bench fast-path error regex (`Cannot find module`) matched the *model's own test-script output* in the log and aborted the trial early (WATCHDOG: fatal error in log) - bench false positive, not a splash issue |
| opencode | direct (provider `splash` in ~/.config/opencode/opencode.jsonc, backup `.bak-splash`) | 3/3 | 8/8 | 64s / 205s | |
| codex | direct, Responses API via codex-models-wrapper | 3/3 (`--parallel 1 --warmup 0 --timeout 600`) | 8/8 (`--warmup 0 --timeout 600`) | 132s / 55s | needs `-c web_search=disabled -c apply_patch_tool_type=function`: splash `/v1/responses` rejects non-function tool types (`web_search`, `custom`) with HTTP 400 (bisected with captured codex payload; MCP `namespace` tools are accepted). Default-parallel smoke stalls: single-slot splash queues the 3 parallel cases behind codex's big prompt. Default watchdog false-positives on model's own "command not found" output (see Problems). |
| claude | direct, Anthropic `/v1/messages` (ANTHROPIC_BASE_URL=$SPLASH root) | 3/3 | 8/8 | 27s / 51s | fastest harness; adapter swallows claude's exit code (always 0) |

## Follow-up findings (2026-10-20, second pass)

### Splash via oMLX (:8000, v0.7.1rc1): NOT viable as a proxy route

- `GET :8000/v1/models` lists only oMLX's own models (Ornith, Qwen3.8-Flash-Next, Nemotron,
  gemma-4, Qwen3.5-2B, `incoai--Qwen3.8-27B-DFlash2`); **no splash-prefixed id**.
- `POST :8000/v1/chat/completions` with `unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M`,
  `splash/unsloth/...` and `splash` all return 404 `Model ... not found. Available models: ...`.
- The oMLX "Splash" integration (`~/.omlx/settings.json` -> `integrations.splash_path`,
  `splash_kv_format`, `splash_ssd_cache_gb`, `splash_ane_prefill`) is oMLX *launching its own
  Splash engine* (a launcher path; currently `null`) for models it manages. It is not a
  pass-through to the externally started splash at :8002 (admin UI text: "Splash results ...
  measure the Splash engine, not oMLX"). Making it work would require setting `splash_path`
  and adding a GGUF model under `~/.omlx/models`, which spawns a second Splash/model load -
  out of scope (no service/model changes allowed). So no proxy-overhead tok/s comparison was
  taken; the direct numbers above stand. `RUNTIME=omlx` therefore cannot reach this model.

### bash-01-topwords "stall" was the 300s hard timeout, not a hang

- The default `--timeout` is 300s; the earlier "stall" and the `--stall 300` retry both ended
  at ~302s = the hard ceiling (bench even warns `--stall (300) >= --timeout (300)`).
- The `(lms: idle)` text in the WATCHDOG line is just the default label: the lms token probe
  only runs for `RUNTIME=lms`. The watchdog itself is runtime-agnostic (progress = newest mtime
  in sandbox + pi session dir). pi-p prints only at the end, so mtime progress is sparse.
- Running the pi adapter directly: finished in 8m13s, wrote `bin/topwords.sh` at ~5 min, then
  kept self-verifying (30 randomized trials vs Python reference). Grader: 4/4.
- bench retry `bin/bench -a pi ... --cases bash-01-topwords --stall 300 --warmup 400 --timeout 900`
  -> **4/4, 580s**. Slow because the model over-verifies, not because splash hangs.

### Problems / deferred

- bench's early-abort regex (`command not found|Cannot find module|ENOENT|...` in
  `.bench.log`) false-positives on *the model's own command output* for harnesses that stream
  tool output into the log (mini-swe-agent, codex): trial aborted as `error` with
  `WATCHDOG: fatal error in log`. Workaround used: `--warmup 0` (disables all watchdog)
  with `--timeout 600`. A proper fix (scope the regex to adapter stderr or drop the generic
  patterns) is a bin/bench change, deferred.
- splash is single-slot: smoke's default `--parallel 4` queues cases behind each other;
  slow-prefill harnesses (codex ~15K-token prompt) then hit the 180s warmup. Use
  `--parallel 1` for smoke on splash with big-prompt harnesses.
- Splash `/v1/responses` rejects non-function tools (`web_search`, `custom`) with HTTP 400.
- goose: one smoke run in a combined invocation reported failures; an identical re-run
  passed 3/3 (cause not captured).
- Not wired (not requested/prioritised): cline, cn, copilot, forge, gptme, hermes,
  interpreter, nanocoder, vibe, caveman, opencode-orch.
- compat.json had a pre-existing uncommitted modification; left untouched, not committed.
- User config touched: `~/.config/opencode/opencode.jsonc` (adds a `splash` provider;
  backups `opencode.json.bak-splash`, `opencode.jsonc.bak-splash`), `~/.pi/agent/models.json`
  (earlier). Codex/goose/qwen/aider/openhands/claude need no user-config edits.

## Third pass: remaining adapters + harder cases

`bin/smoke` now forwards `--warmup/--timeout/--stall` to bench and maps `--parallel N` to
`BENCH_PARALLEL` (+`BENCH_PARALLEL_EXPLICIT=1`; bench itself has no `--parallel` flag).
Bench runs used `BENCH_PARALLEL=1 BENCH_PARALLEL_EXPLICIT=1 ... --skip-compat-filter --warmup 0 --timeout 600`.

| Adapter | Route/wiring | Smoke | Bench js-01/js-02 | Time js-01 / js-02 | Notes |
|---|---|---|---|---|---|
| cn | `adapter_endpoint` (config.yaml apiBase) | 3/3 | 8/8 | 29s / 40s | |
| copilot | `adapter_endpoint` (BYOK env) | 3/3 | 8/8 | 67s / 125s | gpt-4o catalog id makes copilot send a `custom` (apply_patch) tool -> splash HTTP 400 "only function tools are supported"; adapter uses catalog id `gpt-4.1` when `RUNTIME=splash` |
| gptme | `adapter_endpoint` | 3/3 | 8/8 | 143s / 98s | |
| hermes | `adapter_endpoint`, provider `custom:splash` self-healed into ~/.hermes/config.yaml (backup `.bak-splash`) | 3/3 | 8/8 | 127s / 312s | |
| interpreter | `adapter_endpoint` (`-c model_providers...`) | 3/3 | 8/8 | 66s / 58s | |
| nanocoder | `adapter_endpoint` (NANOCODER_PROVIDERS) | 3/3 | 8/8 | 53s / 83s | |
| vibe | `adapter_endpoint` (isolated VIBE_HOME) | 3/3 | 8/8 | 75s / 131s | |
| forge | wired | FAIL 0/3 | - | - | environment: `better_sqlite3.node` native binding missing for node 24 (forge's bundled dep); not a splash issue. Deferred (would need `npm rebuild` of a global package) |
| cline | wired | not run | - | - | `cline` binary not installed (smoke: "cline not installed - skipping") |

### Harder cases (`--timeout 900`, one trial)

Cases: js-03-multifile-cache, js-04-multifile-rename, js-05-multiselect-filter, js-06-lint-and-test, ts-01-groupby, bash-01-topwords.

| Adapter | js-03 | js-04 | js-05 | js-06 | ts-01 | bash-01 | Total |
|---|---|---|---|---|---|---|---|
| claude | 5/5 53s | 3/3 28s | 5/5 111s | 4/4 83s | 3/3 31s | 4/4 53s | 24/24 |
| aider | 5/5 89s | 3/3 24s | 5/5 125s | 4/4 32s | **1/3** 32s | 4/4 318s | 22/24 |
| goose | 5/5 113s | 3/3 67s | 5/5 97s | 4/4 63s | 3/3 141s | 4/4 121s | 24/24 |
| pi | 5/5 51s | 3/3 34s | 5/5 72s | 4/4 28s | 3/3 44s | 4/4 381s | 24/24 |
| omp | 5/5 95s | 3/3 56s | 5/5 278s | 4/4 46s | 3/3 375s | 4/4 902s | 24/24 |
| codex | 5/5 454s | 3/3 65s | 5/5 111s | 4/4 184s | 3/3 83s | 4/4 267s | 24/24 |
| opencode | 5/5 113s | 3/3 55s | 5/5 123s | 4/4 51s | 3/3 51s | 4/4 91s | 24/24 |

Notes: aider ts-01-groupby partial (aider edit-format/whole-file limitation, see grader MISS lines in
run 20261020-030505). omp bash-01 took 902s (at the 900s ceiling yet graded 4/4). bash-01 is slow on
pi/omp because the model over-verifies. Run IDs: claude 20261020-025905, aider -030505, goose -031530,
pi -032535, omp -033550, codex -040507, opencode -042433.

## Problems / deferred (third pass)

- forge: native `better_sqlite3.node` binding missing for node 24 - cannot run at all (env issue).
- cline: binary not installed; adapter wired but untested.
- opencode-orch, caveman: not wired (optional / not a candidate).
- `bin/smoke --parallel` was not a real flag before; now maps to BENCH_PARALLEL env.
- compat.json: uncommitted diff is unrelated to splash (forge/cline entries on omlx, older
  run ids from 2026-09-16); left uncommitted.
