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
| goose | 40/44 (90.9%) | 134.4s | omlx | Slower but reliable; 4/44 short of clean |
| qwen | 40/44 (90.9%) | 118.5s | omlx | Fixed 2026-08-29 — see Failure patterns. |
| codex | 38/44 (86.4%) | 136.4s | omlx | 2 stalls (bash-01-topwords, smoke-01-edit-file) at/near the default `--stall 120` ceiling — likely the same stall-floor pattern root-caused for claude below; not yet confirmed with `--stall 200`. |
| vibe | 23/38 (60.5%) | 156.6s | omlx | Ran concurrently with caveman/cn/codex (4-way parallel bench) — several stalls/WARNs may reflect server contention rather than a genuine vibe issue; re-run in isolation before concluding. |
| gptme | 24/40 (60.0%) | 127.8s | omlx | Fixed the runtime-prefix-stripping bug (see Failure patterns) — smoke-verified 3/3 clean in isolation, but the full 12-case bench (run concurrently with other load) shows stalls/timeouts on the harder cases, consistent with the same stall-floor pattern as claude/codex rather than a regression of the fix. |
| omp | 23/40 (57.5%) | 110.3s | omlx | Partial — several cases WARN/FAIL |
| claude | 10/38 (26.3%) | 126.8s | omlx | Root-caused 2026-08-29: not a wiring bug — this model needs >120s per turn on harder cases on this hardware, and the bench default `--stall 120` kills the trial before it finishes. Re-run with `--stall 200` to get a fair score (see Failure patterns). |
| copilot | 8/38 (21.1%) | 34.1s | omlx | Fixed 2026-08-29 — see Failure patterns. Smoke-verified 3/3 after the fix; full re-run pending a clean (uncontended) machine. |
| aider | 8/38 (21.1%) | 8.5s | omlx | Fixed 2026-08-29 — see Failure patterns. Smoke-verified 3/3 after the fix; full re-run pending a clean (uncontended) machine. |

**Working adapters total:** 5/12 clean-or-near-clean (pi, cn, caveman, goose, qwen); the stall-floor pattern (claude, likely codex/gptme too) needs a `--stall 200`+ re-run for a fair score; omp/vibe not yet root-caused; copilot/aider fixed but not yet re-benchmarked on a clean machine
**Overall (incl. all adapters/runs so far):** 341/438 (77.9%) across pi/goose/omp/claude/copilot/aider/qwen/caveman/cn/codex/vibe/gptme — not representative of model quality on its own; see Failure patterns

## Timing observations

pi: fastest case smoke-00-hello (10s), slowest ts-01-groupby (84s), no timeouts/stalls, all well under the 300s ceiling. cn and caveman: similarly clean, ~1.5-2x pi's median. goose/qwen: reliable but ~4-5x slower than pi per case (median 118-134s). omp/claude/copilot/codex/gptme ran 100-140s per case where they reached the model — several hit the default 120s stall ceiling on harder/longer-context cases specifically (see claude's root-cause below, likely shared by codex and gptme). aider and copilot's initial (pre-fix) runs failed fast (8.5s, 34s median) because they errored out before real model inference — not genuine timing data.

## Failure patterns

- **aider (8/38, fixed 2026-08-29):** Aider bundles its own `litellm` client-side to parse `--model` before any network call, and it only recognizes litellm's built-in provider registry — our runtime prefixes (`omlx/`, `mtplx/`, ...) threw `litellm.BadRequestError: LLM Provider NOT provided` before `--openai-api-base` was ever consulted. Fix: `adapters/aider.sh` now wraps the already-prefixed id in another `openai/` layer (`openai/omlx/<id>`) — litellm always recognizes `openai/` and forwards everything after the first slash verbatim, so the wire request still carries `omlx/<id>` for `config-templates/litellm.yaml`'s wildcard routes to match. Smoke-verified 3/3. The same client-side rejection also hit `adapters/mini-swe-agent.sh`; same fix applied there, but that adapter then hit a separate stall/timeout issue (open, see below).
- **copilot (8/38, fixed 2026-08-29):** Two separate bugs. (1) `copilot.sh` unconditionally defaulted `PROVIDER` to `lms`, ignoring `--runtime omlx` / `$RUNTIME` — fixed to match the `${RUNTIME:-lms}` fallback other adapters already had. The identical hardcoded-`lms` bug was also found and fixed in `cline.sh`, `forge.sh`, `interpreter.sh`, `opencode.sh`, `opencode-orch.sh`, `openhands.sh`, and `qwen.sh`; **qwen's fix alone fully resolved it** (now 40/44, 90.9%, confirmed via `bin/smoke`), while the other five still fail after the fix for unrelated reasons (see below). (2) After the `PROVIDER` fix, copilot CLI always advertises its built-in `apply_patch` tool as `{"type": "custom", "custom": {...freeform grammar...}}` — an OpenAI *Responses API* tool shape that none of our local runtimes' Chat Completions endpoints support. Forwarding it made the backend call return `None` instead of a stream, which litellm-proxy's own streaming-iterator hook chain then crashed on with `'async for' requires an object with __aiter__ method, got NoneType` (confirmed by capturing copilot's actual request body via a local relay and replaying it directly against the proxy). Fixed with a litellm pre-call hook, `config-templates/litellm-hooks/strip_unsupported_tools.py`, that drops any tool whose `type` isn't `function` before it reaches the backend — mounted into the proxy container via `bin/litellm-proxy` and registered in `config-templates/litellm.yaml`'s `litellm_settings.callbacks`. Smoke-verified 3/3.
- **qwen (40/44, fixed 2026-08-29):** Same hardcoded-`PROVIDER=lms` bug as copilot (see above) — `qwen.sh` ignored `--runtime`/`$RUNTIME`. Fixed to `${RUNTIME:-lms}`; confirmed clean via `bin/smoke` (6/6) and a full bench run (40/44, 90.9%).
- **gptme (24/40, partially fixed 2026-08-29):** `gptme.sh` stripped the runtime prefix (`omlx/`, `mtplx/`, ...) down to a bare model name before handing it to gptme (reasoning: gptme's litellm client only recognizes `openai/` as a provider). But `config-templates/litellm.yaml`'s model_name wildcard routes match on the *runtime-prefixed* name (e.g. `omlx/*`) — a bare name has no route, so every request 400'd with "no healthy deployments for this model". Fixed the same way as aider: keep the runtime prefix and wrap the whole thing in an extra `openai/` layer. Smoke-verified clean (3/3, isolated), but the full 12-case bench (run under concurrent load from other adapters) shows stalls/timeouts on `bash-01-topwords` and `js-02-debounce-feature` — likely the same stall-floor pattern documented for claude below rather than a flaw in the fix; needs an isolated `--stall 200` re-run to confirm.
- **claude (10/38, root-caused 2026-08-29 — not a wiring bug):** Mostly `status=stall` at almost exactly the bench's default `--stall 120` ceiling, even on trivial smoke cases in one contended run. Isolated re-runs (`--stall 200`, single case, no concurrent load) scored 4/4 on `js-01-slugify-bug` in 59s — well inside even the default budget. A follow-up re-run of the originally-stalling harder cases (`bash-01-topwords`, `deleg-01-validate-format-pipeline`, `ts-01-groupby`) still needed the full 200s stall budget and scored 3/13 sub-checks at ~120s avg under `--stall 120`, confirming this model+adapter combination genuinely needs more than 120s per turn on harder, longer-context tasks on this hardware — Claude Code's larger system prompt plus this model's decode speed pushes past the default stall window before goose/omp (leaner prompts) would. Not fixable in `adapters/claude.sh`; re-run with `--stall 200` (or higher) for a representative score.
- **codex (38/44):** 2 stalls, both at/near the default 120s ceiling (`bash-01-topwords` 159s, `smoke-01-edit-file` 232s) with the rest of the suite passing cleanly and quickly — consistent with the same stall-floor pattern as claude rather than a codex-specific bug. Not yet confirmed with `--stall 200`.
- **vibe (23/38):** Ran as part of a 4-adapter concurrent batch (with caveman/cn/codex all hitting the same omlx server simultaneously) — most failures are `stall` at ~180s, well above the default ceiling, suggesting server contention inflated latency rather than a genuine vibe defect (an earlier isolated 3-case smoke test passed 3/3 clean). Re-run in isolation before drawing conclusions.
- **forge, interpreter, opencode, opencode-orch, openhands (all still failing after the `PROVIDER` fix):** each has its own separate, unrelated root cause — forge crashes on a broken native module (`better-sqlite3` bindings not found in the global npm install); interpreter gets routed into a ChatGPT/Codex-account code path that rejects local model ids outright; opencode and opencode-orch both return an opaque `{"name":"UnknownError", ...}` with no detail in the bench log; openhands crashes with a tmux `set-environment` error. None investigated further yet — filed as a follow-up task.
- **hermes, nanocoder, mini-swe-agent (open, not wiring bugs already covered above):** hermes fails fast with just "Connection error" (no further detail); nanocoder reaches the model (correct `omlx/<id>` tag confirmed in its log) but then hangs with zero output until the stall watchdog aborts it; mini-swe-agent (after the same `openai/`-wrapping fix that resolved aider) still stalls/times out rather than erroring. Possibly related to the same litellm-proxy streaming issue found for copilot, possibly the stall-floor pattern — not yet root-caused. Filed as a follow-up task.
- **omp (23/40):** Partial passes/WARN on several cases; not yet investigated in depth.
- **pi, cn, caveman, goose:** no repeatable failures.

## Better alternatives

Of the adapters tried so far, pi, cn, and caveman are clean at 100% (pi fastest at ~29s/case); goose and qwen are reliable at 90.9% but 4-5x slower. Several others (claude, likely codex and gptme) show a "stall-floor" pattern — genuinely correct once given enough time per turn (`--stall 200`+), just slower than the default 120s ceiling assumes — so their real accuracy is probably much closer to the clean adapters than their default-settings score suggests. omp, vibe, hermes, nanocoder, forge, interpreter, opencode, opencode-orch, openhands, and mini-swe-agent are not yet cleanly evaluated (see Failure patterns) — no fair conclusion about this model vs. `Ornith-1.0-35B-4bit` or `Qwen3.6-35B-A3B` should be drawn until the stall-floor and remaining-adapter issues are resolved or the affected adapters are re-run with a higher `--stall` budget.

## Status

**keep** — set as the repo default (`config.sh`) for bench and smoke testing on 2026-08-29. Clean 100% on pi/cn/caveman, solid 90.9% on goose/qwen. Most of the remaining low scores (claude, likely codex/gptme) are a stall-floor artifact of the default `--stall 120` being tuned for faster adapters, not evidence against the model; a handful (forge, interpreter, opencode, opencode-orch, openhands, hermes, nanocoder, mini-swe-agent, omp, vibe) remain open and tracked in follow-up tasks.
