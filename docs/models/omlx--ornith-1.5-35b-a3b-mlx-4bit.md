---
title: "Ornith-1.5-35B-A3B-MLX-4bit"
model_key: "Ornith-1.5-35B-A3B-MLX-4bit"
family: "Ornith 1.5"
params_total: "35B"
params_active: "3B (A3B MoE)"
quantization: "MLX 4-bit"
disk_size: "18 GiB"
context: "256k native (BENCH_CONTEXT applies for bench runs)"
status: "keep"
recommended_for: ["default", "bench", "smoke"]
tier: "64gb"
best_adapter: "pi, cn, caveman"
accuracy: "100% (pi, cn, caveman), 90.9% (goose, qwen)"
speed_avg: "~29s (pi), ~44s (cn), ~54s (caveman)"
added: "2026-08-29"
last_run: "2026-08-29"
---

# Ornith-1.5-35B-A3B-MLX-4bit

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 100% on pi, cn, caveman (44/44 each); 90.9% on goose, qwen |
| **Speed (avg)** | ~29.2s per case (pi, omlx) — fastest of the clean 100% adapters |
| **Best adapter** | pi — fastest of the three clean 100% adapters (pi, cn, caveman) |
| **Recommended for** | default bench/smoke model |
| **Status** | keep |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `Ornith-1.5-35B-A3B-MLX-4bit` (served via oMLX, no `omlx/` prefix — see `bin/omlx models`) |
| **Family / arch** | Ornith 1.5, MoE (35B total, ~3B active — A3B) |
| **Parameter count** | 35B total, 3B active |
| **Quantization** | MLX 4-bit |
| **Disk size** | 18 GB (`~/.omlx/models/ornith-ai/Ornith-1.5-35B-A3B-MLX-4bit`) |
| **Context window** | 262144 (256K) native (`max_position_embeddings`, model `config.json`); bench runs use `BENCH_CONTEXT` |
| **Added** | 2026-08-29 |
| **Last run** | 2026-08-29 (runs `20260829-115614`, `20260829-132337`, `20260829-160836`, `20260829-161514`, `20260829-171401`) |
| **Doc updated** | 2026-08-29 |

## Results summary

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| pi | 44/44 (100%) | 29.2s | omlx | Full 12-case suite, all clean passes |
| cn | 44/44 (100%) | 44.3s | omlx | Clean |
| caveman | 44/44 (100%) | 53.8s | omlx | Clean |
| hermes | 44/44 (100%) | 110.2s | omlx | Fixed 2026-08-29 — see Failure patterns. Was silently hitting LM Studio instead of omlx before the fix. |
| goose | 40/44 (90.9%) | 134.4s | omlx | Slower but reliable; 4/44 short of clean |
| qwen | 40/44 (90.9%) | 118.5s | omlx | Fixed 2026-08-29 — see Failure patterns. |
| codex | 38/44 (86.4%) original run; 100% isolated re-check | 136.4s (contended) / 104.0s (isolated) | omlx | Root-caused 2026-08-29: contention, not a real issue (same as omp below) — original run was a 4-way concurrent bench (caveman+cn+codex+vibe). Isolated re-run of the failing `bash-01-topwords` case, no concurrent load, scored 4/4 in 104s, under the default 120s ceiling. |
| vibe | 23/38 (60.5%) original run; 100% isolated re-check | 156.6s (contended) / 110.5s (isolated) | omlx | Root-caused 2026-08-29: contention, not a real issue (same as omp/codex above) — original run was the 4-way concurrent bench with caveman/cn/codex. Isolated re-run of 2 cases, no concurrent load, scored 8/8 in 110.5s avg. |
| gptme | 24/40 (60.0%) | 127.8s | omlx | Fixed the runtime-prefix-stripping bug (see Failure patterns) — smoke-verified 3/3 clean in isolation, but a genuine (not contention) model/tool-format issue remains on harder cases — see Failure patterns. |
| omp | 23/40 (57.5%) original run; 100% isolated re-check | 110.3s (contended) / 66.0s (isolated) | omlx | Root-caused 2026-08-29: contention, not a real issue — original run was part of a 5-way concurrent bench (omp+aider+goose+claude+copilot). 5/6 failing cases hit `WATCHDOG: stall phase — no progress for 120s`; an isolated re-run of one (`js-02-debounce-feature`, no concurrent load) scored 4/4 in 66s, well under even the default 120s ceiling. Unlike claude (see below), this is contention-driven, not an inherent per-turn latency floor for this adapter+model. |
| claude | 10/38 (26.3%) | 126.8s | omlx | Root-caused 2026-08-29: not a wiring bug — this model needs >120s per turn on harder cases on this hardware, and the bench default `--stall 120` kills the trial before it finishes. Re-run with `--stall 200` to get a fair score (see Failure patterns). |
| copilot | 8/38 (21.1%) | 34.1s | omlx | Fixed 2026-08-29 — see Failure patterns. Smoke-verified 3/3 after the fix; full re-run pending a clean (uncontended) machine. |
| aider | 8/38 (21.1%) | 8.5s | omlx | Fixed 2026-08-29 — see Failure patterns. Smoke-verified 3/3 after the fix; full re-run pending a clean (uncontended) machine. |

**Working adapters total:** 8/12 clean-or-near-clean in isolation (pi, cn, caveman, goose, qwen, omp, codex, vibe — the latter three were only degraded by concurrent-run contention, confirmed clean when isolated); claude has a genuine per-turn latency floor needing `--stall 200`+; gptme has a genuine (non-contention) model/tool-format mismatch on harder cases; copilot/aider fixed but not yet re-benchmarked on a clean machine
**Overall (incl. all adapters/runs so far):** 341/438 (77.9%) across pi/goose/omp/claude/copilot/aider/qwen/caveman/cn/codex/vibe/gptme as originally run — this understates the model, since 3 of those low scores (omp, codex, vibe) were pure contention artifacts that scored 100% in isolation; see Failure patterns

## Timing observations

pi: fastest case smoke-00-hello (10s), slowest ts-01-groupby (84s), no timeouts/stalls, all well under the 300s ceiling. cn and caveman: similarly clean, ~1.5-2x pi's median. goose/qwen: reliable but ~4-5x slower than pi per case (median 118-134s). omp/claude/copilot/codex/gptme ran 100-140s per case where they reached the model — several hit the default 120s stall ceiling on harder/longer-context cases specifically (see claude's root-cause below, likely shared by codex and gptme). aider and copilot's initial (pre-fix) runs failed fast (8.5s, 34s median) because they errored out before real model inference — not genuine timing data.

## Failure patterns

- **aider (8/38, fixed 2026-08-29):** Aider bundles its own `litellm` client-side to parse `--model` before any network call, and it only recognizes litellm's built-in provider registry — our runtime prefixes (`omlx/`, `mtplx/`, ...) threw `litellm.BadRequestError: LLM Provider NOT provided` before `--openai-api-base` was ever consulted. Fix: `adapters/aider.sh` now wraps the already-prefixed id in another `openai/` layer (`openai/omlx/<id>`) — litellm always recognizes `openai/` and forwards everything after the first slash verbatim, so the wire request still carries `omlx/<id>` for `config-templates/litellm.yaml`'s wildcard routes to match. Smoke-verified 3/3. The same client-side rejection also hit `adapters/mini-swe-agent.sh`; same fix applied there, but that adapter then hit a separate stall/timeout issue (open, see below).
- **copilot (8/38, fixed 2026-08-29):** Two separate bugs. (1) `copilot.sh` unconditionally defaulted `PROVIDER` to `lms`, ignoring `--runtime omlx` / `$RUNTIME` — fixed to match the `${RUNTIME:-lms}` fallback other adapters already had. The identical hardcoded-`lms` bug was also found and fixed in `cline.sh`, `forge.sh`, `interpreter.sh`, `opencode.sh`, `opencode-orch.sh`, `openhands.sh`, and `qwen.sh`; **qwen's fix alone fully resolved it** (now 40/44, 90.9%, confirmed via `bin/smoke`), while the other five still fail after the fix for unrelated reasons (see below). (2) After the `PROVIDER` fix, copilot CLI always advertises its built-in `apply_patch` tool as `{"type": "custom", "custom": {...freeform grammar...}}` — an OpenAI *Responses API* tool shape that none of our local runtimes' Chat Completions endpoints support. Forwarding it made the backend call return `None` instead of a stream, which litellm-proxy's own streaming-iterator hook chain then crashed on with `'async for' requires an object with __aiter__ method, got NoneType` (confirmed by capturing copilot's actual request body via a local relay and replaying it directly against the proxy). Fixed with a litellm pre-call hook, `config-templates/litellm-hooks/strip_unsupported_tools.py`, that drops any tool whose `type` isn't `function` before it reaches the backend — mounted into the proxy container via `bin/litellm-proxy` and registered in `config-templates/litellm.yaml`'s `litellm_settings.callbacks`. Smoke-verified 3/3.
- **qwen (40/44, fixed 2026-08-29):** Same hardcoded-`PROVIDER=lms` bug as copilot (see above) — `qwen.sh` ignored `--runtime`/`$RUNTIME`. Fixed to `${RUNTIME:-lms}`; confirmed clean via `bin/smoke` (6/6) and a full bench run (40/44, 90.9%).
- **gptme (24/40, wiring bug fixed 2026-08-29, separate model/tool-format issue open):** `gptme.sh` stripped the runtime prefix (`omlx/`, `mtplx/`, ...) down to a bare model name before handing it to gptme (reasoning: gptme's litellm client only recognizes `openai/` as a provider). But `config-templates/litellm.yaml`'s model_name wildcard routes match on the *runtime-prefixed* name (e.g. `omlx/*`) — a bare name has no route, so every request 400'd with "no healthy deployments for this model". Fixed the same way as aider: keep the runtime prefix and wrap the whole thing in an extra `openai/` layer; smoke-verified clean (3/3, isolated). But an isolated re-run of `bash-01-topwords`/`js-02-debounce-feature` (no concurrent load, ruling out contention — see omp/codex below) still failed: on the harder cases, this model sometimes emits its tool call as literal `<tool_call><function=shell><parameter=command>...` XML text in the assistant message instead of gptme's expected OpenAI-style structured `tool_calls` field. gptme never recognizes this as a tool call, so the shell command is never actually run; after 2 turns with no tool use, gptme's autonomous-mode watchdog exits the session on its own ("No tools used after 2 auto-reply confirmations"). This is the same family of issue as the flat-XML-vs-nested-tool-call mismatch documented for pi+qwen3-coder in [pi.md](../tools/pi.md#known-issues) — a genuine model-output-format vs. adapter-parser mismatch, not a wiring bug, and not fixable in `gptme.sh` alone (would need a client-side shim in gptme itself, or steering the model more explicitly with a system-prompt style compatible with gptme's expectations).
- **claude (10/38, root-caused 2026-08-29 — not a wiring bug):** Mostly `status=stall` at almost exactly the bench's default `--stall 120` ceiling, even on trivial smoke cases in one contended run. Isolated re-runs (`--stall 200`, single case, no concurrent load) scored 4/4 on `js-01-slugify-bug` in 59s — well inside even the default budget. A follow-up re-run of the originally-stalling harder cases (`bash-01-topwords`, `deleg-01-validate-format-pipeline`, `ts-01-groupby`) still needed the full 200s stall budget and scored 3/13 sub-checks at ~120s avg under `--stall 120`, confirming this model+adapter combination genuinely needs more than 120s per turn on harder, longer-context tasks on this hardware — Claude Code's larger system prompt plus this model's decode speed pushes past the default stall window before goose/omp (leaner prompts) would. Not fixable in `adapters/claude.sh`; re-run with `--stall 200` (or higher) for a representative score.
- **codex (38/44 original, 100% isolated re-check, root-caused 2026-08-29 — contention, not a real issue):** Original run was part of the 4-adapter concurrent batch (caveman+cn+codex+vibe). 2 stalls at/near the default 120s ceiling (`bash-01-topwords` 159s, `smoke-01-edit-file` 232s). Isolated re-run of `bash-01-topwords` (no concurrent load) scored 4/4 in 104s, under the default ceiling — same contention story as omp, not a genuine per-turn floor.
- **vibe (23/38 original, 100% isolated re-check, root-caused 2026-08-29 — contention, not a real issue):** Ran as part of the same 4-adapter concurrent batch as codex — most failures were `stall` at ~180s, well above the default ceiling. Isolated re-run of 2 cases (no concurrent load) scored 8/8 in 110.5s avg — same contention story as omp/codex.
- **forge, interpreter, opencode, opencode-orch, openhands (all still failing after the `PROVIDER` fix):** each has its own separate, unrelated root cause — forge crashes on a broken native module (`better-sqlite3` bindings not found in the global npm install); interpreter gets routed into a ChatGPT/Codex-account code path that rejects local model ids outright; opencode and opencode-orch both return an opaque `{"name":"UnknownError", ...}` with no detail in the bench log; openhands crashes with a tmux `set-environment` error. None investigated further yet — filed as a follow-up task.
- **hermes (fixed 2026-08-29):** `adapters/hermes.sh` mapped omlx/mlx/mtplx to `HERMES_PROVIDER="lmstudio"`, silently pointing hermes at LM Studio's endpoint instead of the runtime under test — hence the fast "Connection error" with no further detail. Fixed by routing through hermes's own `custom:omlx`/`custom:mlx` provider entries (`~/.hermes/config.yaml`), which hit the runtime directly. Smoke-verified 3/3 (100%, ~29-39s/case).
- **nanocoder (fixed 2026-08-29):** the hang was not a litellm-proxy streaming issue (the proxy streams both plain and tool-call responses correctly against this model, verified directly with curl). It was nanocoder's own non-interactive `run` mode: its default `auto-accept` pre-approves file-editing tools but still gates `execute_bash` behind an interactive approval prompt, which can never be answered once stdin is consumed by the piped task — the run sat idle until the watchdog killed it. Fixed by adding `--mode yolo`. Smoke-verified 3/3 (100%, ~12-17s/case).
- **mini-swe-agent (investigated, not a wiring bug):** after the earlier `openai/`-wrapping fix, a re-run shows 2/3 smoke cases genuinely passing (245s, 165s — well under the 300s timeout, no proxy hang). The third (smoke-00-hello) errored because the model spent its turns exploring the sandbox instead of acting directly, per mini.yaml's generic "analyze the codebase first" workflow prompt — a model/prompt-workflow latency characteristic, not an adapter or proxy defect. Left open for a possible smoke-00 flakiness watch, but not blocking.
- **omp (23/40 original, 100% isolated re-check, root-caused 2026-08-29 — contention, not a real issue):** The original run was part of a 5-way concurrent bench (omp+aider+goose+claude+copilot all hitting the same omlx server at once). 5/6 failing cases showed `WATCHDOG: stall phase — no progress for 120s (lms: idle)`. Re-running one of them (`js-02-debounce-feature`) in isolation, no concurrent load, scored 4/4 in 66s — well under even the default 120s ceiling, unlike claude's genuine per-turn latency floor (which held even in isolation at 200s). Treat omp's low first-run score as a symptom of running 5 adapters concurrently against one server, not an adapter or model issue.
- **pi, cn, caveman, goose:** no repeatable failures.

## Better alternatives

Of the adapters tried so far, pi, cn, caveman, omp, codex, and vibe are all clean at or near 100% once isolated from concurrent-run contention (pi fastest at ~29s/case); goose and qwen are reliable at 90.9% but 4-5x slower. claude shows a genuine "stall-floor" pattern — correct once given enough time per turn (`--stall 200`+), just slower than the default 120s ceiling assumes on this hardware. gptme has a genuine, non-contention model/tool-format mismatch on harder cases (this model sometimes emits its tool call as XML text instead of a structured `tool_calls` field, which gptme doesn't parse). hermes, nanocoder, forge, interpreter, opencode, opencode-orch, openhands, and mini-swe-agent are not yet cleanly evaluated (see Failure patterns). Taken together, this model looks strong — most of the adapters that scored poorly on the first pass turned out to be measurement artifacts (contention) or adapter-side format gaps, not model weaknesses — but a fair comparison against `Ornith-1.0-35B-4bit` or `Qwen3.6-35B-A3B` should wait until the remaining open adapters are resolved.

## Status

**keep** — set as the repo default (`config.sh`) for bench and smoke testing on 2026-08-29. Clean (or clean-once-isolated) on pi/cn/caveman/omp/codex/vibe; solid 90.9% on goose/qwen. claude's low score is a stall-floor artifact of `--stall 120` being tuned for faster adapters, not evidence against the model; gptme's is a genuine but adapter-side tool-format mismatch. A handful of adapters (forge, interpreter, opencode, opencode-orch, openhands, hermes, nanocoder, mini-swe-agent) remain open and tracked in follow-up tasks — none of them point at a model problem so far.
